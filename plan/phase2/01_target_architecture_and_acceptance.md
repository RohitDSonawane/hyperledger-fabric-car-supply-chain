# Phase 2.1: Target Architecture and Acceptance Criteria

## Goal
Define the exact distributed target state before any host-level changes.

## Target Topology (5 PCs)
- PC1: Manager + Orderer + admin CLI
- PC2: Manufacturer peer (+ optional CA if selected)
- PC3: Showroom peer (+ optional CA if selected)
- PC4: Customer peer (+ optional CA if selected)
- PC5: Explorer + Postgres

## Naming and Addressing Contract
Use stable ZeroTier addressing and keep canonical Fabric names:
- orderer.example.com -> PC1 ZeroTier IP
- peer0.manufacturer.example.com -> PC2 ZeroTier IP
- peer0.showroom.example.com -> PC3 ZeroTier IP
- peer0.customer.example.com -> PC4 ZeroTier IP
- explorer.example.com -> PC5 ZeroTier IP

## Required Port Matrix
Open and verify these flows:
- Orderer: 7050, 7053, 9443
- Manufacturer peer: 7051, 7052, 9444
- Showroom peer: 9051, 9052, 9445
- Customer peer: 11051, 11052, 9446 (if aligned to existing style)
- Explorer UI: 8080
- Postgres: 5432 (internal or restricted)
- ZeroTier control/data: 9993 UDP/TCP

## Deployment Contract
- Hostnames and IPs must be resolvable from all 5 hosts and from all Fabric containers.
- MSP/TLS artifact paths must be identical by convention on each host.
- One authoritative operator node (PC1) controls channel updates and chaincode commit.

## Exit Criteria
- Approved topology table with final hostnames and IPs.
- Confirmed port matrix and firewall policy.
- Chosen crypto mode (`cryptogen` pilot or Fabric CA-driven).
- **Mandated orderer model:** Use a **Single Orderer** on PC1 to minimize variables during the initial network and connectivity cutover. Upgrading to a distributed 3-node Raft consensus (e.g., across PC1, PC2, PC3) should be strictly deferred to Phase 3.

## Rollback
- If topology sign-off is incomplete, do not proceed to host preparation.
