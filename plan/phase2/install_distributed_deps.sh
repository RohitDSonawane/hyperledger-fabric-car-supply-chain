#!/bin/bash
# install_distributed_deps.sh
# ONE-SHOT CLEAN-SLATE BOOTSTRAP + AUDIT for Hyperledger Fabric Phase 2.
# VERSION-LOCKED: Enforces Go 1.24.0 and Node.js v20.

set -e
set -o pipefail

if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    RUN_USER="${SUDO_USER}"
    RUN_HOME="$(getent passwd "${SUDO_USER}" | cut -d: -f6)"
else
    RUN_USER="${USER}"
    RUN_HOME="${HOME}"
fi

BASHRC_FILE="${RUN_HOME}/.bashrc"

# --- Configuration (Production Targets) ---
TARGET_GO_VER="1.24.0"
TARGET_NODE_MAJOR="20"
ZEROTIER_INSTALL_URL="https://install.zerotier.com"
FABRIC_VERSION="2.5.15"
FABRIC_CA_VERSION="1.5.15"
FABRIC_SAMPLES_DIR="${FABRIC_SAMPLES_DIR:-$HOME/fabric-samples}"

REQUIRED_PACKAGES=(
    build-essential curl wget git jq net-tools openssh-server
    ca-certificates gnupg lsb-release software-properties-common
    unzip tar netcat-openbsd
)

# --- Visual Setup ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}   DISTRIBUTED CAR SUPPLY CHAIN: CLEAN-SLATE INSTALLER   ${NC}"
echo -e "${CYAN}==========================================================${NC}"

warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

info() {
    echo -e "${GREEN}[OK] $1${NC}"
}

run_as_user() {
    local cmd="$1"
    if [ "$(id -un)" = "$RUN_USER" ]; then
        bash -lc "$cmd"
    else
        sudo -u "$RUN_USER" -H bash -lc "$cmd"
    fi
}

user_has_docker_access() {
    run_as_user "docker info >/dev/null 2>&1"
}

# --- Task 0: System OS Sync ---
echo -e "\n[0/7] Synchronizing System Repositories..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y "${REQUIRED_PACKAGES[@]}"
info "System base updated."

# Docker compose packaging differs by distro/repo state.
# Try plugin first, then fall back to legacy docker-compose package.
if ! docker compose version >/dev/null 2>&1; then
    echo -e "${YELLOW}docker compose plugin not detected, attempting package install...${NC}"
    if sudo apt install -y docker-compose-plugin; then
        info "Installed docker-compose-plugin."
    else
        warn "docker-compose-plugin package not available on this host. Falling back to docker-compose."
        sudo apt install -y docker-compose
    fi
fi

# --- Task 1: Go (Clean Slate & Sync) ---
echo -e "\n[1/7] Syncing Go Language to version $TARGET_GO_VER..."
GO_INSTALLED_VER=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//' || echo "none")

if [ "$GO_INSTALLED_VER" != "$TARGET_GO_VER" ]; then
    echo -e "${YELLOW}Syncing Go: Correcting '$GO_INSTALLED_VER' to '$TARGET_GO_VER'...${NC}"
    
    # CRITICAL: Wipe older/incorrect Go to prevent corruption
    sudo rm -rf /usr/local/go
    
    # Direct Download & Extract with fallback and explicit errors
    GO_TARBALL="go${TARGET_GO_VER}.linux-amd64.tar.gz"
    GO_URL_PRIMARY="https://go.dev/dl/${GO_TARBALL}"
    GO_URL_FALLBACK="https://dl.google.com/go/${GO_TARBALL}"
    GO_TMP="$(mktemp /tmp/go-XXXXXX.tar.gz)"

    echo -e "${CYAN}Downloading ${GO_TARBALL} from go.dev...${NC}"
    if ! curl -fL --retry 3 --connect-timeout 20 --max-time 1200 -o "$GO_TMP" "$GO_URL_PRIMARY"; then
        warn "Primary download failed. Trying fallback mirror..."
        curl -fL --retry 3 --connect-timeout 20 --max-time 1200 -o "$GO_TMP" "$GO_URL_FALLBACK"
    fi

    if [ ! -s "$GO_TMP" ]; then
        echo -e "${RED}[ERROR] Go download failed. Temp file is missing or empty.${NC}"
        exit 1
    fi

    sudo tar -C /usr/local -xzf "$GO_TMP"
    rm -f "$GO_TMP"
    
    # Path configuration logic (ensure it's in .bashrc only once)
    if ! grep -q "/usr/local/go/bin" "$BASHRC_FILE" 2>/dev/null; then
        run_as_user "printf '\n# Hyperledger Fabric Go Paths\nexport PATH=\\$PATH:/usr/local/go/bin\nexport GOPATH=\\$HOME/go\nexport PATH=\\$PATH:\\$GOPATH/bin\n' >> '$BASHRC_FILE'"
    fi
    export PATH=$PATH:/usr/local/go/bin
    info "Go $TARGET_GO_VER is now active."
else
    info "Go is already correctly synced at $TARGET_GO_VER."
fi

# --- Task 2: Node.js (Clean Slate & Sync) ---
echo -e "\n[2/7] Syncing Node.js to v$TARGET_NODE_MAJOR (LTS)..."
NODE_INSTALLED_MAJOR=$(node -v 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1 || echo "none")

