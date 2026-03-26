# Phase 2.3: Crypto and Artifact Distribution Strategy

## Goal
Generate and distribute only required identity/config artifacts to each host with integrity checks. 
*(Note: Your project codebase—scripts, docker-compose files, etc.—must already be present across all hosts via `git clone` from Phase 2.2. The transfer mechanisms below are STRICTLY for sensitive, non-version-controlled cryptographic materials like MSP keys and TLS certificates that `.gitignore` correctly blocks).*

## Recommended Pilot Choice
For immediate migration from current Phase 1: keep `cryptogen` model first, then evaluate CA transition after distributed baseline is stable.

## Artifact Ownership Model
- PC1 (Manager) generates:
  - `organizations/ordererOrganizations/**`
  - `organizations/peerOrganizations/**`
  - channel artifacts under `channel-artifacts/` as needed
- Remote hosts receive only their required subtree.

## Minimum Distribution Matrix
- PC1 keeps authoritative root.
- PC2 receives `organizations/peerOrganizations/manufacturer.example.com/**` into `/multi-host/organizations/`.
- PC3 receives `organizations/peerOrganizations/showroom.example.com/**` into `/multi-host/organizations//`.
- PC4 receives `organizations/peerOrganizations/customer.example.com/**` into `/multi-host/organizations//`.
- PC5 receives Explorer subset into `/multi-host/explorer/`.

## Transfer Procedure
1. Package each host-specific artifact set into tarballs.
2. Generate SHA256 checksums on PC1.
3. Transfer via `scp`/`rsync` over ZeroTier.
4. Verify checksums on destination before deployment.

## Security Guardrails
- Never copy private keys not needed by destination role.
- Restrict file permissions (`chmod 600` for private keys, `700` for key dirs).
- Keep transfer logs for audit.

## Validation
- Peer/orderer TLS files present at expected paths on target hosts.
- Admin MSP exists on PC1 for channel and chaincode admin operations.
- Explorer host has only read material, no admin private keys.

## Rollback
- Delete transferred artifact set on a host if checksum mismatch occurs.
- Repackage and retransmit from trusted source on PC1.
