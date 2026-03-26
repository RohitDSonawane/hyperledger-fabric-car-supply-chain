# Phase 2.2: Host Preparation and Connectivity Gate

## Goal
Prepare all 5 hosts for deterministic distributed deployment over ZeroTier.

## Preconditions
- Phase 2.1 sign-off complete.

## Tasks

### A. Clone the Project Repository
Since `Car-Supply-Chain` is safely tracked via Git, do not use `scp` or physical file transfers for the workspace codebase. On ALL 5 PCs, directly clone the repository to establish the identical project context:
```bash
# Recommended path convention for consistency:
mkdir -p /home/raj/HyperledgerFabric
cd /home/raj/HyperledgerFabric
git clone https://github.com/RohitDSonawane/hyperledger-fabric-car-supply-chain.git
cd hyperledger-fabric-car-supply-chain/multi-host
```

### A.1. Run Automated Prerequisite Checks
Before any work inside the repository, execute the automated checker script detailed in **Phase 2.1.5**. 
Consult `01_5_automated_prerequisites.md` and execute `/home/raj/HyperledgerFabric/plan/phase2/check_prerequisites.sh` on all 5 nodes before continuing.

### B. Join ZeroTier network and pin stable identity
- Join all hosts to the same ZeroTier network.
- Validate each host receives the approved static managed IP.

### C. Configure hostname resolution on all hosts
Update `/etc/hosts` inside Ubuntu on all five machines with the final mapping.
*(Note: The Phase 2.1.5 automated script already disabled WSL's `generateHosts` behavior, ensuring your manual edits to this file will remain permanent across Windows reboots).*

### D. Verify cross-host reachability
From each host:
```bash
ping -c 2 orderer.example.com
nc -zv peer0.manufacturer.example.com 7051
nc -zv peer0.showroom.example.com 9051
nc -zv peer0.customer.example.com 11051
```

### E. Container-level resolution check
Run a temporary container on each host and verify it resolves all Fabric hostnames.

## Validation Checklist
- All hosts resolve canonical names identically.
- Required ports are reachable according to the matrix.
- No conflicting local services occupy Fabric ports.

## Common Failure Modes
- OS firewall blocks ZeroTier/Fabric ports.
- Host-only DNS mapping works on host shell but not inside containers.
- Mixed Fabric binary/image versions across hosts.

## Rollback
- Remove partial host mappings and close opened ports if validation fails.
- Fix one host at a time, then re-run connectivity tests.
