# --------------------------------------------------------------------------------------------- # 
# Author(s)    : Peter Klapwijk - www.InTheCloud247.com      				        #
# Version      : 1.0                                                                            #
#                                                                                               #
# Description  : Detection script to be used with Microsoft Intune, determines if the current   #
#                Product Key Channel is OEM or Retail					        #
#                										#
# Changes      : v1.0 Initial version	                                                        #
#                										#
# --------------------------------------------------------------------------------------------- #

$getreg=Get-WmiObject SoftwareLicensingProduct -Filter "ApplicationID = '55c92734-d682-4d71-983e-d6ec3f16059f' and LicenseStatus = '1'"
$ProductKeyChannel=$getreg.ProductKeyChannel

    if ($getreg.ProductKeyChannel -eq "OEM:DM" -or $getreg.ProductKeyChannel -eq "Retail") {
        write-host "Correct ProductKeyChannel found = "$ProductKeyChannel""
		Exit 0
    } else {
		write-host "ERROR: Wrong ProductKeyChannel found =  "$ProductKeyChannel""
		Exit 4
    }
