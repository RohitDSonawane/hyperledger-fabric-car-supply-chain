#!/bin/bash
# install_distributed_deps.sh
# CLEAN-SLATE BOOTSTRAP: Hyperledger Fabric Phase 2 Distributed Migration.
# VERSION-LOCKED: Purges old versions and enforces Go 1.24.0 and Node.js v20.

set -e # Exit on error
set -o pipefail

# --- Configuration (Production Targets) ---
TARGET_GO_VER="1.24.0"
TARGET_NODE_MAJOR="20"
ZEROTIER_INSTALL_URL="https://install.zerotier.com"

# --- Visual Setup ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}   DISTRIBUTED CAR SUPPLY CHAIN: CLEAN-SLATE INSTALLER   ${NC}"
echo -e "${CYAN}==========================================================${NC}"

# --- Task 0: System OS Sync ---
echo -e "\n[0/5] Synchronizing System Repositories..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential curl wget git jq net-tools openssh-server
echo -e "${GREEN}System base updated.${NC}"

# --- Task 1: Go (Clean Slate & Sync) ---
echo -e "\n[1/5] Syncing Go Language to version $TARGET_GO_VER..."
GO_INSTALLED_VER=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//' || echo "none")

if [ "$GO_INSTALLED_VER" != "$TARGET_GO_VER" ]; then
    echo -e "${YELLOW}Syncing Go: Correcting '$GO_INSTALLED_VER' to '$TARGET_GO_VER'...${NC}"
    
    # CRITICAL: Wipe older/incorrect Go to prevent corruption
    sudo rm -rf /usr/local/go
    
    # Direct Download & Extract
    wget -q https://go.dev/dl/go$TARGET_GO_VER.linux-amd64.tar.gz -O /tmp/go.tar.gz
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    
    # Path configuration logic (ensure it's in .bashrc only once)
    if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
        echo -e "\n# Hyperledger Fabric Go Paths" >> ~/.bashrc
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        echo 'export GOPATH=$HOME/go' >> ~/.bashrc
        echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
    fi
    export PATH=$PATH:/usr/local/go/bin
    echo -e "${GREEN}Go $TARGET_GO_VER is now active.${NC}"
else
    echo -e "${GREEN}Go is already correctly synced at $TARGET_GO_VER.${NC}"
fi

# --- Task 2: Node.js (Clean Slate & Sync) ---
echo -e "\n[2/5] Syncing Node.js to v$TARGET_NODE_MAJOR (LTS)..."
NODE_INSTALLED_MAJOR=$(node -v 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1 || echo "none")

if [ "$NODE_INSTALLED_MAJOR" != "$TARGET_NODE_MAJOR" ]; then
    echo -e "${YELLOW}Syncing Node.js: Patching 'v$NODE_INSTALLED_MAJOR' to 'v$TARGET_NODE_MAJOR'...${NC}"
    
    # Remove older/legacy nodejs if present (prevents conflicts)
    sudo apt remove -y nodejs npm 2>/dev/null || true
    sudo apt autoremove -y
    
    # Install NodeSource v20
    curl -fsSL https://deb.nodesource.com/setup_$TARGET_NODE_MAJOR.x | sudo -E bash -
    sudo apt install -y nodejs
    echo -e "${GREEN}Node.js version is now v$(node -v | cut -d'v' -f2).${NC}"
else
    echo -e "${GREEN}Node.js is already correctly synced at v$TARGET_NODE_MAJOR.${NC}"
fi

# --- Task 3: ZeroTier One Client ---
echo -e "\n[3/5] Syncing ZeroTier One Networking..."
if ! command -v zerotier-one > /dev/null; then
    echo -e "${YELLOW}Downloading and installing ZeroTier...${NC}"
    curl -s $ZEROTIER_INSTALL_URL | sudo bash
    echo -e "${GREEN}ZeroTier installed and active.${NC}"
else
    echo -e "${GREEN}ZeroTier is already installed.${NC}"
fi

# --- Task 4 & 5: Context and Permissions ---
echo -e "\n[4/5] Finalizing Fabrication User Permissions..."
if ! groups $USER | grep -q "\bdocker\b"; then
    sudo usermod -aG docker $USER
    echo -e "${RED}[ACTION] Please log out and back in to finalize Docker permissions!${NC}"
else
    echo -e "${GREEN}User permissions verified.${NC}"
fi

echo -e "\n${GREEN}==========================================================${NC}"
echo -e "${GREEN}   CLEAN-SLATE BOOTSTRAP COMPLETE: READY FOR PHASE 2     ${NC}"
echo -e "${GREEN}==========================================================${NC}"
