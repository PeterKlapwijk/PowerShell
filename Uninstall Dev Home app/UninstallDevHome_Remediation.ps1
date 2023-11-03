#Script removes the Dev Home UWP app from the Windows device.
#Run the script using an Intune remediation. Set Run this script using the logged-on credentials to Yes

try{
    Get-AppxPackage -Name "*Windows.DevHome*" | Remove-AppxPackage -ErrorAction stop
    Write-Host "Dev Home app successfully removed"

}
catch{
    Write-Error "Error removing Dev Home"
}