#!/bin/bash
# check_prerequisites.sh
# Strict version parity auditor for Hyperledger Fabric 5nd-PC distributed clusters.
# ENFORCES: All nodes must have the EXACT Go 1.24.0 and Node.js v20.x versions.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# TARGET VERSIONS FOR PARITY
TARGET_GO_VER="1.24.0"
TARGET_NODE_MAJOR="20"
TARGET_PEER_VER="2.5.0"

echo -e "====== Phase 2 Strict Prerequisite Auditor ======"

# 0. System Sync
echo -e "\n[0] Verifying System OS State..."
sudo apt update && sudo apt upgrade -y
echo -e "${GREEN}System up-to-date.${NC}"

# 1. Base Packages
echo -e "\n[1] Checking Core Packages..."
if ! dpkg-query -W -f='${Status}' openssh-server net-tools curl jq 2>/dev/null | grep -q "ok installed"; then
    echo -e "${YELLOW}Base packages missing. Run 'install_distributed_deps.sh' first!${NC}"
else
    echo -e "${GREEN}Base packages verified.${NC}"
fi

# 2. Go Language (STRICT)
echo -e "\n[2] Auditing Go Language Version..."
GO_INSTALLED_VER=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//' || echo "none")

if [ "$GO_INSTALLED_VER" != "$TARGET_GO_VER" ]; then
    echo -e "${RED}[ERROR] Version Mismatch! PC has '$GO_INSTALLED_VER', but Cluster requires EXACT '$TARGET_GO_VER'.${NC}"
    echo -e "${YELLOW}Please run 'install_distributed_deps.sh' to sync this host.${NC}"
else
    echo -e "${GREEN}Go version is perfectly synced with the cluster ($GO_INSTALLED_VER).${NC}"
fi

# 3. Node.js (STRICT)
echo -e "\n[3] Auditing Node.js Version..."
NODE_INSTALLED_MAJOR=$(node -v 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1 || echo "none")

if [ "$NODE_INSTALLED_MAJOR" != "$TARGET_NODE_MAJOR" ]; then
    echo -e "${RED}[ERROR] Version Mismatch! Node.js is v$NODE_INSTALLED_MAJOR, but Cluster requires v$TARGET_NODE_MAJOR.${NC}"
else
    echo -e "${GREEN}Node.js version is perfectly synced (v$TARGET_NODE_MAJOR.x).${NC}"
fi

# 4. Fabric Binaries & Permissions
echo -e "\n[4] Auditing Fabric Tools & WSL Networking..."
if ! command -v peer > /dev/null; then
    echo -e "${RED}[ERROR] Peer binary not in PATH.${NC}"
else
    PEER_VER=$(peer version | sed -ne 's/^ Version: //p')
    echo -e "${GREEN}Fabric tools verified (Version: $PEER_VER).${NC}"
fi

if ! grep -q "generateHosts=false" /etc/wsl.conf 2>/dev/null; then
    echo -e "${RED}[ERROR] /etc/wsl.conf is NOT set for static hosts. This will break distributed networking!${NC}"
else
    echo -e "${GREEN}WSL DNS config verified.${NC}"
fi

echo -e "\n====== Sync Audit Finished ======"
echo -e "${YELLOW}Recommendation: If any [ERROR] appeared above, the host will NOT work in the 5-PC cluster.${NC}"
