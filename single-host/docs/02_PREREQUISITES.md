# 02 - Prerequisites

## Required Host Tools
- Docker
- Docker Compose
- Bash
- Node.js (used for helper scripts)
- `peer`, `configtxlator`, and Fabric binaries in project `bin/`

## Verify Core Commands
```bash
cd /home/raj/HyperledgerFabric/Car-Supply-Chain
./network.sh -h
ls bin
```

## Repository Expectations
- Working directory:
  - `/home/raj/HyperledgerFabric/Car-Supply-Chain`
- Explorer path:
  - `/home/raj/HyperledgerFabric/Car-Supply-Chain/explorer`

## Security Baseline
- Use `explorer/.env` for local credentials.
- Do not hardcode passwords in tracked JSON/YAML.
- Do not commit `organizations/**/keystore/*` or wallets.
