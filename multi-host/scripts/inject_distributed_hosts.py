#!/usr/bin/env python3
import os
import sys

# ##########################################################
# # DISTRIBUTED HOST INJECTOR (Car Supply Chain Phase 2)  #
# ##########################################################
# This script reads your .env file and automatically injects 
# the ZeroTier Managed IPs as "extra_hosts" into every service 
# across your Docker Compose files. 
# ##########################################################

def parse_env(env_path):
    """Parses a .env file and returns a dictionary of hostmappings."""
    mappings = {}
    if not os.path.exists(env_path):
        print(f"Error: {env_path} not found! Please copy .env.example to .env first.")
        sys.exit(1)
    
    with open(env_path, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            if '=' in line:
                key, val = line.split('=', 1)
                # We care about PC IPs for extra_hosts
                if key.endswith('_IP'):
                    mappings[key] = val
    
    # Static mappings derived from HLF naming
    final_hosts = [
        f"orderer.example.com:{mappings.get('PC1_IP', '127.0.0.1')}",
        f"peer0.manufacturer.example.com:{mappings.get('PC2_IP', '127.0.0.1')}",
        f"peer0.showroom.example.com:{mappings.get('PC3_IP', '127.0.0.1')}",
        f"peer0.customer.example.com:{mappings.get('PC4_IP', '127.0.0.1')}",
        f"explorer.example.com:{mappings.get('PC5_IP', '127.0.0.1')}"
    ]
    return final_hosts

def inject_extra_hosts(file_path, hosts_list):
    """Injects or replaces extra_hosts into each service in a yaml file."""
    if not os.path.isfile(file_path):
        return

    with open(file_path, 'r') as f:
        lines = f.readlines()

    new_content = []
    in_services = False
    in_service_block = False
    
    # Simple YAML injection logic (safe for HLF compose templates)
    for line in lines:
        stripped = line.strip()
        
        # Detect services block
        if stripped == "services:":
            in_services = True
        
        # New service identification (2-space indent in HLF files)
        if in_services and line.startswith("  ") and not line.startswith("    ") and stripped.endswith(":"):
            in_service_block = True
            new_content.append(line)
            # Inject extra_hosts right under the service name
            new_content.append("    extra_hosts:\n")
            for h in hosts_list:
                new_content.append(f"      - \"{h}\"\n")
            continue
        
        # If we see 'extra_hosts:' already in the file, we skip it (clean overwrite)
        if stripped == "extra_hosts:":
            continue
        if stripped.startswith("- \"orderer.example.com:") or stripped.startswith("- \"peer0."):
            continue
            
        new_content.append(line)

    with open(file_path, 'w') as f:
        f.writelines(new_content)
    print(f"Modified: {os.path.basename(file_path)}")

def main():
    # Paths relative to script location in multi-host/scripts/
    script_dir = os.path.dirname(os.path.realpath(__file__))
    multi_host_root = os.path.dirname(script_dir)
    env_file = os.path.join(multi_host_root, ".env")
    compose_dir = os.path.join(multi_host_root, "compose")

    # 1. Get IP mappings
    print("Parsing .env file...")
    hosts = parse_env(env_file)
    print("Detected Host Logic:")
    for h in hosts:
        print(f"  -> {h}")

    # 2. Iterate and Inject YAMLs
    print(f"\nScanning {compose_dir} for layouts...")
    # Walk through compose directory and its subdirectories (docker/ podman/)
    for root, _, files in os.walk(compose_dir):
        for file in files:
            if file.endswith(".yaml") or file.endswith(".yml"):
                inject_extra_hosts(os.path.join(root, file), hosts)

    # 3. Handle separate addCustomer compose files
    customer_compose = os.path.join(multi_host_root, "addCustomer", "compose")
    if os.path.isdir(customer_compose):
        print(f"\nScanning addCustomer layouts...")
        for root, _, files in os.walk(customer_compose):
            for file in files:
                if file.endswith(".yaml") or file.endswith(".yml"):
                    inject_extra_hosts(os.path.join(root, file), hosts)

    print("\nInjection complete! Distributed 5-PC networking is now mapped across all containers.")

if __name__ == "__main__":
    main()
