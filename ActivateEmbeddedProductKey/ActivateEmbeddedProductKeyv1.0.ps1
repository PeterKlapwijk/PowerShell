# --------------------------------------------------------------------------------------------- # 
# Author(s)    : Peter Klapwijk - www.InTheCloud247.com      					#
# Version      : 1.0                                                                            #
#                                                                                               #
# Description  : Script retrieves the firmware-embedded product key and activates Windows       #
#                with this key									#
#                										#
# Changes      : v1.0 Initial version	                                                        #
#                										#
# --------------------------------------------------------------------------------------------- #

# Start Transcript
$Transcript = "C:\programdata\Microsoft\IntuneManagementExtension\Logs\$($(Split-Path $PSCommandPath -Leaf).ToLower().Replace(".ps1",".log"))"
Start-Transcript -Path $Transcript | Out-Null

#Get firmware-embedded product key
try {
    $EmbeddedKey=(Get-CimInstance -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey
    write-host "Firmware-embedded product key is "$EmbeddedKey""
} catch {
    write-host "ERROR: Failed to retrieve firmware-embedded product key"
    Exit 1
}

#Install embedded key
try {
    cscript.exe "$env:SystemRoot\System32\slmgr.vbs" /ipk "$EmbeddedKey"
    write-host "Installed license key"
} catch {
    write-host "ERROR: Changing license key failed"
    Exit 2
}

#Active embedded key
try {
    cscript.exe "$env:SystemRoot\System32\slmgr.vbs" /ato
    write-host "Windows activated"
} catch {
    write-host "ERROR: Windows could not be activated."
    Exit 3
}

#Check Product Key Channel
$getreg=Get-WmiObject SoftwareLicensingProduct -Filter "ApplicationID = '55c92734-d682-4d71-983e-d6ec3f16059f' and LicenseStatus = '1'"
$ProductKeyChannel=$getreg.ProductKeyChannel

    if ($getreg.ProductKeyChannel -eq "OEM:DM") {
        write-host "Windows activated, ProductKeyChannel = "$ProductKeyChannel""
		Exit 0
    } else {
		write-host "ERROR: Windows could not be activated. "$ProductKeyChannel""
		Exit 4
    }

Stop-Transcript
