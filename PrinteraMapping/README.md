![This is an image](https://www.inthecloud247.com/wp-content/uploads/2022/06/GitHub-PowerShell.png)

This is an example of a solution to map network printers on Windows devices.

Printermappingv1.0_CreateScheduledTask.ps1 creates an scheduled task.
The scheduled task runs when an user logs on to the device, with a short delay.
The scheduled task runs a vbs script, this is used to avoid user pop-ups.
The vbs script runs the  Printermappingv1.0_ScriptRunFromTaskScheduler.ps1 which does the actual printer mapping.
The PS script first checks domain connectivity after which it checks if the printer is already mapped.
If the printer is not mapped, the printer is mapped by the script.

An option to deploy the scripts, is to wrap them as win32 app and deploy the package with Microsoft Intune.

*Note; depending on the needed printer driver, it might be needed to deploy the printer driver separated.*
