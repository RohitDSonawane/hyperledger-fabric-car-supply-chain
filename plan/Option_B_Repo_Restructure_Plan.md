# Option B Repository Restructuring Plan: Single-Host & Multi-Host Coexistence

## Objective
To drastically restructure the `Car-Supply-Chain` GitHub repository so that it natively supports both a `single-host` local development environment and a `multi-host` (5-PC distributed) environment without needing complex bash toggles or Git branch switching. Both environments will share a single, unified `chaincode-go` source directory to guarantee that core business logic is never duplicated.

## 1. Target Directory Architecture
The root folder will be transformed from a flat network footprint into a categorized dual-topology layout:

```text
Car-Supply-Chain/
├── .git/                 (Untouched)
├── .gitignore            (Untouched)
├── README.md             (Update to explain the two folders)
├── chaincode-go/         (Untouched: Central Smart Contract Source)
├── single-host/          (NEW: Contains original Phase 1 implementation)
│   ├── network.sh
│   ├── compose/
│   ├── configtx/
│   ├── organizations/
│   └── ...all other network infrastructure files
└── multi-host/           (NEW: Contains Phase 2 5-PC implementation)
    ├── network.sh
    ├── compose/
    ├── configtx/
    ├── organizations/
    └── ...all other network files tailored for distributed ZeroTier routing
```

## 2. Step-by-Step Migration Execution

### Step 2.1: Create Subdirectories & Relocate Network Files
Create the `single-host` folder and move all infrastructure, UI, and runtime files into it, **leaving only** the chaincode, git metadata, and markdown docs in the root.

**Items to Move into `single-host/`:**
- `addCustomer/`
- `bin/`
- `bft-config/`
- `channel-artifacts/`
- `compose/`
- `config/`
- `configtx/`
- `docs/`
- `explorer/`
- `prometheus-grafana/`
- `organizations/`
- `scripts/`
- `system-genesis-block/`
- All root `.sh` scripts (`network.sh`, `setOrgEnv.sh`, `monitordocker.sh`)
- `network.config`

**Items to Keep in `Car-Supply-Chain/` (Root):**
- `chaincode-go/`
- `.git/` folder and `.gitignore` file
- `README.md`

### Step 2.2: Fix Chaincode Paths in `single-host/network.sh`
Because `network.sh` and the deployment scripts (like `deployCC.sh` inside the `scripts` folder) have been moved one directory deeper into the tree, they will fail to locate the chaincode if their paths are hardcoded to `./chaincode-go`.
- **Critical Action:** Open `single-host/network.sh` and update the default chaincode path parameter (`-ccp`) to point to `../chaincode-go` instead of `./chaincode-go`. Ensure any `go mod vendor` commands in the deployment scripts also resolve to the `../chaincode-go` directory.

### Step 2.3: Duplicate for Multi-Host
Once `single-host` is tested by running `./network.sh up` to ensure the new directory depth didn't break volume mounts, completely clone the environment:
- **Action:** Run `cp -r single-host multi-host` in the terminal.

### Step 2.4: Execute Phase 2 Distributed Edits on `multi-host`
Now that `multi-host` is safely decoupled from the pristine single-PC setup, apply all of the Phase 2 edits directly to the `multi-host` folder without fear of breaking the fallback setup:
- Refactor `multi-host/compose/*.yaml` to inject the mandatory `extra_hosts` arrays for ZeroTier IPs.
- Edit `multi-host/setOrgEnv.sh` to remove `localhost` and rely strictly on canonical ZeroTier hostnames.
- Modify the `multi-host/network.sh` logic to correctly target remote peers across the distributed network.

## 3. Risks & Critical Considerations
1. **Docker Volume Pathing:** If any `docker-compose.yaml` files in your `compose/` directory previously used deep absolute bind mounts based on absolute paths, they must be checked. Standard relative paths (e.g., `- ../organizations/ordererOrganizations:/var/hyperledger/orderer/msp`) will continue to work perfectly because both the compose file and the target folder shifted down exactly one level together.
2. **Double Maintenance Penalty:** While the central `chaincode-go` business logic is perfectly preserved and shared, your network definitions are now forever split. If you decide to add a new Fabric Organization (e.g., "Insurer") next month, you literally must edit `single-host/configtx/configtx.yaml` AND `multi-host/configtx/configtx.yaml` individually.

## 4. Acceptance Criteria
1. Running `./network.sh up createChannel -c supplychain` inside the `single-host` directory successfully bootstraps the local demo network exactly as it did in Phase 1.
2. Running the exact same command inside `multi-host` successfully initiates the ZeroTier distributed setup across the 5 PCs.
3. Modifying a `.go` smart contract file in the root `chaincode-go/` folder automatically impacts both networks immediately the next time `deployCC` is run in either folder.
