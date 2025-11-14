<#
.SYNOPSIS
    Microsoft Intune Detection Script for Secure Boot and UEFI CA 2023 Certificate Status

.DESCRIPTION
    This PowerShell script is designed to run as a Microsoft Intune detection script to verify
    compliance with Secure Boot requirements and UEFI CA 2023 certificate installation status.
    
    The script performs a two-tier validation:
    1. Verifies that Secure Boot is enabled on the device
    2. Checks the presence and status of the Windows UEFI CA 2023 certificate
    
    BACKGROUND:
    The UEFI CA 2011 certificate expires June 2026, requiring devices to update
    to the new UEFI CA 2023 certificate to maintain Secure Boot functionality.
    This script helps organizations monitor compliance across their device fleet.

.FUNCTIONALITY
    Registry Keys Checked:
    - HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State\UEFISecureBootEnabled
    - HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing\WindowsUEFICA2023Capable
    - HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing\UEFICA2023Status
    - HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing\UEFICA2023Error

.RETURN VALUES
    Exit 0 (Compliant):
    - Secure Boot is enabled AND
    - WindowsUEFICA2023Capable = 1 (certificate in DB) OR
    - WindowsUEFICA2023Capable = 2 (certificate in DB + using 2023 boot manager)
    
    Exit 1 (Non-compliant):
    - Secure Boot is disabled OR
    - WindowsUEFICA2023Capable = 0 (certificate not in DB) OR
    - Registry keys missing OR
    - Any errors encountered during execution

.LOGGING
    Creates detailed logs at: $env:ProgramData\Microsoft\IntuneManagementExtension\Logs\SecureBootUEFICA2023_Detection.log
    Log levels: INFO, SUCCESS, ERROR

.REFERENCES
    - Secure Boot certificate updates guidance: https://support.microsoft.com/en-gb/topic/secure-boot-certificate-updates-guidance-for-it-professionals-and-organizations-e2b43f9f-b424-42df-bc6a-8476db65ab2f
    - Registry key updates documentation: https://support.microsoft.com/en-gb/topic/registry-key-updates-for-secure-boot-windows-devices-with-it-managed-updates-a7be69c9-4634-42e1-9ca1-df06f43f360d

.NOTES
    Author: Peter Klapwijk (www.InTheCloud247.com)
    Created: November 2025
    Version: 1.0
    This script is provide "As-Is" without any warranties 
#>

# Setup logging
$logPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\SecureBootUEFICA2023_Detection.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Output $Message
    try {
        Add-Content -Path $logPath -Value $logEntry -Force
    }
    catch {
        # If logging fails, continue without blocking the script
    }
}

