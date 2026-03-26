#!/bin/bash
# install_full_stack.sh
# One-Click Stack Installer for Hyperledger Fabric Distributed Migration (Phase 2).
# Target: Fresh Ubuntu 22.04/WSL2 Installations.

set -e # Exit on error
set -o pipefail

# --- COLORS ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- VERSION GOALS ---
GO_VERSION="1.22.4"
NODE_MAJOR=18

echo -e "========== Phase 2: Full Stack Installer (Ubuntu 22.04) =========="

# Check for Sudo
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[ERROR] Please run with sudo or as root.${NC}"
  exit 1
fi

# Function: Step Header
function step() {
    echo -e "\n${YELLOW}[Step $1] $2...${NC}"
}

# 1. System Update
step 1 "Updating System Packages"
apt update && apt upgrade -y
apt install -y ca-certificates curl gnupg lsb-release jq net-tools coreutils

# 2. Install Docker (Native Ubuntu Engine)
step 2 "Installing Docker Engine & Compose"
if ! command -v docker &> /dev/null; then
    mkdir -m 0755 -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    # Post-install config
    groupadd docker 2>/dev/null || true
    usermod -aG docker $SUDO_USER || usermod -aG docker $USER
    echo -e "${GREEN}Docker installed correctly.${NC}"
else
    echo -e "${GREEN}Docker already exists. Skipping installation.${NC}"
fi

# 3. Install Go (v1.22.4)
step 3 "Installing Golang ($GO_VERSION)"
if ! command -v go &> /dev/null || [[ "$(go version)" != *"$GO_VERSION"* ]]; then
    ARCH=$(dpkg --print-architecture)
    [ "$ARCH" == "amd64" ] && GO_ARCH="amd64" || GO_ARCH="arm64"
    GO_TAR="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    
    echo "Downloading $GO_TAR..."
    curl -OL "https://go.dev/dl/$GO_TAR"
    rm -rf /usr/local/go && tar -C /usr/local -xzf "$GO_TAR"
    rm "$GO_TAR"
    
    # Configure PATH for ALL users
    if ! grep -q "/usr/local/go/bin" /etc/profile; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
        echo 'export GOPATH=$HOME/go' >> /etc/profile
        echo 'export PATH=$PATH:$GOPATH/bin' >> /etc/profile
    fi
    echo -e "${GREEN}Go $GO_VERSION installed to /usr/local/go.${NC}"
else
    echo -e "${GREEN}Go $GO_VERSION already exists. Skipping.${NC}"
fi

# 4. Install Node.js (v18 LTS)
step 4 "Installing Node.js (via NodeSource)"
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_$NODE_MAJOR.x | bash -
    apt install -y nodejs
    echo -e "${GREEN}Node.js $(node -v) installed.${NC}"
else
    echo -e "${GREEN}Node.js $(node -v) already exists. Skipping.${NC}"
fi

# 5. Install ZeroTier One
step 5 "Installing ZeroTier One Core Client"
if ! command -v zerotier-one &> /dev/null; then
    curl -s 'https://raw.githubusercontent.com/zerotier/ZeroTierOne/master/doc/contact@zerotier.com.gpg' | gpg --import
    curl -s https://install.zerotier.com | bash
    echo -e "${GREEN}ZeroTier One installed successfully.${NC}"
else
    echo -e "${GREEN}ZeroTier already exists. Skipping.${NC}"
fi

# 6. WSL-Specific Network Hardening
step 6 "Finalizing WSL2 & Networking Config"
# Disable auto-hosts
if ! grep -q "generateHosts=false" /etc/wsl.conf 2>/dev/null; then
    echo -e "[network]\ngenerateHosts=false" | tee /etc/wsl.conf > /dev/null
fi

# Inform User
echo -e "\n========================================================"
echo -e "${GREEN}STACK INSTALLATION COMPLETE!${NC}"
echo -e "========================================================"
echo -e "1. ${RED}IMPORTANT:${NC} You MUST log out and log back in (or restart WSL)."
echo -e "2. RUN 'zerotier-cli join <NETWORK_ID>' to connect to your mesh."
echo -e "3. Next Step: Run 'bash plan/phase2/check_prerequisites.sh' to verify."
echo -e "========================================================"
