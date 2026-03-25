# 06 - Explorer Setup With Env Credentials

## Objective
Run Hyperledger Explorer without hardcoding credentials in tracked files.

## Files Used
- `explorer/.env` (local, ignored)
- `explorer/.env.example` (committed template)
- `explorer/render-connection-profile.js`
- `explorer/patch-lscc-fallback.js`
- `explorer/docker-compose.yaml`

## Prepare Env
```bash
cd /home/raj/HyperledgerFabric/Car-Supply-Chain/explorer
cp -n .env.example .env
```

Edit `.env` only if you need different values.

## Start Explorer
```bash
docker compose down -v
docker compose up -d
```

## Validate Startup
```bash
docker logs explorer.mynetwork.com --tail 200 | grep -Ei "render-connection-profile|patch-lscc-fallback|error|Synchronizer"
```

Expected:
- runtime profile render message appears
- LSCC fallback patch message appears
- no recurring fatal sync crash

## Why This Works
- Credentials are injected from env at runtime.
- Connection profile in git keeps placeholders, not real secrets.
- LSCC fallback patch avoids legacy lifecycle assumptions causing sync failure.
