# Phase 2: Distributed 5-PC Setup (ZeroTier Strategy)

This phase moves the **Car Supply Chain** from a simulation on one PC to a real distributed network using five physical/virtual machines connected via a **ZeroTier** flat Layer 2 subnet.

---

## 1. Network Topology (5-Node Distribution)

| Node | Name | Roles | Responsibilities |
| :--- | :--- | :--- | :--- |
| **PC 1** | **Manager / Client** | `orderer.example.com`, `cli` | Manages consensus and invokes transactions. |
| **PC 2** | **Manufacturer** | `peer0.manufacturer.example.com`, `ca-manufacturer` | Represents the Manufacturer Org. |
| **PC 3** | **Showroom** | `peer0.showroom.example.com`, `ca-showroom` | Represents the Showroom Org. |
| **PC 4** | **Customer** | `peer0.customer.example.com`, `ca-customer` | Represents the Customer Org. |
| **PC 5** | **Explorer** | `explorer.example.com`, `postgres-db` | Provides the visualization frontend. |

---

## 2. Global Connectivity Strategy (ZeroTier + /etc/hosts)

Since we are on a ZeroTier virtual network:
1.  **Static IP Mapping**: Every PC must have a static ZeroTier IP assigned (e.g., `10.147.17.x`).
2.  **Static Resolution**: Map hostnames in `/etc/hosts` on **EVERY** machine:
    ```bash
    # Sample /etc/hosts
    10.147.17.1 orderer.example.com
    10.147.17.2 peer0.manufacturer.example.com
    10.147.17.3 peer0.showroom.example.com
    10.147.17.4 peer0.customer.example.com
    ```
3.  **Docker Overlay?**: We will stick to **standard Docker Compose** on each node but use `extra_hosts` in the YAML files to ensure containers can resolve other nodes' IPs across the ZeroTier bridge.

---

## 3. Distributed Lifecycle Protocol

### **A. Decentralized Crypto Generation**
1.  **Initial Generation**: Generate all certificates (MSP, TLS) on **PC 1** using `cryptogen`.
2.  **Secure Synchronization**: Copy the required `crypto-config` folders to PCs 2, 3, 4, 5 using SSH/SCP:
    ```bash
    scp -r ./organizations/peerOrganizations/manufacturer <user>@10.147.17.2:/home/raj/HyperledgerFabric/
    ```

### **B. Starting the Services**
1.  **PC 1**: Start Orderer.
2.  **PC 2, 3, 4**: Run a specialized `docker-compose-distributed.yaml` that only starts the local peer and CA.
3.  **PC 5**: Start Explorer connected to PC1-PC4 over the ZeroTier IP.

### **C. External Environment (WSL2)**
- Ensure Windows Firewall on all 5 host PCs allows ZeroTier traffic (ports 9993 UDP/TCP) and Hyperledger Fabric ports (7050, 7051, 8051, 9051).

---

## 4. Why this approach works with ZeroTier?
ZeroTier provides a "Virtual Switch" effect. To the Hyperledger Fabric containers, it looks like all nodes are in one local network, even if they are in different locations. 

---

## 5. Summary Implementation Flow (P2P)
1.  **Join ZeroTier Network** on all 5 PCs.
2.  **Update /etc/hosts** for peer name resolution.
3.  **Generate Certs** on PC1 $\rightarrow$ **Distribute via SSH** to PC2-PC5.
4.  **Launch Peer containers** individually (PC1, PC2, PC3, PC4).
5.  **Launch Explorer** on PC5 pointing to the peer IPs.
