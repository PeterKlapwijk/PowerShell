![This is an image](https://www.inthecloud247.com/wp-content/uploads/2022/06/GitHub-PowerShell.png)

This is an example of a solution to connect drive mappings on Windows devices.

1. DriveMappingsv1.0_CreateScheduledTask creates a scheduled task.
2. The scheduled task runs when a network change is detected, based on event id 10000 (Path="Microsoft-Windows-NetworkProfile/Operational).
3. The scheduled task runs a vbs script, this is used to avoid user pop-ups.
4. The vbs script runs the DriveMappingsv1.0_ScriptRunFromTaskScheduler.ps1 which connects the drive mappings.
5. The PS script first checks domain connectivity after which it checks if the drive mappings already exist.
6. If the drive mapping does not exist, the drive mapping is connected by the script.

An option to deploy the scripts is to wrap them as a win32 app and deploy the package with Microsoft Intune.

The logs are saved on %programdata%\Microsoft\IntuneManagementExtension\Logs. This makes it available in the Device Diagnostics for Intune.


My website can be found here [Here](https://www.inthecloud247.com/)
