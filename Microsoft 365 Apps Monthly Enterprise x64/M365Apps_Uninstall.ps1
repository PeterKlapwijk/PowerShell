#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Uninstalls Microsoft 365 Apps (Office Click-to-Run) with all language packs.

.DESCRIPTION
    This script removes Microsoft 365 Apps (formerly Office 365 ProPlus) using the Office Deployment Tool.
    It removes all installed Office products and all language packs.

.NOTES
    File Name      : M365AppsMonthlyEnterprisex64_Uninstall.ps1
    Author        : Peter Klapwijk (InTheCloud247.com)
    Intune Deployment: Package as Win32 app using Microsoft Win32 Content Prep Tool
#>

[CmdletBinding()]
param()

# Set error action preference
$ErrorActionPreference = "Stop"

# Define variables
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ODTSetupPath = Join-Path -Path $ScriptPath -ChildPath "setup.exe"
$UninstallXMLPath = Join-Path -Path $ScriptPath -ChildPath "uninstall.xml"
$LogPath = Join-Path -Path $env:ProgramData -ChildPath "Microsoft\IntuneManagementExtension\Logs"
$LogFile = Join-Path -Path $LogPath -ChildPath "M365Apps_Uninstall_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Create log directory if it doesn't exist
if (-not (Test-Path -Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

# Function to write log
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    Write-Output $LogMessage
    Add-Content -Path $LogFile -Value $LogMessage -Force
}

# Start uninstallation
Write-Log -Message "========================================" -Level "INFO"
Write-Log -Message "Starting Microsoft 365 Apps uninstallation" -Level "INFO"
Write-Log -Message "========================================" -Level "INFO"

# Create uninstall configuration XML
$UninstallXML = @"
<Configuration>
  <Remove All="TRUE">
    <!-- Remove all Office products and all language packs -->
  </Remove>
  <Display Level="None" AcceptEULA="TRUE" />
  <Logging Level="Standard" Path="$LogPath" />
</Configuration>
"@

try {
    # Write uninstall XML to file
    Write-Log -Message "Creating uninstall configuration file: $UninstallXMLPath" -Level "INFO"
    Set-Content -Path $UninstallXMLPath -Value $UninstallXML -Force
    Write-Log -Message "Uninstall configuration file created successfully" -Level "INFO"
    
    # Check if setup.exe exists
    if (-not (Test-Path -Path $ODTSetupPath)) {
        Write-Log -Message "Office Deployment Tool (setup.exe) not found at: $ODTSetupPath" -Level "ERROR"
        Write-Log -Message "Attempting to download Office Deployment Tool..." -Level "INFO"
        
        # Download ODT
        $ODTDownloadURL = "https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_17531-20046.exe"
        $ODTDownloadPath = Join-Path -Path $ScriptPath -ChildPath "officedeploymenttool.exe"
        
        Write-Log -Message "Downloading from: $ODTDownloadURL" -Level "INFO"
        Invoke-WebRequest -Uri $ODTDownloadURL -OutFile $ODTDownloadPath -UseBasicParsing
        Write-Log -Message "Download completed" -Level "INFO"
        
        # Extract ODT
        Write-Log -Message "Extracting Office Deployment Tool..." -Level "INFO"
        Start-Process -FilePath $ODTDownloadPath -ArgumentList "/quiet /extract:`"$ScriptPath`"" -Wait -NoNewWindow
        Write-Log -Message "Extraction completed" -Level "INFO"
        
        # Verify setup.exe exists after extraction
        if (-not (Test-Path -Path $ODTSetupPath)) {
            Write-Log -Message "Failed to extract setup.exe from Office Deployment Tool" -Level "ERROR"
            exit 1
        }
    }
    
    Write-Log -Message "Office Deployment Tool found: $ODTSetupPath" -Level "INFO"
    
    # Check if Office is installed
    Write-Log -Message "Checking if Microsoft 365 Apps is installed..." -Level "INFO"
    
    $OfficeInstalled = $false
    $OfficeC2R = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -ErrorAction SilentlyContinue
    
    if ($OfficeC2R) {
        Write-Log -Message "Microsoft 365 Apps (Click-to-Run) detected" -Level "INFO"
        Write-Log -Message "Version: $($OfficeC2R.VersionToReport)" -Level "INFO"
        Write-Log -Message "Platform: $($OfficeC2R.Platform)" -Level "INFO"
        $OfficeInstalled = $true
    } else {
        Write-Log -Message "Microsoft 365 Apps (Click-to-Run) is not installed" -Level "WARNING"
        Write-Log -Message "Proceeding with uninstallation attempt anyway..." -Level "INFO"
    }
    
    # Run Office Deployment Tool to uninstall Office
    Write-Log -Message "Starting Office uninstallation process..." -Level "INFO"
    Write-Log -Message "Command: $ODTSetupPath /configure `"$UninstallXMLPath`"" -Level "INFO"
    
    $Process = Start-Process -FilePath $ODTSetupPath -ArgumentList "/configure `"$UninstallXMLPath`"" -Wait -PassThru -NoNewWindow
    
    $ExitCode = $Process.ExitCode
    Write-Log -Message "Office Deployment Tool completed with exit code: $ExitCode" -Level "INFO"
    
    # Check exit code
    switch ($ExitCode) {
        0 {
            Write-Log -Message "Microsoft 365 Apps uninstallation completed successfully" -Level "INFO"
        }
        17 {
            Write-Log -Message "Uninstallation completed successfully (another installation was already in progress)" -Level "INFO"
        }
        30175 {
            Write-Log -Message "Office was not found on this system" -Level "WARNING"
        }
        default {
            Write-Log -Message "Uninstallation completed with exit code: $ExitCode" -Level "WARNING"
        }
    }
    
    # Verify Office removal
    Write-Log -Message "Verifying Office removal..." -Level "INFO"
    $OfficeStillInstalled = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -ErrorAction SilentlyContinue
    
    if ($OfficeStillInstalled) {
        Write-Log -Message "Warning: Office registry keys still detected" -Level "WARNING"
    } else {
        Write-Log -Message "Office Click-to-Run registry keys removed successfully" -Level "INFO"
    }
    
    # Clean up temporary files
    Write-Log -Message "Cleaning up temporary files..." -Level "INFO"
    if (Test-Path -Path $UninstallXMLPath) {
        Remove-Item -Path $UninstallXMLPath -Force -ErrorAction SilentlyContinue
    }
    
    Write-Log -Message "========================================" -Level "INFO"
    Write-Log -Message "Uninstallation process completed" -Level "INFO"
    Write-Log -Message "Log file: $LogFile" -Level "INFO"
    Write-Log -Message "========================================" -Level "INFO"
    
    exit $ExitCode
}
catch {
    Write-Log -Message "Error during uninstallation: $($_.Exception.Message)" -Level "ERROR"
    Write-Log -Message "Stack Trace: $($_.ScriptStackTrace)" -Level "ERROR"
    exit 1
}
