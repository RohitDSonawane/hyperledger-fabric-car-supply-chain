# Step 4: Chaincode Development (Car Supply Chain in Go)

The Smart Contract will be developed in Go and live in `fabric-samples/car-supply-chain/chaincode-go/`.

---

## 1. Key Business Logic (Car Lifecycle)

The lifecycle will have 3 distinct stages:
1.  **Manufacturer (Creation)**: Asset is created with status `MANUFACTURED`.
2.  **Showroom (In Transit)**: Ownership is transferred to the Showroom with status `IN_SHOWROOM`.
3.  **Customer (Final Sale)**: Ownership is transferred to the Customer with status `OWNED`.

## 2. Go Model Definition (`car.go`)
```go
type Car struct {
    ID          string `json:"ID"`
    Make        string `json:"make"`
    Model       string `json:"model"`
    Color       string `json:"color"`
    Owner       string `json:"owner"`      // Manufacturer/Showroom/Customer
    Status      string `json:"status"`     // MANUFACTURED, IN_SHOWROOM, OWNED
    Price       int    `json:"price"`
    MfgDate     string `json:"mfgDate"`
}
```

## 3. Core Go Functions

### **CreateCar (Manufacturer Only)**
- **Role Check**: Verify the submitter is from `ManufacturerMSP`.
- **Validation**: Check if `ID` already exists.
- **Action**: PutState with status `MANUFACTURED`.

### **TransferCar (Multi-Step)**
- **Role Check**: 
    - If transferring from Manufacturer to Showroom: Verify `ManufacturerMSP`.
    - If transferring from Showroom to Customer: Verify `ShowroomMSP`.
- **Action**: Update `Owner` and `Status`.

### **GetCarHistory (Provenance)**
- **Action**: Use `GetHistoryForKey(carID)`.
- **Demo Utility**: Shows the transaction IDs, timestamps, and state changes (The "Blockchain Proof").

---

## 4. Chaincode Deployment Script
Deploy the chaincode to the `supplychain` channel for all three organizations.
```bash
./network.sh deployCC \
    -ccn carcc \
    -ccp ../car-supply-chain/chaincode-go/ \
    -ccl go \
    -c supplychain \
    -ccep "OR('ManufacturerMSP.member','ShowroomMSP.member','CustomerMSP.member')"
```
*(Note: We use OR policy to allow any of the 3 orgs to interact, but enforce business logic inside the code).*

---

## 5. Deployment Verification
Invoke the `initLedger` function to seed the data:
```bash
peer chaincode invoke -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls --cafile $ORDERER_CA \
    -C supplychain -n carcc \
    --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_ORG1_CA \
    -c '{"function":"InitLedger","Args":[]}'
```
Check that 5-10 cars are created in the world state.
