# ------------------------------------------------------------------------------------------------------------ #
# Author(s)    : Peter Klapwijk - www.inthecloud247.com			                                       		   #
# Version      : 1.0                                                                                           #
#                                                                                                              #
# Description  : Script that runs at user logon and maps network printer(s)            						   #
#                                                                                                              #
# Changes      : v1.0 - Initial version                                  		                       		   #                                                                     
#                							                                                                   #
#                This script is provide "As-Is" without any warranties                                         #
#                                                                                                              #                     
#------------------------------------------------------------------------------------------------------------- #

#region Functions
Function CleanUpAndExit() {
    Param(
        [Parameter(Mandatory=$True)][String]$ErrorLevel
    )

    # Write results to log file
    $NOW = Get-Date -Format "yyyyMMdd-hhmmss"

    If ($ErrorLevel -eq "0") {
        Write-Host "Printers added successfully at $NOW"
    } else {
        Write-Host "Adding printers failed at $NOW with error $Errorlevel"
    }
    
    # Exit Script with the specified ErrorLevel
    Stop-Transcript | Out-Null
    EXIT $ErrorLevel
}

function Test-DCConnection
{
    $DCConnection = Test-Connection domain.internal -Count 1
        return ($DCConnection -ne $null)
	}

function Test-PrinterBW
{
    $PrinterBW = Get-Printer | Where-Object {$_.Name -eq "\\fps01.domain.internal\Printer-BW"}
        return ($PrinterBW -ne $null)
	}

function Test-PrinterColour
{
    $PrinterColour = Get-Printer | Where-Object {$_.Name -eq "\\fps01.domain.internal\Printer-Colour"}
        return ($PrinterColour -ne $null)
	}

#endregion Functions

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
		Write-Host "STATUS:  No connection with the domain. Unable to add printers!"
		CleanUpAndExit -ErrorLevel 1
	}
	
# ------------------------------------------------------------------------------------------------------- #
# Add printers
# ------------------------------------------------------------------------------------------------------- #

if (Test-PrinterBW -eq $True){
	Write-Host "Printer BW already present"
	}
	else {
		Add-Printer -ConnectionName \\fps01.domain.internal\Printer-BW
		Write-Host "Printer BW added"
	}
	
if (Test-PrinterColour -eq $True){
	Write-Host "Printer Colour already present"
	}
	else {
		Add-Printer -ConnectionName \\fps01.domain.internal\Printer-Colour
		Write-Host "Printer Colour added"
	}
	
	
# ------------------------------------------------------------------------------------------------------- #
# Check end state
# ------------------------------------------------------------------------------------------------------- #

if (Test-PrinterBW -eq $True){
	Write-Host "STATUS: Printer BW present"
	}
	else {
	Write-Host "STATUS: Printer BW NOT present, unknown error"
	CleanUpAndExit -ErrorLevel 2
	}
	
if (Test-PrinterColour -eq $True){
	Write-Host "STATUS: Printer Colour present"
	CleanUpAndExit -ErrorLevel 0
	}
	else {
	Write-Host "STATUS: Printer Colour NOT present, unknown error"
	CleanUpAndExit -ErrorLevel 2
	}
