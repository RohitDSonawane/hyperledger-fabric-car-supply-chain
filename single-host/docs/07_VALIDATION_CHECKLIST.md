# 07 - Validation Checklist

Use this checklist after setup and after any major change.

## Fabric Health
- [ ] Peer and orderer containers are running.
- [ ] Channel `mychannel` is queryable.

## Chaincode Health
- [ ] `carcc` appears in chaincode list.
- [ ] Invoke returns success (`status:200`).
- [ ] Query returns expected car JSON.

## Explorer Health
- [ ] Explorer container starts and serves UI on port `8080`.
- [ ] Logs show profile render + fallback patch applied.
- [ ] Synchronizer does not immediately close.

## DB Health
Run:
```bash
cd /home/raj/HyperledgerFabric/Car-Supply-Chain/explorer
docker exec -it explorerdb.mynetwork.com psql -U hppoc -d fabricexplorer -c "select count(*) as blocks from blocks;"
docker exec -it explorerdb.mynetwork.com psql -U hppoc -d fabricexplorer -c "select count(*) as txs from transactions;"
```

- [ ] Counts are non-zero.
- [ ] Counts increase after a new invoke.

## UI Health
- [ ] Dashboard shows non-zero blocks/transactions.
- [ ] New transactions appear after refresh.
