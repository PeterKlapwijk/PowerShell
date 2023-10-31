# ------------------------------------------------------------------------------------------------------------ #
# Author(s)    : Peter Klapwijk - www.inthecloud247.com			                                       		   #
# Version      : 1.0                                                                                           #
#                                                                                                              #
# Description  : Script that runs on network change and connects drive mapping(s)   						   #
#                                                                                                              #
# Changes      : v1.0 - Initial version                                  		                       		   #                                                                 
#                							                                                                   #
#                This script is provide "As-Is" without any warranties                                         #
#                                                                                                              #                     
#------------------------------------------------------------------------------------------------------------- #

# ------------------------------------------------------------------------------------------------------- #
# Functions
# ------------------------------------------------------------------------------------------------------- #
Function CleanUpAndExit() {
    Param(
        [Parameter(Mandatory=$True)][String]$ErrorLevel
    )

    # Write results to log file
    $NOW = Get-Date -Format "yyyyMMdd-hhmmss"

    If ($ErrorLevel -eq "0") {
        Write-Host "Drive mappings connected successfully at $NOW"
    } else {
        Write-Host "Connecting drive mappings failed at $NOW with error $Errorlevel"
    }
    
    # Exit Script with the specified ErrorLevel
    Stop-Transcript | Out-Null
    EXIT $ErrorLevel
}

function Test-DCConnection
{
    $DCConnection = Test-Connection domain.local -Count 1
        return ($DCConnection -ne $null)
	}

function Test-DriveMappingK
{
    $DriveMappingK = Get-PSDrive -Name "K" -erroraction 'silentlycontinue'
        return ($DriveMappingK -ne $null)
	}

function Test-DriveMappingM
{
    $DriveMappingK = Get-PSDrive -Name "M" -erroraction 'silentlycontinue'
        return ($DriveMappingK -ne $null)
	}

# ------------------------------------------------------------------------------------------------------- #
# Start Transcript
# ------------------------------------------------------------------------------------------------------- #
$Transcript = "C:\programdata\Microsoft\IntuneManagementExtension\Logs\$($(Split-Path $PSCommandPath -Leaf).ToLower().Replace(".ps1",".log"))"
Start-Transcript -Path $Transcript | Out-Null

# ------------------------------------------------------------------------------------------------------- #
# Check domain connectivity
# ------------------------------------------------------------------------------------------------------- #

if (Test-DCConnection -eq $True){
	Write-Host "STATUS: Domain connection OK"
	}
	else {
		Write-Host "STATUS:  No connection with the domain. Unable to connect drive mappings!"
		CleanUpAndExit -ErrorLevel 1
	}
    
# ------------------------------------------------------------------------------------------------------- #
# Add drive mapping(s)
# ------------------------------------------------------------------------------------------------------- #

if (Test-DriveMappingK -eq $True){
	Write-Host "A drive with the name 'K' already exists"
	}
	else {
		New-PSDrive -Name "K" -PSProvider FileSystem -Root "\\FileServer\Share1" -Persist -Scope Global
		Write-Host "Drive K: is connected"
	}

if (Test-DriveMappingM -eq $True){
	Write-Host "A drive with the name 'M' already exists"
	}
	else {
		New-PSDrive -Name "M" -PSProvider FileSystem -Root "\\FileServer\Share2" -Persist -Scope Global
		Write-Host "Drive M: is connected"
	}

# ------------------------------------------------------------------------------------------------------- #
# Check end state
# ------------------------------------------------------------------------------------------------------- #

if (Test-DriveMappingK -eq $True){
	Write-Host "STATUS: K: drive connected"
	}
	else {
	Write-Host "STATUS: K: drive not connected, unknown error"
	CleanUpAndExit -ErrorLevel 2
	}

if (Test-DriveMappingM -eq $True){
	Write-Host "STATUS: M: drive connected"
    CleanUpAndExit -ErrorLevel 0
	}
	else {
	Write-Host "STATUS: M: drive not connected, unknown error"
	CleanUpAndExit -ErrorLevel 2
	}