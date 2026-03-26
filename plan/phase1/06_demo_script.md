# Step 6: Live Demo Script (The "Car Supply Chain" Narrative)

This guide provides a professional "story" for the tech visit at the Student Chapter.

---

## 1. Introduction (The Scenario)
We are looking at a **Blockchain-based Car Supply Chain**.
- **The Problem**: Lack of transparency and counterfeit car parts or "history manipulation".
- **The Solution**: Every state change of a car is recorded on the Hyperledger Fabric ledger and signed by all participating organizations.

## 2. Live Demo Steps

### **Part A: Initial State (Empty Ledger)**
1.  Open **Hyperledger Explorer**.
2.  Show the "Dashboard" and the **Manufacturer**, **Showroom**, and **Customer** Org Peers (all green).
3.  Show zero transactions in the history.

### **Part B: Production (Manufacturer Logic)**
1.  Open your CLI/Terminal.
2.  **Submit: CreateCar** (ID: `CAR001`, Model: `Tesla X`, Status: `MANUFACTURED`).
3.  **Visual Check**: Open Explorer, go to the "Blocks" tab. Show a new block just appeared!
4.  **Proof**: Click the Transaction ID in Explorer to show the "Manufacturer" identity that signed this creation.

### **Part C: Logistics (The Transfer to Showroom)**
1.  **Submit: TransferCar** (ID: `CAR001`, NewOwner: `Showroom`, Status: `IN_SHOWROOM`).
2.  **Visual Check**: Show the block count increasing.
3.  **Narrative**: Explain that the Showroom can now "prove" this car came from the Manufacturer without having to call them—the blockchain is the proof itself.

### **Part D: Sale (The Transfer to Customer)**
1.  **Submit: TransferCar** (ID: `CAR001`, NewOwner: `John Doe`, Status: `OWNED`).
2.  **Visual Check**: Block 4 created.

### **Part E: The "Wow" Moment (Provenance History)**
1.  Perform a **GetCarHistory** for `CAR001`.
2.  **Impact**: Show the students the JSON list showing the car's entire life on the ledger:
    - [Time T1]: Created by Manufacturer.
    - [Time T2]: Moved to Showroom.
    - [Time T3]: Sold to John Doe.
3.  Explain that **none of these records can be deleted or changed back**.

---

## 3. Interaction Strategy (Asking Students)
Ask a student: "If John Doe says his car was never in the showroom, how can we prove it?"
- **Answer**: By looking at the immutability of Block 3 on the Hyperledger Explorer dashboard.

---

## 4. Summary for Students
1.  **Immutability** (You can't lie).
2.  **Traceability** (You know where it came from).
3.  **Trust** (The network handles the trust, not the people).