if [ "$NODE_INSTALLED_MAJOR" != "$TARGET_NODE_MAJOR" ]; then
    echo -e "${YELLOW}Syncing Node.js: Patching 'v$NODE_INSTALLED_MAJOR' to 'v$TARGET_NODE_MAJOR'...${NC}"
    
    # Remove older/legacy nodejs if present (prevents conflicts)
    sudo apt remove -y nodejs npm 2>/dev/null || true
    sudo apt autoremove -y
    
    # Install NodeSource v20
    curl -fsSL https://deb.nodesource.com/setup_$TARGET_NODE_MAJOR.x | sudo -E bash -
    sudo apt install -y nodejs
    info "Node.js version is now v$(node -v | cut -d'v' -f2)."
else
    info "Node.js is already correctly synced at v$TARGET_NODE_MAJOR."
fi

# --- Task 3: ZeroTier One Client ---
echo -e "\n[3/7] Syncing ZeroTier One Networking..."
if ! command -v zerotier-one > /dev/null; then
    echo -e "${YELLOW}Downloading and installing ZeroTier...${NC}"
    curl -s $ZEROTIER_INSTALL_URL | sudo bash
    info "ZeroTier installed and active."
else
    info "ZeroTier is already installed."
fi

# --- Task 4: Fabric Samples + Binaries ---
echo -e "\n[4/7] Syncing Hyperledger Fabric samples and binaries..."

if [ ! -d "$FABRIC_SAMPLES_DIR" ]; then
    run_as_user "mkdir -p '$(dirname "$FABRIC_SAMPLES_DIR")'"
    run_as_user "git clone https://github.com/hyperledger/fabric-samples.git '$FABRIC_SAMPLES_DIR'"
else
    info "fabric-samples already present at $FABRIC_SAMPLES_DIR."
fi

if user_has_docker_access; then
    run_as_user "cd '$FABRIC_SAMPLES_DIR' && curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh | bash -s -- -f '$FABRIC_VERSION' -c '$FABRIC_CA_VERSION' binary docker samples"
    info "Fabric binaries, samples, and docker images synced."
else
    warn "Docker socket not accessible for user '$RUN_USER'. Installing binaries/samples only; skipping docker image pull for now."
    run_as_user "cd '$FABRIC_SAMPLES_DIR' && curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh | bash -s -- -f '$FABRIC_VERSION' -c '$FABRIC_CA_VERSION' binary samples"
fi

if ! grep -q "fabric-samples/bin" "$BASHRC_FILE" 2>/dev/null; then
    run_as_user "printf '\n# Hyperledger Fabric binaries\nexport PATH=\\$PATH:$FABRIC_SAMPLES_DIR/bin\n' >> '$BASHRC_FILE'"
fi
export PATH="$PATH:$FABRIC_SAMPLES_DIR/bin"

if ! command -v peer >/dev/null 2>&1 || ! command -v configtxgen >/dev/null 2>&1 || ! command -v configtxlator >/dev/null 2>&1; then
    echo -e "${RED}Fabric binaries are still missing in PATH after install-fabric step.${NC}"
    exit 1
fi

info "Fabric samples and binaries are synced."

# --- Task 5: Context and Permissions ---
echo -e "\n[5/7] Finalizing user and Docker permissions..."
if ! id -nG "$RUN_USER" | grep -qw docker; then
    sudo usermod -aG docker "$RUN_USER"
    warn "Added '$RUN_USER' to docker group. Log out/login (or restart WSL) then rerun installer to pull docker images."
else
    info "User permissions verified."
fi

# --- Task 6: WSL Networking sanity ---
echo -e "\n[6/7] Checking WSL networking baseline..."
if ! grep -q "generateHosts=false" /etc/wsl.conf 2>/dev/null; then
    warn "/etc/wsl.conf missing 'generateHosts=false'. Set it for stable distributed host mapping."
else
    info "WSL hosts generation setting verified."
fi

# --- Task 7: Final Verification Snapshot ---
echo -e "\n[7/7] Verification Snapshot..."
echo "Go:   $(go version 2>/dev/null || echo missing)"
echo "Node: $(node -v 2>/dev/null || echo missing)"
echo "Peer: $(peer version 2>/dev/null | sed -ne 's/^ Version: //p' || echo missing)"
echo "CfgG: $(command -v configtxgen >/dev/null 2>&1 && echo found || echo missing)"
echo "CfgL: $(command -v configtxlator >/dev/null 2>&1 && echo found || echo missing)"
if docker compose version >/dev/null 2>&1; then
    echo "Dcmp: found (docker compose plugin)"
elif command -v docker-compose >/dev/null 2>&1; then
    echo "Dcmp: found (docker-compose legacy)"
else
    echo "Dcmp: missing"
fi
echo "SamplesDir: $( [ -d "$FABRIC_SAMPLES_DIR" ] && echo "$FABRIC_SAMPLES_DIR" || echo missing )"

echo -e "\n${CYAN}Post-install quick checks:${NC}"
echo "  export PATH=\$PATH:$FABRIC_SAMPLES_DIR/bin"
echo "  peer version"
echo "  configtxgen -version"
echo "  configtxlator version"

echo -e "\n${GREEN}==========================================================${NC}"
echo -e "${GREEN}   ONE-SHOT INSTALL + AUDIT COMPLETE: READY FOR PHASE 2  ${NC}"
echo -e "${GREEN}==========================================================${NC}"
