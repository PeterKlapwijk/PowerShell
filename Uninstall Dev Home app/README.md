![This is an image](https://www.inthecloud247.com/wp-content/uploads/2022/06/GitHub-PowerShell.png)

These are two scripts that can be used with Intune (Proactive) Remediation scripts to detect and remove the installation of the Dev Home app which is installed automatically on Windows (11) devices.
The detection script (UninstallDevHome_Detection.ps1) is run on the Windows client and detects the installation of the Dev Home app.
The remediation script (NUninstallDevHome_Remediation.ps1) uninstalls the Dev Home app when the app is detected.

When using an Intune remediation, Set Run this script using the logged-on credentials to Yes