try {
    # Log device attributes for diagnostic purposes
    $deviceAttributesPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing\DeviceAttributes"
    Write-Log "=== Device Attributes Information ===" "INFO"
    
    $deviceAttributes = Get-ItemProperty -Path $deviceAttributesPath -ErrorAction SilentlyContinue
    
    if ($null -eq $deviceAttributes) {
        Write-Log "DeviceAttributes registry key not found" "INFO"
    } else {
        # Log OEM Name
        $oemName = if ($null -ne $deviceAttributes.OEMName) { $deviceAttributes.OEMName } else { "Not available" }
        Write-Log "OEMName: $oemName" "INFO"
        
        # Log OEM Model Number
        $oemModelNumber = if ($null -ne $deviceAttributes.OEMModelNumber) { $deviceAttributes.OEMModelNumber } else { "Not available" }
        Write-Log "OEMModelNumber: $oemModelNumber" "INFO"
        
        # Log Base Board Manufacturer
        $baseBoardManufacturer = if ($null -ne $deviceAttributes.BaseBoardManufacturer) { $deviceAttributes.BaseBoardManufacturer } else { "Not available" }
        Write-Log "BaseBoardManufacturer: $baseBoardManufacturer" "INFO"
        
        # Log Firmware Manufacturer
        $firmwareManufacturer = if ($null -ne $deviceAttributes.FirmwareManufacturer) { $deviceAttributes.FirmwareManufacturer } else { "Not available" }
        Write-Log "FirmwareManufacturer: $firmwareManufacturer" "INFO"
        
        # Log Firmware Version
        $firmwareVersion = if ($null -ne $deviceAttributes.FirmwareVersion) { $deviceAttributes.FirmwareVersion } else { "Not available" }
        Write-Log "FirmwareVersion: $firmwareVersion" "INFO"
        
        # Log Firmware Release Date
        $firmwareReleaseDate = if ($null -ne $deviceAttributes.FirmwareReleaseDate) { $deviceAttributes.FirmwareReleaseDate } else { "Not available" }
        Write-Log "FirmwareReleaseDate: $firmwareReleaseDate" "INFO"
    }
    Write-Log "=== End Device Attributes Information ===" "INFO"

    # Registry path for SecureBoot State
    $secureBootStatePath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State"
    
    # Check if Secure Boot is enabled
    $secureBootValue = Get-ItemProperty -Path $secureBootStatePath -Name "UEFISecureBootEnabled" -ErrorAction SilentlyContinue
    
    if ($null -eq $secureBootValue -or $null -eq $secureBootValue.UEFISecureBootEnabled) {
        Write-Log "Registry key UEFISecureBootEnabled not found" "ERROR"
        exit 1
    }
    
    # Check if Secure Boot is enabled: 1 = enabled, 0 = disabled
    if ($secureBootValue.UEFISecureBootEnabled -eq 1) {
        Write-Log "Secure Boot is enabled - Checking UEFI CA 2023 certificate status"
        
        # Registry path for SecureBoot Servicing
        $servicingPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing"
        
        # Check UEFI CA 2023 capability
        $ca2023Value = Get-ItemProperty -Path $servicingPath -Name "WindowsUEFICA2023Capable" -ErrorAction SilentlyContinue
        
        if ($null -eq $ca2023Value -or $null -eq $ca2023Value.WindowsUEFICA2023Capable) {
            Write-Log "WindowsUEFICA2023Capable registry key not found - Windows UEFI CA 2023 certificate is not in the DB" "ERROR"
            exit 1
        }
        
        # Check the UEFI CA 2023 certificate status
        switch ($ca2023Value.WindowsUEFICA2023Capable) {
            0 {
                # When value is 0, also check the UEFICA2023Status
                $statusValue = Get-ItemProperty -Path $servicingPath -Name "UEFICA2023Status" -ErrorAction SilentlyContinue
                
                if ($null -eq $statusValue -or $null -eq $statusValue.UEFICA2023Status) {
                    Write-Log "WindowsUEFICA2023Capable = 0 - Windows UEFI CA 2023 certificate is not in the DB. UEFICA2023Status: Not found" "ERROR"
                } else {
                    $status = $statusValue.UEFICA2023Status
                    switch ($status) {
                        "NotStarted" {
                            # Check for error code when status is NotStarted
                            $errorValue = Get-ItemProperty -Path $servicingPath -Name "UEFICA2023Error" -ErrorAction SilentlyContinue
                            if ($null -eq $errorValue -or $null -eq $errorValue.UEFICA2023Error) {
                                Write-Log "WindowsUEFICA2023Capable = 0 - Windows UEFI CA 2023 certificate is not in the DB. UEFICA2023Status: NotStarted (The update has not yet run). UEFICA2023Error: Not found" "ERROR"
                            } else {
                                $errorCode = $errorValue.UEFICA2023Error
                                if ($errorCode -eq 0) {
                                    Write-Log "WindowsUEFICA2023Capable = 0 - Windows UEFI CA 2023 certificate is not in the DB. UEFICA2023Status: NotStarted (The update has not yet run). UEFICA2023Error: 0 (No error)" "ERROR"
                                } else {
                                    Write-Log "WindowsUEFICA2023Capable = 0 - Windows UEFI CA 2023 certificate is not in the DB. UEFICA2023Status: NotStarted (The update has not yet run). UEFICA2023Error: $errorCode (Error encountered)" "ERROR"
                                }
                            }
                        }
                        "InProgress" {
                            # Check for error code when status is InProgress
                            $errorValue = Get-ItemProperty -Path $servicingPath -Name "UEFICA2023Error" -ErrorAction SilentlyContinue
                            if ($null -eq $errorValue -or $null -eq $errorValue.UEFICA2023Error) {
                                Write-Log "WindowsUEFICA2023Capable = 0 - Windows UEFI CA 2023 certificate is not in the DB. UEFICA2023Status: InProgress (The update is actively in progress). UEFICA2023Error: Not found" "ERROR"
                            } else {
                                $errorCode = $errorValue.UEFICA2023Error
                                if ($errorCode -eq 0) {
                                    Write-Log "WindowsUEFICA2023Capable = 0 - Windows UEFI CA 2023 certificate is not in the DB. UEFICA2023Status: InProgress (The update is actively in progress). UEFICA2023Error: 0 (No error)" "ERROR"
                                } else {
                                    Write-Log "WindowsUEFICA2023Capable = 0 - Windows UEFI CA 2023 certificate is not in the DB. UEFICA2023Status: InProgress (The update is actively in progress). UEFICA2023Error: $errorCode (Error encountered)" "ERROR"
                                }
                            }
                        }
                        "Updated" {
                            Write-Log "WindowsUEFICA2023Capable = 0 - Windows UEFI CA 2023 certificate is not in the DB. UEFICA2023Status: Updated (The update has completed successfully)" "ERROR"
                        }
                        default {
                            Write-Log "WindowsUEFICA2023Capable = 0 - Windows UEFI CA 2023 certificate is not in the DB. UEFICA2023Status: $status (Unknown status)" "ERROR"
                        }
                    }
                }
                exit 1
            }
            1 {
                Write-Log "WindowsUEFICA2023Capable = 1 - Windows UEFI CA 2023 certificate is in the DB - Device is compliant" "SUCCESS"
                exit 0
            }
            2 {
                Write-Log "WindowsUEFICA2023Capable = 2 - Windows UEFI CA 2023 certificate is in the DB and system is starting from 2023 signed boot manager - Device is compliant" "SUCCESS"
                exit 0
            }
            default {
                Write-Log "Unexpected value for WindowsUEFICA2023Capable: $($ca2023Value.WindowsUEFICA2023Capable)" "ERROR"
                exit 1
            }
        }
    }
    else {
        Write-Log "Secure Boot is disabled (value: $($secureBootValue.UEFISecureBootEnabled)) - Device is not compliant" "ERROR"
        exit 1
    }
}
catch {
    Write-Log "Error occurred while checking Secure Boot and UEFI CA 2023 status: $($_.Exception.Message)" "ERROR"
    exit 1
}
