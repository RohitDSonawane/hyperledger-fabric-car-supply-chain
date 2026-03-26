# Phase 3: Risk Mitigation & Troubleshooting Guide

This phase outlines common failure points during a live demo (especially in a 5-PC distributed setup) and provides a "safety net" if things go wrong.

---

## 1. Common Tech Failures & Fixes

### **A. WSL2 & Docker Synchronization**
- **Error**: "Peer cannot connect to Orderer" or "Certificate Invalid".
- **Cause**: WSL2's clock drifts from the host PC's clock, making certificates appear as "not yet valid" or "expired".
- **Fix**: 
  ```bash
  sudo hwclock -s
  ```
  Check the date on all 5 PCs before starting.

### **B. ZeroTier / LAN Connectivity**
- **Error**: Ping works, but Fabric containers can't communicate.
- **Cause**: Windows Defender or Third-party Firewalls blocking Docker's internal bridge communication on the ZeroTier interface.
- **Fix**: Temporary disable of Windows Firewall for the "Private" or "Domain" profile on all 5 PCs.

### **C. High MTU Issues (ZeroTier specific)**
- **Error**: Transaction logs show `context deadline exceeded`.
- **Cause**: Standard MTU (1500) might be too high for the virtual bridge.
- **Fix**: Lower the MTU of the ZeroTier interface on all Linux nodes:
  ```bash
  sudo ip link set dev ztXXXXXXXX mtu 1280
  ```

### **D. Docker Database (Explorer)**
- **Error**: Explorer shows `Error connecting to database`.
- **Cause**: Persistent volume from previous runs conflict.
- **Fix**: 
  ```bash
  docker-compose -f explorer/docker-compose.yaml down -v
  ```
---

## 2. Fallback Demo Strategy (The "Safety Net")

**Level 1: The "Self-Healing" Network (15 Minutes)**
- Maintain a **"Reset Script"** on PC1 that kills all containers across the 5 PCs using SSH and restarts the network from scratch.

**Level 2: Revert to Simulation (The Backup PC)**
- If the ZeroTier/P2P network is unstable during the tech visit, **DO NOT debug on-stage for more than 5 minutes**. 
- Immediately switch your HDMI output to a **Single-PC Simulation** (Phase 1 setup). This PC should have the 3-Org network already pre-launched and Explorer running.

---

## 3. Pre-Demo Checklist (The Night Before)
1.  [ ] **SSH Keys**: Ensure PC1 can SSH into all other 4 PCs without a password.
2.  [ ] **Static IPs**: Verify ZeroTier IPs haven't changed.
3.  [ ] **Docker Images**: Ensure `hyperledger/fabric-peer:2.5` and `hyperledger/explorer:latest` are PRE-PULLED on all PCs (avoid downloading on slow campus Wi-Fi).
4.  [ ] **Disk Space**: Ensure at least 10GB free on each PC for logs and Docker images.
5.  [ ] **Explorer connection-profile**: Double-check the path to the distributed certificates.
