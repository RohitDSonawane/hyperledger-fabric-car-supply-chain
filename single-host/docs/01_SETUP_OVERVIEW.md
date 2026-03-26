# 01 - Setup Overview

## Goal
Build and run the Car Supply Chain Fabric network from scratch, deploy chaincode, integrate Explorer, and validate block/transaction visibility.

## Scope
- Fabric network bootstrapping
- Channel and organization setup
- Chaincode deployment and test invoke/query
- Explorer startup with env-based credentials
- Operational validation and troubleshooting

## High-Level Flow
1. Prepare host dependencies and binaries.
2. Start Fabric network and create channel.
3. Add Customer organization to channel.
4. Deploy and test `carcc` chaincode on `mychannel`.
5. Configure and start Explorer with env file.
6. Verify Explorer sync, DB counters, and UI.
7. Prepare safe Git commit without credentials.

## Important Principles
- Never commit real credentials or private keys.
- Keep runtime secrets in `explorer/.env` only.
- Commit only templates (`.env.example`) and docs/scripts.
- Validate each step before moving to the next.
