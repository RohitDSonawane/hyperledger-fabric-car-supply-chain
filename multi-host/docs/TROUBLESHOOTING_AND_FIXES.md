# Troubleshooting And Fixes

This file is dedicated to problems faced during setup and the exact fixes applied.

## 1. Explorer wallet/config startup failure
### Symptoms
- Explorer failed to start with wallet/config errors.

### Cause
- Missing/incorrect admin credential fields and wallet path assumptions.

### Fix
- Corrected connection profile client fields.
- Ensured wallet mount and runtime profile generation are valid.

### Validation
- Explorer starts and responds on `http://localhost:8080`.

## 2. Invalid platform configuration
### Symptoms
- Explorer showed invalid platform configuration at startup.

### Cause
- Connection profile fields or identity settings were incomplete/misaligned.

### Fix
- Aligned `client` fields and org/peer mappings.
- Added env-driven rendering for credentials.

### Validation
- Explorer logs show successful initialization and discovery.

## 3. LSCC sync failure on Fabric v2 lifecycle
### Symptoms
- Synchronizer failed with LSCC-related errors.
- Error chain included `lscc.syscc` not found.

### Cause
- Explorer attempted legacy LSCC `GetChaincodes` path against Fabric v2 lifecycle model.

### Fix
- Added runtime patch script: `explorer/patch-lscc-fallback.js`.
- Patched call path to tolerate LSCC failure and continue lifecycle-compatible flow.

### Validation
- Logs show fallback patch applied.
- Synchronizer no longer hard-stops on LSCC path.

## 4. Illegal buffer decode crash
### Symptoms
- `Error: illegal buffer` during chaincode query decode in Explorer sync.

### Cause
- LSCC payload decode attempted on invalid/null data after fallback path.

### Fix
- Hardened patch logic to guard decode patterns and prevent fatal parse path.

### Validation
- Illegal buffer no longer recurring after patched restart.

## 5. SQL count query syntax issue
### Symptoms
- `count()` query failed in Postgres.

### Cause
- PostgreSQL requires `count(*)` for parameterless aggregate.

### Fix
Use:
```bash
select count(*) as blocks from blocks;
select count(*) as txs from transactions;
```

### Validation
- Returned numeric rows correctly.

## 6. Wrong network command mode
### Symptoms
- `./network.sh invokeCar` returned usage/help text.

### Cause
- Mode does not exist in this project script.

### Fix
Use cc wrapper commands:
```bash
./network.sh cc invoke -org 1 -c mychannel -ccn carcc -ccic '{"Args":["CreateCar","CAR901","Honda","City","White","45000"]}'
./network.sh cc query -org 2 -c mychannel -ccn carcc -ccqc '{"Args":["ReadCar","CAR901"]}'
```

### Validation
- Invoke returned `status:200`.
- Query returned expected car JSON.

## 7. Customer org update friction
### Symptoms
- Re-runs failed with already-exists style update errors.

### Cause
- Channel update logic was not idempotent.

### Fix
- Improved update scripts with safer retries and idempotent handling.

### Validation
- Repeated runs no longer fail when membership already exists.

## 8. Credential handling risk before git push
### Symptoms
- Risk of leaking passwords or key material in committed files.

### Cause
- Runtime credentials could be hardcoded in tracked configs.

### Fix
- Moved runtime credentials to `explorer/.env`.
- Added `explorer/.env.example` template.
- Added ignore policy for local env files.

### Validation
- Runtime works with env file.
- Tracked files keep placeholders/templates only.
