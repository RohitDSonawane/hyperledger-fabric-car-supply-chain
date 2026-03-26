# 04 - Add Customer Organization

## Objective
Add `CustomerMSP` to channel `mychannel` and ensure peers are discoverable.

## Run Customer Add Flow
```bash
cd /home/raj/HyperledgerFabric/Car-Supply-Chain/single-host/addCustomer
./addCustomer.sh
```

## Validate Membership
From project root:
```bash
cd /home/raj/HyperledgerFabric/Car-Supply-Chain/single-host
export $(./setOrgEnv.sh Manufacturer | xargs)
peer channel fetch config /tmp/config_block.pb -o localhost:7050 -c mychannel --tls --cafile organizations/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem
```

Then inspect decoded config for `CustomerMSP` presence.

## Expected Result
- `CustomerMSP` exists in channel config.
- No blocking errors from update transaction path.

## Notes
During stabilization, channel update scripts were made idempotent so repeated runs do not fail when `CustomerMSP` is already present.
