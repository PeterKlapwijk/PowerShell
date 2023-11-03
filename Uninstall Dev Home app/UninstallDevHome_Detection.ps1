#Script detects if the Dev Home UWP app is installed under the current user.

if ($null -eq (Get-AppxPackage -Name "*Windows.DevHome*")) {
	Write-Host "Dev Home app not found"
	exit 0
} Else {
	Write-Host "Dev Home app found"
	Exit 1

}