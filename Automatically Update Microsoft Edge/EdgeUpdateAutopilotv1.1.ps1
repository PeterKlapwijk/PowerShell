# --------------------------------------------------------------------------------------#
# Author(s)    : Peter Klapwijk - www.InTheCloud247.com                                 #
#                Mathieu Ait Azzouzene - @MatAitAzzouzene                               #
# Version      : 1.1                                                                    #
#                                                                                       #
# Description  : Updates Microsoft Edge during AP enrollment as Windows is              #
#                delivered with an outdated Edge version                                #
#                                                                                       #
#                                                                                       #
# Changes      : v1.0 - Initial published version                                       #
#                v1.1 - Logic added to check on the latest version available online     #
#                                                                                       #
# This script is provide "As-Is" without any warranties                                 #
#                                                                                       #
# --------------------------------------------------------------------------------------#

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
$StoreResults = "InTheCloud247\EdgeUpdateAutopilot\v1.1"

# Start Transcript
Start-Transcript -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$($(Split-Path $PSCommandPath -Leaf).ToLower().Replace(".ps1",".log"))" | Out-Null

#Determine original Microsoft Edge Version
$OldEdgeVersion = (Get-AppxPackage -AllUsers -Name "Microsoft.MicrosoftEdge.Stable").Version
Write-Host "Current Microsoft Edge version $OldEdgeVersion"

#Trigger Microsoft Edge update
Start-Process -FilePath "C:\Program Files (x86)\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe" -argumentlist "/silent /install appguid={56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}&appname=Microsoft%20Edge&needsadmin=True"
Write-Host "Sleeping for 120 seconds"
Start-Sleep -Seconds 120

#Get the latest Edge stable version available
$Product = 'Stable'
$Platform = 'Windows'
$architecture = 'x64'
$EdgeInfo = (Invoke-WebRequest -uri 'https://edgeupdates.microsoft.com/api/products?view=enterprise' -UseBasicParsing)
$LatestEdgeVersion = ((($EdgeInfo.content | Convertfrom-json) | ? {$_.product -eq $Product}).releases | ? {$_.Platform -eq $Platform -and $_.architecture -eq $architecture})[0].productversion

Write-Host "Latest Edge stable version is $LatestEdgeVersion"

# Do Until Loop to check updated Edge version
Do {
    $NewEdgeVersion = (Get-AppxPackage -AllUsers -Name "Microsoft.MicrosoftEdge.Stable").Version
    Write-Host "Checking current installed Edge version"
    Start-Sleep -Seconds 15
} Until ($NewEdgeVersion -eq $LatestEdgeVersion)
Write-Host "Edge version updated to $NewEdgeVersion"

CleanUpAndExit -ErrorLevel 0

Stop-Transcript | Out-Null