This PowerShell script is designed to run as a Microsoft Intune remediation detection script to verify
    compliance with Secure Boot requirements and UEFI CA 2023 certificate installation status.
    
    The script performs a two-tier validation:
    1. Verifies that Secure Boot is enabled on the device
    2. Checks the presence and status of the Windows UEFI CA 2023 certificate
    
    BACKGROUND:
    The UEFI CA 2011 certificate expires June 2026, requiring devices to update
    to the new UEFI CA 2023 certificate to maintain Secure Boot functionality.

    This script helps organizations monitor compliance across their device fleet.
