# Phase 2.8: Cutover Runbook, Rollback, and Handover

## Goal
Convert the distributed setup from pilot state to repeatable operating mode with clear rollback controls.

## Cutover Checklist
- **MANDATORY**: Verify current working directory is `Car-Supply-Chain/multi-host/`.
- All prior phase acceptance criteria are marked complete.
- Run full validation sequence end-to-end once without manual patching.
- Capture final host/IP/port matrix and distributed command cheat sheet.

## Risk Controls

### Configuration drift control
- Maintain a single source-of-truth config bundle on PC1.
- Version and checksum all distributed config packages.

### Change management
- Apply one topology change at a time.
- Require validation gate pass before next change.

### Security controls
- Re-check no secrets are committed.
- Review key/cert permissions on all hosts.
- Restrict SSH and admin access paths.

## Rollback Strategy

### Soft rollback (preferred)
- Stop only newly changed component.
- Restore previous compose/env package for that host.
- Re-run validation scope for impacted services.

### Hard rollback
- If consensus/channel operations are unstable, freeze distributed writes and revert to Phase 1 environment for demo continuity.

## Handover Deliverables
- Final distributed architecture document.
- Operations commandbook for start/stop/health/recovery.
- Unified automated validation script (`validate_distributed.sh`) that pings all nodes, queries channel height from all peers, and submits a test cross-node invoke transaction.
- Known-issues log and owner mapping.
- Backlog items for Phase 3 risk-mitigation.
