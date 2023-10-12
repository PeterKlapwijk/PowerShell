# Author(s)    : Peter Klapwijk - www.inthecloud247.com	
# Description  :Script detects the new Microsoft Outlook (preview) app.

if ($null -eq (Get-AppxPackage -Name "Microsoft.OutlookForWindows")) {
	Write-Host "New Microsoft Outlook client not found"
	exit 0
} Else {
	Write-Host "New Microsoft Outlook client found"
	Exit 1

}
