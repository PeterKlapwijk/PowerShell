# ------------------------------------------------------------------------------------------------------------ #
# Author(s)    : Peter Klapwijk - www.inthecloud247.com                                                        #
# Version      : 1.0                                                                                           #
#                                                                                                              #
# Description  : This Powershell script will remove AppX packages from the system                              #
#                that are listed in the app array                                                              #
#                                                                                                              #
# Changes      : v1.0 - Initial version                                                                		   # 
#                                                                                                              # 
#                                                                                                              #
#                This script is provide "As-Is" without any warranties                                 		   #
#                                                                                                              #
#------------------------------------------------------------------------------------------------------------- #
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

# ---------------------------------------------------------------------------- #
# Set Generic Script Variables, etc.
# ---------------------------------------------------------------------------- #
$StoreResults = "Klapwijk\AppXRemove\v1.0"

# Start Transcript
Start-Transcript -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$($(Split-Path $PSCommandPath -Leaf).ToLower().Replace(".ps1",".log"))" | Out-Null

# Define Array
$AppsToRemove = @()

# Build array with Appx Packages to remove
$AppsToRemove += "*Microsoft.BingWeather*"
$AppsToRemove += "*Microsoft.GamingApp*"
$AppsToRemove += "*Microsoft.GetHelp*"
$AppsToRemove += "*Microsoft.Messaging*"
$AppsToRemove += "*Microsoft.Microsoft3DBuilder*"
$AppsToRemove += "*Microsoft.Microsoft3DViewer*"
$AppsToRemove += "*Microsoft.MicrosoftOfficeHub*"
$AppsToRemove += "*Microsoft.MicrosoftSolitaireCollection*"
$AppsToRemove += "*Microsoft.MixedReality.Portal*"
$AppsToRemove += "*Microsoft.Office.OneNote*"
$AppsToRemove += "*Microsoft.OneConnect*"
$AppsToRemove += "*Microsoft.People*"
$AppsToRemove += "*Microsoft.Print3D*"
$AppsToRemove += "*Microsoft.SkypeApp*"
$AppsToRemove += "*Microsoft.Wallet*"
$AppsToRemove += "*Microsoft.WindowsAlarms*"
$AppsToRemove += "*microsoft.windowscommunicationsapps*"
$AppsToRemove += "*Microsoft.WindowsFeedbackHub*"
$AppsToRemove += "*Microsoft.WindowsMaps*"
$AppsToRemove += "*Microsoft.Xbox.TCUI*"
$AppsToRemove += "*Microsoft.XboxApp*"
$AppsToRemove += "*Microsoft.XboxGameOverlay*"
$AppsToRemove += "*Microsoft.XboxIdentityProvider*"
$AppsToRemove += "*Microsoft.XboxSpeechToTextOverlay*"
$AppsToRemove += "*Microsoft.YourPhone*"
$AppsToRemove += "*Microsoft.ZuneMusic*"
$AppsToRemove += "*Microsoft.ZuneVideo*"
$AppsToRemove += "*MicrosoftTeams*"

# Determine OS Drive when running in WinPE
if ($env:SYSTEMDRIVE -eq "X:") {
  $Offline = $true
  $drives = get-volume | Where-Object {-not [String]::IsNullOrWhiteSpace($_.DriveLetter) } | Where-Object {$_.DriveType -eq 'Fixed'} | Where-Object {$_.DriveLetter -ne 'X'}
  $drives | Where-Object { Test-Path "$($_.DriveLetter):\Windows\System32"} | ForEach-Object { $OfflinePath = "$($_.DriveLetter):\" }
} else {
  $Offline = $false
}

# Remove the AppX provisioned packages from the installation
$Error.Clear()
Foreach ( $AppToRemove in $AppsToRemove) {
    if ( $Offline -eq $true ) {
        Get-AppxProvisionedPackage -Path $OfflinePath | Where-Object { $_.PackageName -like "$($AppToRemove)" } | Remove-AppxProvisionedPackage -Path $OfflinePath
    } Else { 
        # Remove provisioned AppX package that were updated during the install
        Write-Output "Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like $($AppToRemove) } | Remove-AppxProvisionedPackage -online"
        Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like "$($AppToRemove)" } | Remove-AppxProvisionedPackage -online
        # Remove AppX package from all users that have it installed
        Get-AppxPackage -AllUsers -Name "$($AppToRemove)" `
            | Select-Object -ExpandProperty PackageUserInformation `
            | Select-Object -ExpandProperty UserSecurityId `
            | Select-Object SID `
            | Foreach-object { Get-AppxPackage -AllUsers -Name "$($AppToRemove)" | Remove-AppxPackage -user $_.Sid; Get-AppxPackage -AllUsers -Name "$($AppToRemove)" | Remove-AppxPackage -Allusers }
    }
}
If ($Error.Count -gt 0) {
    Write-Output "Removing AppX Packages failed: $($Error[0])"
    CleanUpAndExit -ErrorLevel 101
} else {
    Write-Output "Successfully Removed AppX packages"
}

CleanUpAndExit -ErrorLevel 0

Stop-Transcript
