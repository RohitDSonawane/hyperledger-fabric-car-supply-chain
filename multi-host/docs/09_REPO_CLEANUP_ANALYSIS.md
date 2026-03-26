# 09 - Repo Cleanup Analysis

## Why
The root of the repository has become crowded during iterative setup and debugging.
A cleanup pass improves onboarding, maintenance, and review quality.

## Objective
Produce a practical cleanup plan without breaking network scripts or expected paths.

## Root Inventory Snapshot (Current)
- `.gitignore`
- `README.md`
- `monitordocker.sh`
- `network.config`
- `network.sh`
- `setOrgEnv.sh`
- runtime and source folders (`addCustomer/`, `bin/`, `chaincode-go/`, `compose/`, `config/`, `configtx/`, `docs/`, `explorer/`, `organizations/`, etc.)

## Classification (Keep / Move / Archive)
### Keep In Root (core runtime)
- `README.md`
- `network.sh`
- `network.config`
- `setOrgEnv.sh`
- `monitordocker.sh` (or move later to `scripts/` with compatibility check)
- core runtime folders (`addCustomer/`, `bin/`, `chaincode-go/`, `compose/`, `config/`, `configtx/`, `explorer/`, `organizations/`, `scripts/`)

### Move To docs/
- `CHAINCODE_AS_A_SERVICE_TUTORIAL.md` -> `docs/CHAINCODE_AS_A_SERVICE_TUTORIAL.md` (update references)

### Move Outside Project (workspace-level notes)
- `docs/TODO_WORKSPACE.md` -> `/home/raj/HyperledgerFabric/workspace-notes/TODO_WORKSPACE.md`
- `docs/NEXT_STEPS_TODO.md` -> `/home/raj/HyperledgerFabric/workspace-notes/NEXT_STEPS_TODO.md`

### Archive / Remove / Ignore
- `log.txt` (treat as runtime log; do not keep in root)
- `carcc.tar.gz` (generated chaincode package; regenerate when needed)

## Immediate Low-Risk Cleanup Actions
1. Move `CHAINCODE_AS_A_SERVICE_TUTORIAL.md` into `docs/` and update README link. [x]
2. Move workspace TODO markdown files outside project to workspace-notes. [x]
3. Add ignore entries for runtime/generated artifacts: [x]
- `*.log`
- `*.tar.gz` (or at least `carcc.tar.gz`)
4. Remove temporary `artifacts/` folder after relocation decisions. [x]

## Medium-Risk Actions (Do After Reference Audit)
1. Consider moving `monitordocker.sh` into `scripts/` if no external docs depend on root path.
2. Consider grouping generated outputs under `artifacts/` and ignoring that folder.

## Proposed Migration Sequence
1. Move docs-only files first.
2. Update all internal references.
3. Validate command snippets in docs.
4. Add/update `.gitignore` rules.
5. Commit cleanup in a separate commit from functional changes.

## Validation After Cleanup
- `rg -n "CHAINCODE_AS_A_SERVICE_TUTORIAL.md" .` points to docs path only.
- `docs/README.md` links resolve.
- Root listing is mostly runtime essentials.

## Analysis Checklist
1. Inventory root-level files and folders. [x]
2. Mark each item as one of: [x]
- Core runtime asset (keep in root)
- Documentation/process artifact (move to `docs/`)
- Generated/debug artifact (ignore/archive/remove)

3. Validate path coupling: [x]
- Check scripts that reference moved files.
- Confirm docs links remain valid after move.

4. Propose final structure: [x]
- `docs/` for manuals, guides, and checklists
- `scripts/` for operational helpers
- `artifacts/` or ignored paths for generated output

5. Define migration sequence: [x]
- Move lowest-risk docs first
- Update references
- Validate commands
- Commit in small batches

## Suggested Candidates For Immediate Execution
- Phase 1 cleanup complete:
	- moved `CHAINCODE_AS_A_SERVICE_TUTORIAL.md` to `docs/`
	- moved workspace TODO files outside project to `workspace-notes/`
	- removed root `log.txt`, `carcc.tar.gz`, and deleted temporary `artifacts/` folder

## Completion Criteria
- Root directory contains mostly source/runtime essentials.
- Documentation is centralized in `docs/`.
- No broken script paths or stale references.
