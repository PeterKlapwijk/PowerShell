# ------------------------------------------------------------------------------------------------------------ #
# Author(s)    : Peter Klapwijk - www.InTheCloud247.com                                                        #
# Version      : 1.0                                                                                           #
#                                                                                                              #
# Description  : This script removes unwanted (pre-installed) AppX packages from the system                    # 
#                                                                                                              #
# Changes      : v1.0 - Initial version																		   #
#   																                                           #
# This script is provide "As-Is" without any warranties                                                        #
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
        [microsoft.win32.registry]::SetValue($Key, "Error Code", $ErrorLevel)
    }
    
    # Exit Script with the specified ErrorLevel
    Stop-Transcript | Out-Null
    EXIT $ErrorLevel
}

# ---------------------------------------------------------------------------- #
# Set Generic Script Variables, etc.
# ---------------------------------------------------------------------------- #
$StoreResults = "Klapwijk\AppXRemoval\v1.0"

# Ensure the log directory exists
$LogDirectory = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"
If (-Not (Test-Path -Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
}

# Start Transcript
If (-not $PSCOMMANDPATH) {
    Throw "PSCOMMANDPATH is not defined."
}

Try {
    Start-Transcript -Path "$LogDirectory\$($(Split-Path $PSCommandPath -Leaf).ToLower().Replace('.ps1','.log'))" | Out-Null
} Catch {
    Write-Output "Warning: Failed to start transcript. Error: $_"
}

# List of AppX packages to remove
$AppXPackagesToRemove = @(
    "Microsoft.BingNews", 
    "Microsoft.BingWeather", 
    "Microsoft.GamingApp", 
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftOffaiceHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MixedReality.Portal",
    "Microsoft.Office.OneNote",
    "Microsoft.People",
    "Microsoft.PowerAutomateDesktop",
    "Microsoft.SkypeApp",
    "Microsoft.Xbox.TCUI", 
    "Microsoft.XboxGameOverlay", 
    "Microsoft.XboxGamingOverlay", 
    "Microsoft.XboxIdentityProvider", 
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.WindowsAlarms",
    "Microsoft.windowscommunicationsapps",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.YourPhone", 
    "Microsoft.ZuneMusic", 
    "Microsoft.ZuneVideo",
    "Microsoft.OutlookForWindows",
    "Microsoft.Copilot",
    "Microsoft.Windows.DevHome",
    "Microsoft.MicrosoftStickyNotes"
)

# Function to remove AppX packages for the current user or all users
function Remove-AppXPackages {
    param (
        [string[]]$Packages,
        [switch]$ForAllUsers
    )

    foreach ($PackageName in $Packages) {
        if ($ForAllUsers) {
            Write-Output "Removing AppX package '$PackageName' for all users..."
            Get-AppxPackage -AllUsers -Name $PackageName | ForEach-Object {
                try {
                    Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction Stop
                    Write-Output "Removed package: $($_.Name)"
                } catch {
                    Write-Output "Failed to remove package: $($_.Name). Error: $_"
                }
            }
        } else {
            Write-Output "Removing AppX package '$PackageName' for the current user..."
            Get-AppxPackage -Name $PackageName | ForEach-Object {
                try {
                    Remove-AppxPackage -Package $_.PackageFullName -ErrorAction Stop
                    Write-Output "Removed package: $($_.Name)"
                } catch {
                    Write-Output "Failed to remove package: $($_.Name). Error: $_"
                }
            }
        }
    }
}

# Function to remove AppxProvisionedPackages
function Remove-AppxProvisionedPackages {
    param (
        [string[]]$Packages
    )

    foreach ($PackageName in $Packages) {
        Write-Output "Removing provisioned AppX package '$PackageName'..."
        Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $PackageName } | ForEach-Object {
            try {
                Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction Stop
                Write-Output "Removed provisioned package: $($_.DisplayName)"
            } catch {
                Write-Output "Failed to remove provisioned package: $($_.DisplayName). Error: $_"
            }
        }
    }
}

# Clear previous errors
$Error.Clear()

# Comment the line which is not needed
# Remove the specified AppX packages for the current user
Write-Output "Start removing AppX packages for the current user"
Remove-AppXPackages -Packages $AppXPackagesToRemove

# Remove the specified AppX packages for all users
Write-Output "Start removing AppX packages for the all users"
Remove-AppXPackages -Packages $AppXPackagesToRemove -ForAllUsers

# Remove the specified provisioned AppX packages
Write-Output "Start removing provisioned AppX packages"
Remove-AppxProvisionedPackages -Packages $AppXPackagesToRemove

# Result
If ($Error.Count -gt 0) {
    Write-Output "Removing AppX Packages failed: $($Error[0])"
    CleanUpAndExit -ErrorLevel 101
} else {
    Write-Output "Successfully Removed AppX packages"
}

CleanUpAndExit -ErrorLevel 0
