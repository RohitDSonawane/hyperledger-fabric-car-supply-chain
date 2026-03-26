# Step 2: Customizing the Network (The "Car Supply Chain" Rebranding)

Since we want a visual, professional demo, we are renaming `Org1`, `Org2`, and `Org3` of the standard `test-network` to **Manufacturer**, **Showroom**, and **Customer**.

---

## 1. Directory Structure Prep
All changes will be made in `fabric-samples/test-network/` or its `addOrg3` subdirectory.

## 2. Cryptogen Configuration (Organizations)
Open `organizations/cryptogen/crypto-config-org1.yaml` and rename:
- `Name: Org1` $\rightarrow$ `Name: Manufacturer`
- `Domain: org1.example.com` $\rightarrow$ `Domain: manufacturer.example.com`

Repeat for Org2 and Org3:
- Org2 $\rightarrow$ `Showroom`
- Org3 $\rightarrow$ `Customer`

## 3. Configtx Updates (Channel Genesis)
Modify `configtx/configtx.yaml` to represent our 3 Organizations.
- **Section: Organizations**: Update the `# MSPID` and `Name` for all three.
- **Section: Profiles**: Ensure `TwoOrgsApplicationGenesis` (and its 3rd Org variant) is updated with our new names.

## 4. Docker Compose Environment Variables
Rename the service hostnames in `compose/` to be:
- `peer0.manufacturer.example.com:7051`
- `peer0.showroom.example.com:8051`
- `peer0.customer.example.com:9051`

Update the `organizations/` scripts to correctly point to the new domain-named folders.

## 5. Network Launch Logic
We will use custom versions of `./network.sh` and `./addOrg3/addOrg3.sh` to ensure we generate the correct identity material for our 3 specific entities.

---

## 6. Verification
Run:
```bash
./network.sh up -ca
```
If successful, the `organizations` directory will contain three folders:
- `manufacturer.example.com`
- `showroom.example.com`
- `customer.example.com` (after `addOrg3`)
