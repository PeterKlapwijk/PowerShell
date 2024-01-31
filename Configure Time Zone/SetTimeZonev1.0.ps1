# ---------------------------------------------------------------------------- #
# Author(s)    : Peter Klapwijk - www.inthecloud247.com                        #
#                Original script from Koen Van den Broeck                      #
# Version      : 1.0                                                           #
#                                                                              #
# Description  : Automatically configure the time zone                         #
#                                                                              #
# Notes:                                                                       #
# https://ipinfo.io/ has a limit of 50k requests per month without a license   #
#                                                                              #
# The solution makes use of Bing Maps Dev Center. An API key needs to be       #
# created on https://www.bingmapsportal.com. Check the license agreement if a  #
# basic key (free) key is suitable for your needs.                             #
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
$StoreResults = "COMPANY\TimeZone\v1.0"
$BingKey = "xxxxx"

# Start Transcript
Start-Transcript -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$($(Split-Path $PSCommandPath -Leaf).ToLower().Replace(".ps1",".log"))" | Out-Null

# Automatically configure the time zone
$Error.Clear()
$IPInfo = Invoke-RestMethod http://ipinfo.io/json
$Location = $IPInfo.loc
Write-Output "Country : "$IPInfo.country
Write-Output "Public IP Address : "$IPInfo.ip
Write-Output "Location : "$IPInfo.loc
$BingTimeZoneURL = "http://dev.virtualearth.net/REST/v1/TimeZone/$Location" + "?key=$BingKey"
$ResultTZ = Invoke-RestMethod $BingTimeZoneURL
$WindowsTZ = $ResultTZ.resourceSets.resources.timeZone.windowsTimeZoneId
If (![string]::IsNullOrEmpty($WindowsTZ))
{
Get-TimeZone -Id $WindowsTZ
Set-TimeZone -Id $WindowsTZ
}

If ($Error.Count -gt 0) {
    Write-Output "Failed to set the time zone: $($Error[0])"
    CleanUpAndExit -ErrorLevel 101
} else {
    Write-Output "Successfully set the time zone"
}

CleanUpAndExit -ErrorLevel 0

Stop-Transcript
