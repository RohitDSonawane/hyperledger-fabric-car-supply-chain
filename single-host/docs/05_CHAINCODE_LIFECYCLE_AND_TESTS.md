# 05 - Chaincode Lifecycle And Tests

## Objective
Ensure `carcc` is available on channel `mychannel`, then validate invoke/query flows.

## List Installed/Committed Chaincode
```bash
cd /home/raj/HyperledgerFabric/Car-Supply-Chain/single-host
./network.sh cc list -org 1
```

## Invoke Transaction
```bash
./network.sh cc invoke -org 1 -c mychannel -ccn carcc -ccic '{"Args":["CreateCar","CAR901","Honda","City","White","45000"]}'
```

Expected:
- command returns success
- peer output includes `status:200`

## Query Transaction Result
```bash
./network.sh cc query -org 2 -c mychannel -ccn carcc -ccqc '{"Args":["ReadCar","CAR901"]}'
```

Expected JSON fields:
- `ID`
- `make`
- `model`
- `owner`
- `status`

## Notes
Utility scripts were adjusted so invoke/query use explicit channel args and safer defaults.
