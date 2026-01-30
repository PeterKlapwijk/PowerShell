# Office Deployment Toolkit - M365 Apps Monthly Enterprise x64 Installation Script
# This script uses setup.exe from the Office Deployment Toolkit to install Microsoft 365 Apps
# Optimized for Microsoft Intune Win32 App deployment

<#
.SYNOPSIS
    Installs Microsoft 365 Apps (Monthly Enterprise Channel, x64) using Office Deployment Toolkit.

.DESCRIPTION
    This script is designed to be packaged as an Intune Win32 app and uses setup.exe from the 
    Office Deployment Toolkit with a predefined XML configuration file.
    
    Exit Codes:
    0 = Success
    1 = General failure
    2 = setup.exe not found
    3 = Configuration file not found
    
.NOTES
    File Name      : M365AppsMonthlyEnterprisex64.ps1
    Author        : Peter Klapwijk (InTheCloud247.com)
    Prerequisite   : setup.exe and M365AppsMonthlyEnterprisex64.xml must be in the same directory
    Intune Deployment: Package as Win32 app using Microsoft Win32 Content Prep Tool
#>

# Configure logging
$LogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"
$LogFile = Join-Path $LogPath "M365AppsMonthlyEnterprisex64.log"

# Create log directory if it doesn't exist
if (-not (Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

# Start transcript logging
Start-Transcript -Path $LogFile -Append -Force

# Log start time
Write-Host "Script started at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan

# Set the script location as the working directory
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptPath

# Define file paths
$SetupExe = Join-Path $ScriptPath "setup.exe"
$ConfigFile = Join-Path $ScriptPath "M365AppsMonthlyEnterprisex64.xml"

# Verify that setup.exe exists
if (-not (Test-Path $SetupExe)) {
    Write-Error "setup.exe not found in $ScriptPath"
    Write-Error "Please ensure the Office Deployment Toolkit is extracted to this directory."
    Stop-Transcript
    exit 2
}

# Verify that the configuration file exists
if (-not (Test-Path $ConfigFile)) {
    Write-Error "Configuration file not found: $ConfigFile"
    Write-Error "Please ensure M365AppsMonthlyEnterprisex64.xml exists in this directory."
    Stop-Transcript
    exit 3
}

# Display information
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Office Deployment Toolkit - Installation Script" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Setup executable: $SetupExe" -ForegroundColor Green
Write-Host "Configuration file: $ConfigFile" -ForegroundColor Green
Write-Host ""
Write-Host "Starting Office installation..." -ForegroundColor Yellow
Write-Host ""

# Run setup.exe with the configuration file
# /configure - Installs Office using the specified XML configuration file
try {
    $Process = Start-Process -FilePath $SetupExe -ArgumentList "/configure `"$ConfigFile`"" -Wait -PassThru -NoNewWindow
    
    if ($Process.ExitCode -eq 0) {
        Write-Host ""
        Write-Host "================================================" -ForegroundColor Green
        Write-Host "Installation completed successfully!" -ForegroundColor Green
        Write-Host "================================================" -ForegroundColor Green
        
        # Retrieve installation information from registry
        Write-Host ""
        Write-Host "Installation Summary:" -ForegroundColor Cyan
        Write-Host "---------------------------------------------------" -ForegroundColor Cyan
        
        # Check registry paths for Office information
        # Note: Registry may take time to populate during automated deployments
        $OfficeC2RPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
        $OfficeC2RPathWow64 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration"
        
        # Wait for registry keys to be available (up to 60 seconds)
        $MaxRetries = 12
        $RetryCount = 0
        $RegPath = $null
        
        while ($RetryCount -lt $MaxRetries -and -not $RegPath) {
            if (Test-Path $OfficeC2RPath) {
                $RegPath = $OfficeC2RPath
                break
            }
            elseif (Test-Path $OfficeC2RPathWow64) {
                $RegPath = $OfficeC2RPathWow64
                break
            }
            
            if ($RetryCount -eq 0) {
                Write-Host "Waiting for Office installation to finalize..." -ForegroundColor Yellow
            }
            
            $RetryCount++
            Start-Sleep -Seconds 5
        }
        
        if ($RegPath) {
            try {
                $Platform = (Get-ItemProperty -Path $RegPath -Name "Platform" -ErrorAction SilentlyContinue).Platform
                $VersionToReport = (Get-ItemProperty -Path $RegPath -Name "VersionToReport" -ErrorAction SilentlyContinue).VersionToReport
                $UpdateChannel = (Get-ItemProperty -Path $RegPath -Name "UpdateChannel" -ErrorAction SilentlyContinue).UpdateChannel
                $ProductReleaseIds = (Get-ItemProperty -Path $RegPath -Name "ProductReleaseIds" -ErrorAction SilentlyContinue).ProductReleaseIds
                $ClientCulture = (Get-ItemProperty -Path $RegPath -Name "ClientCulture" -ErrorAction SilentlyContinue).ClientCulture
                
                Write-Host "Product: Microsoft 365 Apps" -ForegroundColor White
                if ($Platform) { Write-Host "Architecture: $Platform" -ForegroundColor White }
                if ($VersionToReport) { Write-Host "Version: $VersionToReport" -ForegroundColor White }
                if ($UpdateChannel) { 
                    $ChannelName = switch ($UpdateChannel) {
                        "http://officecdn.microsoft.com/pr/55336b82-a18d-4dd6-b5f6-9e5095c314a6" { "Monthly Enterprise Channel" }
                        "http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60" { "Current Channel" }
                        "http://officecdn.microsoft.com/pr/64256afe-f5d9-4f86-8936-8840a6a4f5be" { "Current Channel (Preview)" }
                        "http://officecdn.microsoft.com/pr/7ffbc6bf-bc32-4f92-8982-f9dd17fd3114" { "Semi-Annual Enterprise Channel" }
                        "http://officecdn.microsoft.com/pr/b8f9b850-328d-4355-9145-c59439a0c4cf" { "Semi-Annual Enterprise Channel (Preview)" }
                        "http://officecdn.microsoft.com/pr/5440fd1f-7ecb-4221-8110-145efaa6372f" { "Beta Channel" }
                        default { $UpdateChannel }
                    }
                    Write-Host "Update Channel: $ChannelName" -ForegroundColor White 
                }
                if ($ClientCulture) { Write-Host "Language: $ClientCulture" -ForegroundColor White }
                if ($ProductReleaseIds) { Write-Host "Products: $ProductReleaseIds" -ForegroundColor White }
            }
            catch {
                Write-Warning "Could not retrieve all installation details from registry"
            }
        }
        else {
            Write-Warning "Could not locate Office installation information in registry"
        }
        
        Write-Host "---------------------------------------------------" -ForegroundColor Cyan
        Write-Host "Script completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
        Stop-Transcript
        exit 0
    }
    else {
        Write-Host ""
        Write-Host "================================================" -ForegroundColor Red
        Write-Host "Installation failed with exit code: $($Process.ExitCode)" -ForegroundColor Red
        Write-Host "================================================" -ForegroundColor Red
        Write-Host "Script completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
        Stop-Transcript
        exit $Process.ExitCode
    }
}
catch {
    Write-Error "An error occurred during installation: $_"
    Write-Host "Script completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
    Stop-Transcript
    exit 1
}
