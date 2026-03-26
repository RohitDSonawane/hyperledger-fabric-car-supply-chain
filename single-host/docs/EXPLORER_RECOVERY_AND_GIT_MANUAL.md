# Hyperledger Explorer Recovery and Git Hygiene Manual (Legacy)

This document is kept for history.

Use the split manuals in [README.md](README.md) for the current step-by-step documentation set.

## Purpose
This manual documents the exact recovery path used to stabilize Hyperledger Explorer for the Car Supply Chain network, plus safe Git practices to avoid committing credentials or private material.

It explains:
- what was failing
- why it failed
- what was changed
- how to validate the fix
- how to commit/push safely

## Problem Summary
Explorer initially had two classes of failures:

1. Startup/config failures
- Wallet/admin credential and profile issues blocked initialization.

2. Sync/indexing failures
- Explorer queried LSCC (`lscc.syscc`) which is not available in Fabric v2 lifecycle-only flow.
- This triggered synchronizer failures and prevented proper dashboard updates.

## Root Cause (Why)
Fabric v2 chaincode lifecycle does not rely on legacy LSCC state. Some Explorer builds still perform LSCC `GetChaincodes` queries and decode assumptions that fail in modern setups.

This caused:
- LSCC query errors
- protobuf decode errors (`illegal buffer`)
- sync processor closure

## Recovery Actions (What)
### A. Credentials moved to env file
- Added local env file support via `explorer/.env`.
- Added safe template file `explorer/.env.example` for git.
- Updated compose to read credentials from env vars instead of hardcoded values.
- Kept tracked connection profile credential-free using placeholders.

### A. Explorer startup stability
- Ensured Explorer container starts with valid connection profile and wallet path.
- Kept startup resilient even if patch logic does not match a specific image layout.

### A.1 Runtime profile rendering
- Added `explorer/render-connection-profile.js`.
- At container startup, script renders a runtime profile at:
  - `/opt/explorer/runtime-connection-profile/test-network.json`
- Runtime profile uses env values, so tracked JSON does not store real secrets.

### B. LSCC compatibility fallback
- Added `explorer/patch-lscc-fallback.js`.
- Script runs before `start.sh` in Explorer container.
- It patches Explorer gateway code at runtime to:
  - catch LSCC `GetChaincodes` failures
  - fallback safely toward lifecycle-compatible flow
  - prevent decode crashes from null/invalid LSCC payloads

### C. Validation workflow
- Restart Explorer stack cleanly.
- Confirm patch log appears.
- Confirm synchronizer does not terminate early.
- Confirm block/transaction counts increase in DB after a valid invoke.

## Files Involved
- `explorer/.env` (local only, ignored)
- `explorer/.env.example` (safe template)
- `explorer/render-connection-profile.js`
- `explorer/patch-lscc-fallback.js`
- `explorer/docker-compose.yaml`
- `explorer/connection-profile/test-network.json`
- supporting scripts updated during stabilization:
  - `setOrgEnv.sh`
  - `addCustomer/addCustomer.sh`
  - `scripts/customer-scripts/updateChannelConfig.sh`
  - `scripts/ccutils.sh`

## Step-by-Step Operations

### 0. Prepare env file (required)
```bash
cd /home/raj/HyperledgerFabric/Car-Supply-Chain/explorer
cp .env.example .env
# edit .env with local values if needed
```

### 1. Start/restart Explorer stack
```bash
cd /home/raj/HyperledgerFabric/Car-Supply-Chain/explorer
docker compose down -v
docker compose up -d
```

### 2. Check patch + sync logs
```bash
docker logs explorer.mynetwork.com --tail 900 | grep -Ei "patch-lscc-fallback|Synchronizer|queryInstantiatedChaincodes|LSCC GetChaincodes failed|illegal buffer|Closing client processor"
```

Expected:
- patch applied message appears
- no recurring `illegal buffer`
- no immediate synchronizer close after startup

### 3. Verify Explorer DB counters
```bash
docker exec -it explorerdb.mynetwork.com psql -U hppoc -d fabricexplorer -c "select count(*) as blocks from blocks;"
docker exec -it explorerdb.mynetwork.com psql -U hppoc -d fabricexplorer -c "select count(*) as txs from transactions;"
```

### 4. Create a test transaction
```bash
cd /home/raj/HyperledgerFabric/Car-Supply-Chain
./network.sh cc invoke -org 1 -c mychannel -ccn carcc -ccic '{"Args":["CreateCar","CAR901","Honda","City","White","45000"]}'
```

### 5. Re-check counters
```bash
cd /home/raj/HyperledgerFabric/Car-Supply-Chain/explorer
docker exec -it explorerdb.mynetwork.com psql -U hppoc -d fabricexplorer -c "select count(*) as blocks from blocks;"
docker exec -it explorerdb.mynetwork.com psql -U hppoc -d fabricexplorer -c "select count(*) as txs from transactions;"
```

Success criterion:
- both counters increase after invoke

### 6. Chaincode data validation
```bash
cd /home/raj/HyperledgerFabric/Car-Supply-Chain
./network.sh cc query -org 2 -c mychannel -ccn carcc -ccqc '{"Args":["ReadCar","CAR901"]}'
```

Success criterion:
- returned JSON for `CAR901` matches invoke payload

## UI Validation
Open:
- `http://localhost:8080`

Verify:
- channel shown
- block/transaction counters non-zero
- latest transaction appears after refresh

## Git Safety: Do Not Commit Credentials
Before commit/push:

0. Verify env policy:
```bash
cd /home/raj/HyperledgerFabric/Car-Supply-Chain
git check-ignore -v explorer/.env
```

Expected:
- `explorer/.env` is ignored
- `explorer/.env.example` is trackable

1. Run secret scan:
```bash
cd /home/raj/HyperledgerFabric/Car-Supply-Chain
rg -n -i "password|passwd|adminpw|secret|private key|BEGIN .*PRIVATE KEY|apikey|token|jwt|bearer" .
```

2. Review staged files and diffs:
```bash
git status
git diff --name-only
git diff
```

3. Stage intentionally:
```bash
git add -p
```

4. Confirm no sensitive/generated artifacts are staged.

## Suggested Commit Scope
Keep this recovery change isolated in one commit:
- Explorer fallback patch script
- compose/profile config updates needed for startup
- runbook docs

## Suggested Commit Message
```text
fix(explorer): stabilize Fabric v2 sync with lscc fallback and recovery docs
```

## Troubleshooting Quick Reference
1. Patch log missing
- Check `explorer/docker-compose.yaml` command still runs patch script before `start.sh`.

2. Sync closes immediately
- Re-check logs for `illegal buffer` or LSCC errors.
- Ensure latest `patch-lscc-fallback.js` is mounted and container restarted with `down -v`.

3. DB counts not moving
- Confirm invoke command actually succeeds (`status:200`).
- Re-check peer/orderer connectivity and channel name (`mychannel`).

4. UI still stale with DB moving
- Hard refresh browser.
- Check browser network tab for API errors.

## Outcome Snapshot (Validated)
- Explorer patch applied successfully at startup.
- Explorer DB counts increased after invoke.
- Chaincode query for `CAR901` returned expected payload.
- End-to-end path is operational for blocks/transactions visibility.
