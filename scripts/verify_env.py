#!/usr/bin/env python3
"""
LCSB Parity Verification Script

This script checks the local environment against the expected configuration
for the Lynker Coastal Sandbox (LCSB). It verifies Python version and
key package versions to ensure parity with the cloud environment.
"""

import sys
import platform
import importlib.metadata

def check_version(package_name, min_version=None):
    try:
        version = importlib.metadata.version(package_name)
        print(f"[OK] {package_name} is installed: {version}")
        
        if min_version:
            # Very basic version check - can be improved with packaging.version if needed
            # For now, just printing is helpful enough for a quick check
            pass
            
    except importlib.metadata.PackageNotFoundError:
        print(f"[WARNING] {package_name} is NOT installed.")

def main():
    print("=== LCSB Parity Environment Check ===\n")
    
    # 1. Check Python Version
    py_ver = sys.version_info
    print(f"Python Integrity Check: {platform.python_version()}")
    if py_ver.major < 3 or (py_ver.major == 3 and py_ver.minor < 8):
        print("[WARNING] Python version is older than 3.8. Cloud env typically runs 3.8+.")
    else:
        print("[OK] Python version seems adequate.")

    print("\nPackage Checks:")
    # 2. Check Key Packages
    packages_to_check = [
        "prefect",
        "boto3",
        "dask",
        "distributed",
        "netCDF4",
        "numpy",
        "matplotlib"
    ]

    for pkg in packages_to_check:
        check_version(pkg)

    print("\n=== Check Complete ===")
    print("If 'prefect' is < 3.0.0, you may be running an outdated version.")
    print("Please refer to LOCAL_ANACONDA_PYTHON_INSTALLATION_CLOUD_SANDBOX_INSTRUCTIONS.md for update instructions.")

if __name__ == "__main__":
    main()
