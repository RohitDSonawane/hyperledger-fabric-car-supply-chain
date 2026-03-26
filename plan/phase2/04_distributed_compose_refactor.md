# Phase 2.4: Distributed Compose and Script Refactor

## Goal
Refactor runtime configuration from localhost/single-network assumptions to routable distributed endpoints.

## Why This Phase Is Mandatory
Current files are local-mode oriented:
- `setOrgEnv.sh` binds to localhost peer ports.
- existing compose files assume one Docker network and local DNS.
- docs invoke operations through local-only addresses.

## Refactor Work Items

### A. Introduce distributed compose overlays
Target Directory: `Car-Supply-Chain/multi-host/compose/`

Create host-specific compose overlays:
- PC1: orderer + admin CLI (optional)
- PC2: manufacturer peer
- PC3: showroom peer
- PC4: customer peer
- PC5: explorer + postgres

Each overlay should:
- expose only local service ports needed externally
- set `CORE_PEER_GOSSIP_EXTERNALENDPOINT` to canonical hostname + port
- **MANDATORY**: include `extra_hosts` to map canonical hostnames (like `orderer.example.com`) directly to their ZeroTier IPs. Docker containers do not inherit the host's `/etc/hosts` file natively.

### B. Parameterize Existing Scripts (Do not duplicate)
Instead of creating parallel `*Distributed.sh` scripts that will fall out of sync, refactor `setOrgEnv.sh` and `network.sh` to read from a `.env` file containing endpoint variables.
For example, let `.env` define:
- `MODE=distributed`
- `ORDERER_ENDPOINT=orderer.example.com:7050`
- `MANUFACTURER_PEER_ENDPOINT=peer0.manufacturer.example.com:7051`

Change `setOrgEnv.sh` so that when it detects `MODE=distributed`, it overrides the internal `localhost` default endpoints with the `.env` distributed hostnames.

### D. Preserve backward compatibility
Keep current single-PC scripts intact. Add distributed paths instead of replacing legacy behavior.

## Validation
- Each host can start only its own stack without unresolved dependencies.
- PC1 admin commands can connect to all peers/orderer via distributed endpoints.
- Gossip external endpoint values match reachable hostnames.

## Rollback
- If distributed overlay fails, stop only the affected host stack.
- Revert to last known-good compose/env overlay version.
