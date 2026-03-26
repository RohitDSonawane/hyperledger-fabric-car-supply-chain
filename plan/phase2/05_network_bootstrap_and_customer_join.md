# Phase 2.5: Distributed Network Bootstrap and Customer Join

## Goal
Bring up orderer and peers across hosts, then establish `supplychain` channel membership in distributed mode.

## Preconditions
- Phase 2.2 connectivity gate passed.
- Phase 2.3 artifacts verified on all hosts.
- Phase 2.4 distributed compose/env refactor completed.

## Execution Order
1. Start orderer on PC1 and validate health/logs.
2. Start Manufacturer peer on PC2.
3. Start Showroom peer on PC3.
4. From PC1 admin context, create/join channel for initial orgs.
5. Start Customer peer on PC4.
6. Run customer-org update flow (adapted `addCustomer` flow for distributed endpoints).

## Important Adjustments from Phase 1
- Ensure channel commands point to distributed orderer endpoint (not localhost).
- Ensure peer env targets remote peers via canonical hostnames.
- Ensure customer join scripts tolerate re-run/idempotency behavior already documented.

## Validation
- `peer channel getinfo -c supplychain` succeeds from each org context.
- Customer org appears in decoded channel config.
- All peers list channel membership.

## Rollback
- If join/update fails, stop customer peer stack and inspect config update transaction path.
- Keep orderer + initial org peers running unless root cause requires full reset.
