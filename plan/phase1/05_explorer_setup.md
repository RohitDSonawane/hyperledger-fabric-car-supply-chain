# Step 5: Hyperledger Explorer Setup (Visualizing the Supply Chain)

This step explains how to deploy the Hyperledger Explorer to visualize the car lifecycle on the `supplychain` channel.

---

## 1. Explorer Configuration
We will use the official `hyperledger/explorer` and `hyperledger/explorer-db` Docker images.

## 2. Connection Profile (`connection-profile.json`)
We must create a custom profile representing our 3 renamed organizations:
- **ManufacturerMSP**
- **ShowroomMSP**
- **CustomerMSP**

### **Host Mapping**:
Map the internal Docker service names within the `connection-profile.json`:
- `peer0.manufacturer.example.com`
- `peer0.showroom.example.com`
- `peer0.customer.example.com`

## 3. Cryptoconfig Mounting (Critical)
The Explorer must have read access to the local `crypto-config` folders generated in Step 2.
- `organizations/peerOrganizations/manufacturer.example.com`
- `organizations/peerOrganizations/showroom.example.com`
- `organizations/peerOrganizations/customer.example.com`

## 4. Docker-Compose Explorer
Create a file `explorer/docker-compose.yaml` with:
- **Service: explorer-db** (PostgreSQL)
- **Service: explorer** (Backend/Frontend)
- **Volume**: Mount the customized `connection-profile.json` and `crypto-config` folders.

## 5. Startup Sequence
1.  Ensure the Fabric network is UP and the channel is CREATED.
2.  Deploy the chaincode (`carcc`).
3.  Run the Explorer:
    ```bash
    cd explorer
    docker-compose up -d
    ```

---

## 6. Accessing the Dashboard
- **URL**: `http://localhost:8080`
- **Port Visibility**: Ensure port 8080 and 5432 (DB) are open in WSL2.
- **Login**: Use standard `admin` / `adminpw`.

Once logged in, you should see three colored squares representing our three organization peers (Manufacturer, Showroom, Customer).
The "Blocks" tab will show every move the car makes (Creation $\rightarrow$ Transfer $\rightarrow$ Sale).
