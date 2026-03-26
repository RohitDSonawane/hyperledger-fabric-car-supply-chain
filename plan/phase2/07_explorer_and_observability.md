# Phase 2.7: Explorer, Metrics, and Operational Visibility

## Goal
Bring Hyperledger Explorer online on PC5 using distributed connection profiles and verify ledger observability.

## Preconditions
- Distributed network and chaincode operations stable.
- Explorer host has required read-only cert material.

## Tasks

### A. Prepare distributed Explorer connection profile
- Replace localhost endpoints with canonical distributed hostnames/ports.
- Keep credential handling env-driven (`.env`) as in current Phase 1 hardening.

### B. Deploy Explorer and Postgres on PC5
- Start database first, then Explorer.
- confirm render and patch scripts execute if retained from current setup.

### C. Validate synchronization
- dashboard loads on PC5:8080
- block and transaction counters are non-zero
- new invoke increments counters

### D. Add lightweight observability checks
- standard command set for orderer/peer logs
- periodic health probes for endpoint availability

## Acceptance Criteria
- Explorer remains stable without recurring sync crash loops.
- UI reflects new transactions from distributed invokes.
- DB count queries return increasing values after test transactions.

## Rollback
- If Explorer sync is unstable, keep Fabric network running and isolate Explorer profile/cert mapping issues.
