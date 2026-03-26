# Phase 2.1.5: Automated Host Prerequisites
 
 ## Goal
 Completely automate the verification of all required dependencies, Docker settings, WSL networking nuances, and Windows Defender Firewall configurations before cross-node execution.
 
 ## Why Automated Checks?
 Running 5 independent PCs over WSL2 introduces complex points of failure that require unified validation. Instead of manually running `apt install` or digging into Windows Firewall settings GUI on 5 separate machines, execute the one-shot `install_distributed_deps.sh` script to install and audit prerequisites in a single run.
 
 ## Tasks
 
 ### A. Run the Automation Script
 On every one of your 5 PCs, execute:
 ```bash
chmod +x install_distributed_deps.sh
./install_distributed_deps.sh
 ```
 
### B. What The Scripts Validate And Install
 - **Network/OS Tools:** `openssh-server`, `curl`, `jq`, `net-tools`
 - **SSH Daemon:** Forces `ssh service` to start (combatting older WSL2 environments where `systemd` is disabled).
- **Users and Docker:** Verifies Docker CLI and `docker compose`, checks `docker` group membership.
- **Language Runtime Parity:** Go `1.24.0` and Node.js `20.x` parity across all five hosts.
- **Fabric Toolchain Bootstrap:** Clones `fabric-samples` (if missing) and runs `install-fabric.sh` to pull binaries and images.
- **Fabric CLI Validation:** Verifies `peer`, `configtxgen`, and `configtxlator` are in PATH.
 - **WSL2 DNS (`/etc/wsl.conf`):** Hardcodes `generateHosts=false` so WSL stops overwriting your canonical `/etc/hosts` name resolutions upon every reboot.
 - **Mirrored Networking (`.wslconfig`):** Patches the Windows host `.wslconfig` file via PowerShell to enable `networkingMode=mirrored`. This forces the WSL NAT boundary to drop, allowing Fabric gossip directly out the ZeroTier gateway adapter.
 - **Windows Defender:** Fires off a PowerShell Admin task to punch cross-host Fabric holes (7050-11052 TCP) through the host OS Windows Firewall so remote ZeroTier peers aren't blocked.
 
 ## Validation Checklist
 - Review script terminal output for any `RED` errors.
 - If the script modifies the Docker group, Windows `.wslconfig`, or `/etc/wsl.conf`, you **must** restart WSL from Windows:
   ```cmd
   wsl --shutdown
   ```
 
 ## Rollback
 If the script causes any unexpected changes to WSL behavior, simply remove `networkingMode=mirrored` from `%USERPROFILE%\.wslconfig` and restart WSL.
