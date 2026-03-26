#!/bin/bash
# check_prerequisites.sh
# Autochecks and installs all WSL2/Fabric dependencies across all Phase 2 hosts.
# Enhanced: Version parity checks and system-wide updates.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Goal Versions for Phase 2 Distributed Setup
MIN_DOCKER_VER="20.10"
MIN_GO_VER="1.20"
MIN_PEER_VER="2.5.0"

echo -e "====== Phase 2 Automated Prerequisite Checker ======"

# 0. System Update & Upgrade
echo -e "\n[0] Running System Update & Upgrade (Ubuntu 22.04+ Recommended)..."
echo -e "${YELLOW}Please wait, this may take a few minutes. Root password may be required.${NC}"
sudo apt update && sudo apt upgrade -y
echo -e "${GREEN}System update complete.${NC}"

# 1. Ubuntu Packages (SSH, net-tools, curl, jq)
echo -e "\n[1] Checking Ubuntu Runtime Dependencies..."
if ! dpkg-query -W -f='${Status}' openssh-server net-tools curl jq 2>/dev/null | grep -q "ok installed"; then
    echo -e "${YELLOW}Missing base packages. Installing...${NC}"
    sudo apt install -y openssh-server net-tools curl jq
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

# 2. Docker & Versions
echo -e "\n[2] Checking Docker Engine & Version Parity..."
if ! command -v docker > /dev/null; then
    echo -e "${RED}[ERROR] Docker is not installed! Please install Docker Desktop with WSL2 integration.${NC}"
else
    DOCKER_VER=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "0.0.0")
    if [[ $(echo -e "$DOCKER_VER\n$MIN_DOCKER_VER" | sort -V | head -n1) == "$MIN_DOCKER_VER" ]]; then
        echo -e "${GREEN}Docker binary found (Version: $DOCKER_VER). Compatible.${NC}"
    else
        echo -e "${RED}[WARNING] Docker version $DOCKER_VER is older than recommended $MIN_DOCKER_VER.${NC}"
    fi

    if ! groups $USER | grep -q "\bdocker\b"; then
        echo -e "${YELLOW}Adding $USER to docker group...${NC}"
        sudo usermod -aG docker $USER
        echo -e "${RED}!! Action required: Log out and log back in (or 'newgrp docker') for permissions to apply.${NC}"
    fi
fi

# 3. Go Language Version
echo -e "\n[3] Checking Go Language Version..."
if ! command -v go > /dev/null; then
    echo -e "${RED}[ERROR] Go is not installed. Please install Go $MIN_GO_VER or higher.${NC}"
else
    GO_VER=$(go version | awk '{print $3}' | sed 's/go//')
    if [[ $(echo -e "$GO_VER\n$MIN_GO_VER" | sort -V | head -n1) == "$MIN_GO_VER" ]]; then
        echo -e "${GREEN}Go found (Version: $GO_VER). Compatible.${NC}"
    else
        echo -e "${RED}[ERROR] Go version $GO_VER is too old! Need $MIN_GO_VER+. Please update Go.${NC}"
    fi
fi

# 4. Fabric Binaries & PATH
echo -e "\n[4] Checking Hyperledger Fabric Binaries..."
if ! command -v peer > /dev/null; then
    echo -e "${RED}[ERROR] Fabric 'peer' binary missing from PATH.${NC}"
else
    PEER_VER=$(peer version | sed -ne 's/^ Version: //p')
    if [[ $(echo -e "$PEER_VER\n$MIN_PEER_VER" | sort -V | head -n1) == "$MIN_PEER_VER" ]]; then
        echo -e "${GREEN}Fabric Peer found (Version: $PEER_VER). Compatible.${NC}"
    else
        echo -e "${RED}[ERROR] Fabric version $PEER_VER is incompatible. Need $MIN_PEER_VER+.${NC}"
    fi
fi

# 5. WSL Networking & DNS
echo -e "\n[5] Applying WSL2 Network Hardening..."
if ! grep -q "generateHosts=false" /etc/wsl.conf 2>/dev/null; then
    echo -e "${YELLOW}Configuring static hosts in /etc/wsl.conf...${NC}"
    echo -e "[network]\ngenerateHosts=false" | sudo tee /etc/wsl.conf > /dev/null
else
    echo -e "${GREEN}/etc/wsl.conf static hosts verified.${NC}"
fi

# 6. Windows Networking via PowerShell
echo -e "\n[6] Checking Windows/WSL Configuration..."
if command -v powershell.exe > /dev/null; then
    WINDOWS_USERProfile=$(powershell.exe -c 'echo $env:USERPROFILE' | tr -d '\r')
    WINDOWS_USERProfile_MNT=$(wslpath "$WINDOWS_USERProfile")
    
    if ! grep -q "networkingMode=mirrored" "$WINDOWS_USERProfile_MNT/.wslconfig" 2>/dev/null; then
        echo -e "${YELLOW}Setting mirrored networking in Windows .wslconfig...${NC}"
        echo -e "\n[wsl2]\nnetworkingMode=mirrored" >> "$WINDOWS_USERProfile_MNT/.wslconfig"
        echo -e "${RED}!! Action required: Restart WSL (wsl --shutdown) for this to apply.${NC}"
    else
        echo -e "${GREEN}Windows .wslconfig mirrored mode verified.${NC}"
    fi

    # Windows Defender Firewall
    echo -e "${YELLOW}Applying Windows Defender ZeroTier Firewall Rules...${NC}"
    powershell.exe -Command "Start-Process powershell -Verb runAs -WindowStyle Hidden -ArgumentList '-Command', 'if (-Not (Get-NetFirewallRule -DisplayName \"Allow Fabric ZeroTier\" -ErrorAction SilentlyContinue)) { New-NetFirewallRule -DisplayName \"Allow Fabric ZeroTier\" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 7050-11052 }'"
    echo -e "${GREEN}Windows firewall update requested.${NC}"
else
    echo -e "${RED}Are you running inside WSL2? powershell.exe not found.${NC}"
fi

echo -e "\n====== Prerequisite Check Finished ======"
echo -e "${YELLOW}Recommendation: Run this on ALL 5 PCs. Ensure all report the same compatible versions.${NC}"
