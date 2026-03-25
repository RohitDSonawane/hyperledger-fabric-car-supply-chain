# 03 - Network And Channel Setup

## Start Fabric Network
```bash
cd /home/raj/HyperledgerFabric/Car-Supply-Chain
./network.sh up createChannel -ca -c mychannel
```

If your local workflow already has a network up, use the command variant that matches your existing scripts and `network.config`.

## Verify Core Containers
```bash
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -Ei "orderer|peer0"
```

## Check Channel Reachability
Use your org env helper and peer CLI to confirm channel is available.

Example:
```bash
export $(./setOrgEnv.sh Manufacturer | xargs)
peer channel getinfo -c mychannel
```

## Expected Result
- Orderer and peer containers are healthy.
- `mychannel` channel exists and is queryable.
