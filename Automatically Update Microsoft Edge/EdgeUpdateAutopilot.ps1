# ---------------------------------------------------------------------------- #
# Author(s)    : Peter Klapwijk - www.InTheCloud247.com                        #
# Version      : 1.0                                                           #
#                                                                              #
# Description  : Updates Microsoft Edge during AP enrollment as Windows is     #
#                delivered with an outdated Edge version                       #
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

#Results stored in the registry for Intune detection. Change to your needs.
$StoreResults = "InTheCloud247\EdgeUpdateAutopilot\v1.0"

# Start Transcript
Start-Transcript -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$($(Split-Path $PSCommandPath -Leaf).ToLower().Replace(".ps1",".log"))" | Out-Null

#Determine original Microsoft Edge Version
$EdgeVersionOld = (Get-AppxPackage -AllUsers -Name "Microsoft.MicrosoftEdge.Stable").Version
Write-Host "Current Microsoft Edge version $EdgeVersionOld"

#Trigger Microsoft Edge update
Start-Process -FilePath "C:\Program Files (x86)\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe" -argumentlist "/silent /install appguid={56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}&appname=Microsoft%20Edge&needsadmin=True"
Write-Host "Sleeping for 120 seconds"
Start-Sleep -Seconds 120

# Do Until Loop to check updated Edge Version
Do {
    $EdgeVersionNew = (Get-AppxPackage -AllUsers -Name "Microsoft.MicrosoftEdge.Stable").Version
    Write-Host "Checking current Edge version"
    Start-Sleep -Seconds 15
} Until ($EdgeVersionNew -gt 120.0.0.0)
Write-Host "Edge version updated to $EdgeVersionNew"


CleanUpAndExit -ErrorLevel 0

Stop-Transcript
