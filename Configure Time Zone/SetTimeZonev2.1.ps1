# ---------------------------------------------------------------------------- #
# Author(s)    : Peter Klapwijk - www.inthecloud247.com                        #
#              : Johannes Muller - Co-author @ www.2azure.nl                   #
#                Original script from Koen Van den Broeck                      #
# Version      : 2.1                                                           #
#                                                                              #
# Description  : Automatically configure the time zone using Azure Maps        #
#                Uses `timezone/enumWindows` API to dynamically map time zones #
#                                                                              #
# Notes:                                                                       #
# https://ipinfo.io/ has a limit of 50k requests per month without a license   #
#                                                                              #
# This script is provide "As-Is" without any warranties                        #
#                                                                              #
# ---------------------------------------------------------------------------- #

# Microsoft Intune Management Extension might start a 32-bit PowerShell instance. If so, restart as 64-bit PowerShell
If ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    Try {
        &"$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -File $PSCOMMANDPATH
    }
    Catch {
        Throw "Failed to start $PSCOMMANDPATH"
    }
    Exit
}

#region Functions
Function CleanUpAndExit() {
    Param(
        [Parameter(Mandatory=$True)][String]$ErrorLevel
    )

    # Write results to registry for Intune Detection
    $Key = "HKEY_LOCAL_MACHINE\Software\$StoreResults"
    $NOW = Get-Date -Format "yyyyMMdd-hhmmss"

    If ($ErrorLevel -eq "0") {
        [microsoft.win32.registry]::SetValue($Key, "Success", $NOW)
    } else {
        [microsoft.win32.registry]::SetValue($Key, "Failure", $NOW)
        [microsoft.win32.registry]::SetValue($Key, "Error Code", $Errorlevel)
    }
    
    # Exit Script with the specified ErrorLevel
    EXIT $ErrorLevel
}
#endregion Functions

# ------------------------------------------------------------------------------------------------------- #
# Variables, change to your needs
# ------------------------------------------------------------------------------------------------------- #
$StoreResults = "COMPANY\TimeZone\v2.1"
$AzureMapsKey = "xxxxx" 

# Start Transcript
Start-Transcript -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$($(Split-Path $PSCommandPath -Leaf).ToLower().Replace(".ps1",".log"))" | Out-Null

# Automatically configure the time zone
$Error.Clear()

# Retrieve IP information
$IPInfo = Invoke-RestMethod http://ipinfo.io/json
$CountryCode = $IPInfo.country

Write-Output "Country Code: $CountryCode"

# Retrieve all Windows Time Zones from Azure Maps
$AzureMapsURL = "https://atlas.microsoft.com/timezone/enumWindows/json?api-version=1.0&subscription-key=$AzureMapsKey"
$ResultTZ = Invoke-RestMethod -Uri $AzureMapsURL -Method Get
# Retrieve Time Zone WindowsId
$WindowsTZ = ($ResultTZ | Where-Object Territory -eq $CountryCode).WindowsId


If (![string]::IsNullOrEmpty($WindowsTZ)) {
    Write-Output "Mapped Country code ($CountryCode) to Windows Time Zone: $WindowsTZ"
} else {
    Write-Output "No matching Windows Time Zone found for country: $CountryCode"
    CleanUpAndExit -ErrorLevel 103
}

# Set the Windows time zone
Set-TimeZone -Id $WindowsTZ
Write-Output "Successfully set Windows Time Zone: $WindowsTZ"

CleanUpAndExit -ErrorLevel 0

Stop-Transcript
