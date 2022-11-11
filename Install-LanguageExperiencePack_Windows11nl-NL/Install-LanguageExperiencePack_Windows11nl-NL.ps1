# ------------------------------------------------------------------------------------------------------------ #
# Author(s)    : Peter Klapwijk - www.inthecloud247.com                                                        #
#                (Part of the script is from script from www.oliverkieselbach.com)                             #
# Version      : 1.0                                                                                           #
#                                                                                                              #
# Description  : Install an additional language pack including FODs.                                           #
#                Changes language for new users, welcome screen etc.                                           #
#                Uses PowerShell commands only Supported on Windows 11 22H2 and later                          #
#                                                                                                              #
# Changes      : v1.0 - Initial published version                                                              #
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

# custom folder for temp scripts
"...creating custom temp script folder"
$scriptFolderPath = "$env:SystemDrive\ProgramData\$CompanyName\CustomTempScripts"
New-Item -ItemType Directory -Force -Path $scriptFolderPath
"`n"

$userConfigScriptPath = $(Join-Path -Path $scriptFolderPath -ChildPath "UserConfig.ps1")
"...creating userconfig scripts"
# we could encode the complete script to prevent the escaping of $, but I found it easier to maintain
# to not encode. I do not have to decode/encode all the time for modifications.
$userConfigScript = @"
`$language = "$language"

Start-Transcript -Path "`$env:TEMP\LXP-UserSession-Config-`$language.log" | Out-Null

`$geoId = $geoId

# important for regional change like date and time...
"Set-WinUILanguageOverride = `$language"
Set-WinUILanguageOverride -Language `$language

"Set-WinUserLanguageList = `$language"

`$OldList = Get-WinUserLanguageList
`$UserLanguageList = New-WinUserLanguageList -Language `$language
`$UserLanguageList += `$OldList | where { `$_.LanguageTag -ne `$language }
"Setting new user language list:"
`$UserLanguageList | select LanguageTag
""
"Set-WinUserLanguageList -LanguageList ..."
Set-WinUserLanguageList -LanguageList `$UserLanguageList -Force

"Set-Culture = `$language"
Set-Culture -CultureInfo `$language

"Set-WinHomeLocation = `$geoId"
Set-WinHomeLocation -GeoId `$geoId

Stop-Transcript -Verbose
"@

$userConfigScriptHiddenStarterPath = $(Join-Path -Path $scriptFolderPath -ChildPath "UserConfigHiddenStarter.vbs")
$userConfigScriptHiddenStarter = @"
sCmd = "powershell.exe -ex bypass -file ""$userConfigScriptPath"""
Set oShell = CreateObject("WScript.Shell")
oShell.Run sCmd,0,true
"@

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

# Configure new language defaults under current user (system account) after which it can be copied to the system
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

# we have to switch the language for the current user session. The powershell cmdlets must be run in the current logged on user context.
# creating a temp scheduled task to run on-demand in the current user context does the trick here.
"Trigger language change for current user session via ScheduledTask = LXP-UserSession-Config-$language"
Out-File -FilePath $userConfigScriptPath -InputObject $userConfigScript -Encoding ascii
Out-File -FilePath $userConfigScriptHiddenStarterPath -InputObject $userConfigScriptHiddenStarter -Encoding ascii

# REMARK: usag of wscript as hidden starter may be blocked because of security restrictions like AppLocker, ASR, etc...
#         switch to PowerShell if this represents a problem in your environment.
$taskName = "LXP-UserSession-Config-$language"
$action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument """$userConfigScriptHiddenStarterPath"""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -UserId (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -expand UserName)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries
$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings
Register-ScheduledTask $taskName -InputObject $task
Start-ScheduledTask -TaskName $taskName 

Start-Sleep -Seconds 30

Unregister-ScheduledTask -TaskName $taskName -Confirm:$false

# trigger 'LanguageComponentsInstaller\ReconcileLanguageResources' otherwise 'Windows Settings' need a long time to change finally
"Trigger ScheduledTask = LanguageComponentsInstaller\ReconcileLanguageResources"
Start-ScheduledTask -TaskName "\Microsoft\Windows\LanguageComponentsInstaller\ReconcileLanguageResources"

Start-Sleep 10

# trigger store updates, there might be new app versions due to the language change
"Trigger MS Store updates for app updates"
Get-CimInstance -Namespace "root\cimv2\mdm\dmmap" -ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" | Invoke-CimMethod -MethodName "UpdateScanMethod"


# Add registry key for Intune detection
"Add registry key for Intune detection"
REG add "HKLM\Software\$CompanyName\LanguageXPWIN11\v1.0" /v "SetLanguage-$language" /t REG_DWORD /d 1

Exit 0
Stop-Transcript