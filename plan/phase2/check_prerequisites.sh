#!/bin/bash
# check_prerequisites.sh
# Autochecks and installs all WSL2/Fabric dependencies across all Phase 2 hosts.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ====== Phase 2 Automated Prerequisite Checker ======

# 1. Ubuntu Packages (SSH, net-tools, curl, jq)
echo -e "\n[1] Checking Ubuntu Runtime Dependencies..."
if ! dpkg-query -W -f='${Status}' openssh-server net-tools curl jq 2>/dev/null | grep -q "ok installed"; then
    echo -e "${YELLOW}Missing base packages. Installing...${NC}"
    sudo apt update && sudo apt install -y openssh-server net-tools curl jq
else
    echo -e "${GREEN}Base packages installed.${NC}"
fi

# SSH Service
if ! service ssh status > /dev/null 2>&1; then
    echo -e "${YELLOW}Starting SSH Service...${NC}"
    sudo service ssh start
else
    echo -e "${GREEN}SSH Service is running.${NC}"
fi

# 2. Docker & Permissions
echo -e "\n[2] Checking Docker Engine..."
if ! command -v docker > /dev/null; then
    echo -e "${RED}Docker is not installed! Please install Docker Desktop with WSL2 integration.${NC}"
else
    echo -e "${GREEN}Docker binary found.${NC}"
    if ! groups $USER | grep -q "\bdocker\b"; then
        echo -e "${YELLOW}Adding $USER to docker group...${NC}"
        sudo usermod -aG docker $USER
        echo -e "${RED}!! Action required: You must log out and log back in (or run 'newgrp docker') for permissions to apply.${NC}"
    else
        echo -e "${GREEN}User is already in docker group.${NC}"
    fi
fi

# 3. Fabric Binaries
echo -e "\n[3] Checking Hyperledger Fabric Binaries..."
if ! command -v peer > /dev/null || ! command -v configtxgen > /dev/null; then
    echo -e "${RED}Fabric binaries (peer, configtxgen) are missing from PATH.${NC}"
    echo -e "${YELLOW}Please download fabric-samples binaries and add them to your ~/.bashrc PATH.${NC}"
else
    echo -e "${GREEN}Fabric binaries found in PATH.${NC}"
fi

# 4. WSL Networking & DNS
echo -e "\n[4] Applying WSL2 Network Hardening..."

# /etc/wsl.conf
if ! grep -q "generateHosts=false" /etc/wsl.conf 2>/dev/null; then
    echo -e "${YELLOW}Disabling Auto-Host Generation in /etc/wsl.conf...${NC}"
    if [ ! -f /etc/wsl.conf ]; then
        echo -e "[network]\ngenerateHosts=false" | sudo tee /etc/wsl.conf > /dev/null
    else
        echo -e "\n[network]\ngenerateHosts=false" | sudo tee -a /etc/wsl.conf > /dev/null
    fi
else
    echo -e "${GREEN}/etc/wsl.conf already configured for static hosts.${NC}"
fi

# 5. Windows Networking (mirrored vs NAT) & Firewall
echo -e "\n[5] Checking Windows Networking Configuration via PowerShell..."
if command -v powershell.exe > /dev/null; then
    WINDOWS_USERProfile=$(powershell.exe -c 'echo $env:USERPROFILE' | tr -d '\r')
    WINDOWS_USERProfile_MNT=$(wslpath "$WINDOWS_USERProfile")
    
    if ! grep -q "networkingMode=mirrored" "$WINDOWS_USERProfile_MNT/.wslconfig" 2>/dev/null; then
        echo -e "${YELLOW}Setting WSL2 to 'mirrored' networking in Windows .wslconfig...${NC}"
        echo -e "\n[wsl2]\nnetworkingMode=mirrored" >> "$WINDOWS_USERProfile_MNT/.wslconfig"
        echo -e "${RED}!! Action required: You must restart WSL from Windows (wsl --shutdown) for this to apply.${NC}"
    else
        echo -e "${GREEN}Windows .wslconfig already set to mirrored networking.${NC}"
    fi

    # Windows Defender Firewall
    echo -e "\n[6] Applying Windows Defender ZeroTier Firewall Rules..."
    echo -e "${YELLOW}(A Windows User Account Control prompt may appear requesting Admin permissions)${NC}"
    powershell.exe -Command "Start-Process powershell -Verb runAs -WindowStyle Hidden -ArgumentList '-Command', 'if (-Not (Get-NetFirewallRule -DisplayName \"Allow Fabric ZeroTier\" -ErrorAction SilentlyContinue)) { New-NetFirewallRule -DisplayName \"Allow Fabric ZeroTier\" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 7050-11052 }'"
    echo -e "${GREEN}Windows firewall rule request sent.${NC}"
else
    echo -e "${RED}powershell.exe not found! Are you running inside WSL2?${NC}"
fi

echo -e "\n====== Prerequisite Check Finished ======"
echo -e "${YELLOW}If you saw red warnings, please resolve them before continuing to Phase 2.2.${NC}"
