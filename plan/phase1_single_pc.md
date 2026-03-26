# Phase 1: Single-PC Implementation Implementation (Simulation Mode)

This phase focuses on getting the **Car Supply Chain** network running locally on one machine. We will simulate the three organizations (Manufacturer, Showroom, Customer) using Docker containers.

---

## 1. Environment Setup
Ensure all prerequisites are installed for Hyperledger Fabric v2.5.

- **Docker & Docker Compose**: `docker version` (>= 20.10.x), `docker-compose version` (>= 2.x).
- **Go Syntax**: `go version` (>= 1.21.x).
- **Node.js (for Explorer)**: `node -v` (>= 18.x).
- **Fabric Binaries & Docker Images**:
  ```bash
  curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.5.4 1.5.7
  ```
- **Path Configuration**:
  Add `fabric-samples/bin` to your system path in `~/.bashrc`.

---

## 2. Network Customization (3-Org Car Supply Chain)
Instead of Generic "Org1", we will modify `test-network` to represent our entities.

### **Step A: Modify Organization Definitions**
We will use the `addOrg3` template and rename:
- **Org1** $\rightarrow$ `Manufacturer`
- **Org2** $\rightarrow$ `Showroom`
- **Org3** $\rightarrow$ `Customer`

### **Step B: Key Files to Update**
1.  **`organizations/cryptogen/`**: Update YAML files for each organization name.
2.  **`compose/`**: Rename service names in docker-compose files (e.g., `peer0.manufacturer.example.com`).
3.  **`configtx/configtx.yaml`**: Update organization profiles and MSP IDs.

---

## 3. Network Lifecycle
Start the network with three organizations and a channel named `supplychain`.

```bash
# From fabric-samples/test-network
./network.sh up createChannel -c supplychain -ca
./addOrg3/addOrg3.sh up -c supplychain
```
*Note: We will customize the script to ensure Org3 is treated as 'Customer'.*

---

## 4. Chaincode Implementation (Go)
The chaincode will handle the "Car" asset life-cycle.

### **Features:**
- `CreateCar`: Manufacturer creates the car record.
- `TransferCar`: Manufacturer transfers to Showroom; Showroom transfers to Customer.
- `QueryHistory`: Show the full provenance (Manufacturer $\rightarrow$ Showroom $\rightarrow$ Customer).

### **Deployment:**
```bash
./network.sh deployCC -ccn carcc -ccp ../asset-transfer-basic/chaincode-go/ -ccl go
```

---

## 5. Visualizing with Hyperledger Explorer
Deploy Explorer to see blocks, transactions, and the ledger state.

1.  **Configuration**: Map the `connection-profile` of the Three Orgs to Explorer's `config.json`.
2.  **Mounting Certificates**: Ensure Explorer has read access to the crypto-config folder.
3.  **Launch**:
    ```bash
    docker-compose -f explorer/docker-compose.yaml up -d
    ```

---

## 6. Live Demo Flow (Local Simulation)
1.  **Visual Check**: Open Explorer at `localhost:8080`.
2.  **Creation**: Use CLI to invoke `CreateCar` (Show "Manufacturer" ownership).
3.  **Movement**: Transfer to Showroom, then to Customer.
4.  **Provenance**: Click on a car ID in Explorer/CLI to show its entire history on the blockchain.
