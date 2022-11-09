# ------------------------------------------------------------------------------------------------------------ #
# Author(s)    : Peter Klapwijk - www.inthecloud247.com                                                        #
# Version      : 1.0                                                                                           #
#                                                                                                              #
# Description  : Install an additional language pack during Autopilot ESP.                                     #
#                Changes language for new users, welcome screen etc.                                           #
#                Uses PowerShell commands only Supported on Windows 11 22H2 and later                          #
#                                                                                                              #
# Changes      : v1.0 - Initial version                                                                		   # 
#                                                                                                              # 
#                                                                                                              #
#                This script is provide "As-Is" without any warranties                                 		   #
#                                                                                                              #
#------------------------------------------------------------------------------------------------------------- #

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


#Set variables:
#Company name
$CompanyName = "Klapwijk"
# The language we want as new default. Language tag can be found here: https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/available-language-packs-for-windows
$language = "nl-NL"
# Geographical ID we want to set. GeoID can be found here: https://learn.microsoft.com/en-us/windows/win32/intl/table-of-geographical-locations?redirectedfrom=MSDN
$geoId = "176"  # Netherlands

# Start Transcript
Start-Transcript -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$($(Split-Path $PSCommandPath -Leaf).ToLower().Replace(".ps1",".log"))" | Out-Null

# Install an additional language pack including FODs
"Installing languagepack"
Install-Language $language -CopyToSettings

#Set System Preferred UI Language
"Set SystemPreferredUILanguage"
Set-SystemPreferredUILanguage $language

#Check status of the installed language pack
"Checking installed languagepack status"
$installedLanguage = (Get-InstalledLanguage).LanguageId

if ($installedLanguage -like $language){
	Write-Host "Language $language installed"
	}
	else {
	Write-Host "Failure! Language $language NOT installed"
    Exit 1
}

#Check status of the System Preferred Language
$SystemPreferredUILanguage = Get-SystemPreferredUILanguage

if ($SystemPreferredUILanguage -like $language){
    Write-Host "System Preferred UI Language set to $language. OK"
    }
    else {
    Write-Host "Failure! System Preferred UI Language NOT set to $language. System Preferred UI Language is $SystemPreferredUILanguage"
    Exit 1
}

# Configure new language defaults under current user (system) after which it can be copied to system
#Set Win UI Language Override for regional changes
"Set WinUILanguageOverride"
Set-WinUILanguageOverride -Language $language

# Set Win User Language List, sets the current user language settings
"Set WinUserLanguageList"
$OldList = Get-WinUserLanguageList
$UserLanguageList = New-WinUserLanguageList -Language $language
$UserLanguageList += $OldList | where { $_.LanguageTag -ne $language }
$UserLanguageList | select LanguageTag
Set-WinUserLanguageList -LanguageList $UserLanguageList -Force

# Set Culture, sets the user culture for the current user account.
"Set culture"
Set-Culture -CultureInfo $language

# Set Win Home Location, sets the home location setting for the current user 
"Set WinHomeLocation"
Set-WinHomeLocation -GeoId $geoId

# Copy User Internaltional Settings from current user to System, including Welcome screen and new user
"Copy UserInternationalSettingsToSystem "
Copy-UserInternationalSettingsToSystem -WelcomeScreen $True -NewUser $True

# Add registry key for Intune detection
"Add registry key for Intune detection"
REG add "HKLM\Software\$CompanyName\LanguageXPWIN11ESP\v1.0" /v "SetLanguage-$language" /t REG_DWORD /d 1

Exit 3010
Stop-Transcript