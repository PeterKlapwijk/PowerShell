# ---------------------------------------------------------------------------- #
# Author(s)    : Peter Klapwijk - www.InTheCloud247.com                        #
# Contributor  : Mathieu Ait Azzouzene                                         #
# Version      : 1.1                                                           #
#                                                                              #
# Description  : Updates Microsoft Edge during AP enrollment as Windows is     #
#                delivered with an outdated Edge version                       #
#                                                                              #
# This script is provide "As-Is" without any warranties                        #
#                                                                              #
# ---------------------------------------------------------------------------- #

param (
    [Parameter(Mandatory = $False)]
    [ValidateNotNullorEmpty()]
    [ValidateSet('Stable', 'Beta', 'Canary', 'Dev')]
    [String]
    $UpdateChannel = 'Stable',
    [Parameter(Mandatory = $False)]
    [ValidateNotNullorEmpty()]
    [ValidateSet('x86', 'x64', 'arm64')]
    [String]
    $Architecture = 'x64'
)

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

$ExitCode = 0

#Results stored in the registry for Intune detection. Change to your needs.
$StoreResults = "InTheCloud247\EdgeUpdateAutopilot\v1.0"

#Get Edge app GUID depending on the update channel
switch ($UpdateChannel) {
    'Stable' { $AppGUID = '{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}' }
    'Beta' { $AppGUID = '{2CD8A007-E189-409D-A2C8-9AF4EF3C72AA}' }
    'Canary' { $AppGUID = '{65C35B14-6C1D-4122-AC46-7148CC9D6497}' }
    'Dev' { $AppGUID = '{0D50BFEC-CD6A-4F9A-964C-C7416E3ACB10}' }
}

$Platform = 'Windows'

# Start Transcript
Start-Transcript -Append -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$($(Split-Path $PSCommandPath -Leaf).ToLower().Replace(".ps1",".log"))" | Out-Null

#Determine original Microsoft Edge Version
[System.Version]$EdgeVersionOld = (Get-AppxPackage -AllUsers -Name "Microsoft.MicrosoftEdge.$UpdateChannel").Version
if (!($EdgeVersionOld)) {
    Write-Error "Microsoft Edge $UpdateChannel not installed, exiting"
    $ExitCode = 1
}
Else {
    Write-Host "Current Microsoft Edge $UpdateChannel version $EdgeVersionOld"
    #Determine latest Microsoft Edge Version depending on the update channel
    $EdgeInfo = (Invoke-WebRequest -UseBasicParsing -uri 'https://edgeupdates.microsoft.com/api/products?view=enterprise')

    [System.Version]$EdgeVersionLatest = ((($EdgeInfo.content | Convertfrom-json) | Where-Object {$_.product -eq $UpdateChannel}).releases | Where-Object {$_.Platform -eq $Platform -and $_.architecture -eq $architecture})[0].productversion
    Write-Host "Latest $UpdateChannel Microsoft Edge version is $EdgeVersionLatest"

    #"-ge" uses alphabetical order to compare, adding "-ne" + "gt" instead
    If ($EdgeVersionOld -ne $EdgeVersionLatest -and $EdgeVersionOld -gt $EdgeVersionLatest) {
        Write-Host "Microsoft Edge $UpdateChannel already up to date"
    }
    else {
        #Trigger Microsoft Edge update
        Write-Host "Lanching Microsoft Edge $UpdateChannel update"
        Start-Process -FilePath "C:\Program Files (x86)\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe" -argumentlist "/silent /install appguid=$AppGUID&appname=Microsoft%20Edge&needsadmin=True"
        Write-Host "Sleeping for 60 seconds"
        Start-Sleep -Seconds 60

        #Getting new Microsoft Edge installed version
        [System.Version]$EdgeVersionNew = (Get-AppxPackage -AllUsers -Name "Microsoft.MicrosoftEdge.$UpdateChannel").Version

        # Do While Loop to wait until Microsoft Edge Version updated if required
        Do {
            [System.Version]$EdgeVersionNew = (Get-AppxPackage -AllUsers -Name "Microsoft.MicrosoftEdge.$UpdateChannel").Version
            Write-Host "Checking current Edge version"
            Start-Sleep -Seconds 15
        } While ($EdgeVersionNew -lt $EdgeVersionLatest)
        Write-Host "Microsoft Edge $UpdateChannel version updated to $EdgeVersionNew"
    }
}

Stop-Transcript

CleanUpAndExit -ErrorLevel $ExitCode
