# Phase 2 Folder Index - Distributed 5-PC Migration

This folder contains the detailed execution plan to migrate the Car Supply Chain setup from single-PC mode to distributed multi-host deployment.

## Reading Order
1. `01_target_architecture_and_acceptance.md`
2. `01_5_automated_prerequisites.md`
3. `02_host_preparation_and_connectivity.md`
4. `03_artifact_strategy_and_distribution.md`
5. `04_distributed_compose_refactor.md`
6. `05_network_bootstrap_and_customer_join.md`
7. `06_chaincode_and_functional_validation.md`
8. `07_explorer_and_observability.md`
9. `08_cutover_runbook_and_risk_controls.md`

## Suggested Execution Pattern
- Treat each document as a gate.
- Do not continue to next phase until exit criteria of current phase are met.
- Keep rollback notes active during every phase.

## Important Implementation Note
This Phase 2 migration plan **must be executed strictly within the `/multi-host/` subdirectory** of the `Car-Supply-Chain` repository. This preserves the isolated Phase 1 implementation in `/single-host/` for fallback and comparative testing.

## Important
This plan intentionally keeps backward compatibility with your existing Phase 1 smart contract source code in `/chaincode-go/` while introducing distributed overlays and environment controls.
