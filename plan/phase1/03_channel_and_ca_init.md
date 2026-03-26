# Step 3: Channel and CA Initialization (Bootstrapping the Supply Chain)

This step explains how to create the `supplychain` channel and join all three organizations (Manufacturer, Showroom, Customer).

---

## 1. Local CA Initialization
Start the Certificate Authorities (CAs) for each organization first. Use the `-ca` flag to ensure that all identity material is generated dynamically.
```bash
./network.sh up -ca
```
- Creates `ca.manufacturer.example.com`
- Creates `ca.showroom.example.com`

## 2. Bootstrapping the "Customer" (Org3)
Since `test-network` treats the 3rd Org differently, we manually add it.
```bash
cd addOrg3
./addOrg3.sh up -ca
```
This launches `ca.customer.example.com` and its associated peer.

## 3. Creating the Channel `supplychain`
We will use a custom script for this.
```bash
./network.sh createChannel -c supplychain
```
- Generates the Genesis Block.
- Joins **Manufacturer** (Org1) and **Showroom** (Org2).
- Updates Anchor Peers for both.

## 4. Join the "Customer" (Org3) to the Channel
Use the `addOrg3` logic to join our third peer to the `supplychain` channel.
```bash
cd addOrg3
./addOrg3.sh join -c supplychain
```

## 5. Peer Verification (CLI)
Confirm that all three peers (Manufacturer, Showroom, and Customer) are on the channel.
```bash
# Check Manufacturer (Port 7051)
peer channel list

# Check Showroom (Port 8051)
CORE_PEER_ADDRESS=localhost:8051 peer channel list

# Check Customer (Port 9051)
CORE_PEER_ADDRESS=localhost:11051 peer channel list
```
*(Note: Default port for Org3 in test-network is usually 11051 unless we change it).*

---

## 6. Channel Anchor Peer Update (Critical for Gossip)
To ensure the organizations can "talk" to each other properly, ensure anchor peer updates are sent for all 3.
- `ManufacturerAnchor.tx`
- `ShowroomAnchor.tx`
- `CustomerAnchor.tx`

This will be handled by the `./network.sh createChannel` and `./addOrg3.sh` scripts once we've renamed the entries in `configtx.yaml`.
