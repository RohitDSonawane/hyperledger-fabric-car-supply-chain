#!/bin/bash
# install_distributed_deps.sh
# One-click Ubuntu 22.04 installer for Hyperledger Fabric Phase 2 migration.
# Optimized for WSL2 + Docker Desktop (Option A).

set -e # Exit on error
set -o pipefail

# --- Configuration ---
MIN_GO_VER="1.22.4"
MIN_NODE_VER="20"
ZEROTIER_INSTALL_URL="https://install.zerotier.com"

# --- Visual Setup ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}   DISTRIBUTED CAR SUPPLY CHAIN: BOOTSTRAP INSTALLER     ${NC}"
echo -e "${CYAN}==========================================================${NC}"

# --- Task 0: System OS Update ---
echo -e "\n[0/5] Updating System Repositories..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential curl wget git jq net-tools openssh-server
echo -e "${GREEN}System base updated.${NC}"

# --- Task 1: Go (v1.22.4+) ---
echo -e "\n[1/5] Installing Go Language..."
GO_INSTALLED_VER=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//' || echo "none")

if [[ "$GO_INSTALLED_VER" == "none" || $(echo -e "$GO_INSTALLED_VER\n$MIN_GO_VER" | sort -V | head -n1) != "$MIN_GO_VER" ]]; then
    echo -e "${YELLOW}Downloading Go $MIN_GO_VER...${NC}"
    wget -q https://go.dev/dl/go$MIN_GO_VER.linux-amd64.tar.gz -O /tmp/go.tar.gz
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    
    # Update PATH if not already handled by ~/.bashrc
    if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        echo 'export GOPATH=$HOME/go' >> ~/.bashrc
        echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
    fi
    export PATH=$PATH:/usr/local/go/bin
    echo -e "${GREEN}Go $MIN_GO_VER installed successfully.${NC}"
else
    echo -e "${GREEN}Go version $GO_INSTALLED_VER already meets requirements.${NC}"
fi

# --- Task 2: Node.js (v20 LTS) ---
echo -e "\n[2/5] Installing Node.js LTS..."
if ! command -v node > /dev/null || [[ $(node -v | cut -d'v' -f2 | cut -d'.' -f1) -lt $MIN_NODE_VER ]]; then
    echo -e "${YELLOW}Installing NodeSource repository for Node.js $MIN_NODE_VER...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_$MIN_NODE_VER.x | sudo -E bash -
    sudo apt install -y nodejs
    echo -e "${GREEN}Node.js $(node -v) installed.${NC}"
else
    echo -e "${GREEN}Node.js $(node -v) is already installed.${NC}"
fi

# --- Task 3: ZeroTier One Client ---
echo -e "\n[3/5] Installing ZeroTier One Networking..."
if ! command -v zerotier-one > /dev/null; then
    echo -e "${YELLOW}Downloading and installing ZeroTier...${NC}"
    curl -s $ZEROTIER_INSTALL_URL | sudo bash
    echo -e "${GREEN}ZeroTier installed.${NC}"
else
    echo -e "${GREEN}ZeroTier is already installed.${NC}"
fi

# --- Task 4: Fabric Binaries Verification ---
echo -e "\n[4/5] Checking Fabric Repository Context..."
# Check for correct directory depth (expecting multi-host/ or single-host/ context)
if [[ ! -d "bin" && ! -d "../bin" ]]; then
    echo -e "${YELLOW}[NOTICE] Fabric binaries (peer) not found in the local context.${NC}"
    echo -e "${YELLOW}This is expected on fresh installs. They will appear after you CLONE the repo branch.${NC}"
else
    echo -e "${GREEN}Fabric binaries verified in context.${NC}"
fi

# --- Task 5: Docker User Permissions (Docker Desktop Assumption) ---
echo -e "\n[5/5] Finalizing User Permissions..."
if ! groups $USER | grep -q "\bdocker\b"; then
    echo -e "${YELLOW}Adding $USER to 'docker' group for WSL integration...${NC}"
    sudo usermod -aG docker $USER
    echo -e "${CYAN}[ACTION REQUIRED] Please restart your terminal for group changes.${NC}"
else
    echo -e "${GREEN}User is already in the docker group.${NC}"
fi

# --- Summary ---
echo -e "\n${GREEN}==========================================================${NC}"
echo -e "${GREEN}   BOOTSTRAP COMPLETE - NODE IS READY FOR PHASE 2      ${NC}"
echo -e "${GREEN}==========================================================${NC}"
echo -e "Next steps for this PC:"
echo -e " 1. Open Docker Desktop on Windows -> Settings -> Resources -> WSL Integration."
echo -e " 2. Enable integration for THIS Ubuntu distro."
echo -e " 3. Run: 'source ~/.bashrc' on this shell."
echo -e " 4. Navigate to 'multi-host/' and join your ZeroTier network."
