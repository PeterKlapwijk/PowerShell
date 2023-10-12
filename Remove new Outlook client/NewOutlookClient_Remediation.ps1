# Author(s)    : Peter Klapwijk - www.inthecloud247.com	
# Description  : Script removes the new Microsoft client (preview) app.
#                App is removed because we currently can't manage the app with GPO or Intune policy settings.

try{
    Get-AppxPackage -Name "Microsoft.OutlookForWindows" | Remove-AppxPackage -ErrorAction stop
    Write-Host "New Microsoft client (preview) app successfully removed"

}
catch{
    Write-Error "Error removing Microsoft client (preview) app"
}