# Phase 2.6: Chaincode Lifecycle and Functional Validation

## Goal
Verify `carcc` behaves identically on distributed topology.

## Preconditions
- `supplychain` channel healthy across all org peers.

## Tasks

### A. Chaincode lifecycle checks
From admin node:
- verify installed packages
- verify committed definition on `supplychain`

### B. Functional invoke/query tests
Run at least these flows:
1. Manufacturer creates a new car asset.
2. Transfer ownership Manufacturer -> Showroom.
3. Transfer ownership Showroom -> Customer.
4. Query current state and full history.

### C. Cross-org endorsement check
- Execute invoke/query from multiple org contexts to ensure policy and connectivity are valid.

## Acceptance Criteria
- All invoke operations return success (`status:200`).
- Queries return expected JSON shape and ownership transitions.
- History/provenance reflects full lifecycle order.

## Non-Functional Checks
- Peer logs show no recurring TLS handshake failures.
- Endorsement latency remains acceptable on ZeroTier network.

## Rollback
- If lifecycle commit mismatch occurs, halt new invokes and reconcile package/sequence mismatch before proceeding.
