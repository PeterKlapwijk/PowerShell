![This is an image](https://www.inthecloud247.com/wp-content/uploads/2022/06/GitHub-PowerShell.png)

This is an example of how we can automatically update Microsoft Edge (for example during Autopilot enrollment).

An option to deploy the scripts is to wrap them as a win32 app and deploy the package with Microsoft Intune (during Autopilot enrollment).

The logs are saved on %programdata%\Microsoft\IntuneManagementExtension\Logs. This makes it available in the Device Diagnostics for Intune.

The related blog post can be found here [Here](https://inthecloud247.com/update-microsoft-edge-during-windows-autopilot-enrollments/)
