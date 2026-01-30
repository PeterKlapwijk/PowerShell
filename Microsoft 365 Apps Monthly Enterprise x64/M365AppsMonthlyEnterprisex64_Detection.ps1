<#
.SYNOPSIS
    Intune Detection Script for Microsoft 365 Apps (x64)

.DESCRIPTION
    This script detects if Microsoft 365 Apps (64-bit) is installed on the system.
    Designed for use with Microsoft Intune Win32 App deployment.
    
    Returns:
    - Outputs "Detected" and exits 0 if Microsoft 365 Apps x64 is installed
    - Exits 1 if not installed or if 32-bit version is found

.NOTES
    File Name      : M365AppsMonthlyEnterprisex64_Detection.ps1
    Author         : Peter Klapwijk (InTheCloud247.com)
    Intune Usage   : Configure as Custom Detection Rule (Script)
#>

try {
    # Check for Office Click-to-Run installation
    $OfficeC2RPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
    
    $OfficeInstalled = $false
    $Is64Bit = $false
    
    # Check primary registry path (native)
    if (Test-Path $OfficeC2RPath) {
        $Platform = (Get-ItemProperty -Path $OfficeC2RPath -Name "Platform" -ErrorAction SilentlyContinue).Platform
        $VersionToReport = (Get-ItemProperty -Path $OfficeC2RPath -Name "VersionToReport" -ErrorAction SilentlyContinue).VersionToReport
        $ProductReleaseIds = (Get-ItemProperty -Path $OfficeC2RPath -Name "ProductReleaseIds" -ErrorAction SilentlyContinue).ProductReleaseIds
        
        # For 64-bit Office, Platform should be "x64"
        if ($Platform -eq "x64" -and $VersionToReport) {
            $OfficeInstalled = $true
            $Is64Bit = $true
        }
    }
    
    # If Office x64 is detected via registry, return success
    if ($OfficeInstalled -and $Is64Bit) {
        Write-Output "Detected"
        exit 0
    }
    
    # Not detected
    exit 1
}
catch {
    # Error occurred, treat as not detected
    exit 1
}
