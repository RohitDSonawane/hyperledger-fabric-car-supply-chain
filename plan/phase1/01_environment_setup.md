# Step 1: Environment Setup (WSL2 Ubuntu 22.04)

This step ensures the host machine has all the binaries and tools needed to run Hyperledger Fabric v2.5.

---

## 1. Upgrade System Tools
Run these in your WSL terminal to ensure standard dependencies are met:
```bash
sudo apt-get update
sudo apt-get install -y build-essential git curl jq nodejs npm
```

## 2. Docker & Docker Compose
Ensure Docker is running and your user is part of the `docker` group.
```bash
# Check status
docker --version
docker-compose --version

# Add your user to docker group (requires relogin)
sudo usermod -aG docker $USER
```
*Note: WSL2 users must have Docker Desktop for Windows installed with the "WSL Integration" enabled.*

## 3. Install Go (v1.21.x)
Go is required to build the chaincode.
```bash
wget https://go.dev/dl/go1.21.8.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.8.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
```
*Tip: Add `export PATH=$PATH:/usr/local/go/bin` to your ~/.bashrc.*

## 4. Hyperledger Fabric Binaries & Images
Download the latest LTS version (v2.5.x) and its companion (CA v1.5.x).
```bash
# Downloads images and samples to current directory
curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.5.4 1.5.7
```

## 5. Path Configuration
Update your environment variables to recognize the Fabric `/bin` directory.
```bash
# In ~/.bashrc
export PATH=$PATH:/home/raj/HyperledgerFabric/fabric-samples/bin
```
Verify with: `peer version`.
