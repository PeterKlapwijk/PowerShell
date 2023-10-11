![This is an image](https://www.inthecloud247.com/wp-content/uploads/2022/06/GitHub-PowerShell.png)

This is an example of a solution to map network printers on Windows devices.

1. Printermappingv1.0_CreateScheduledTask.ps1 creates a scheduled task.
2. The scheduled task runs when an user logs on to the device, with a short delay.
3. The scheduled task runs a vbs script, this is used to avoid user pop-ups.
4. The vbs script runs the  Printermappingv1.0_ScriptRunFromTaskScheduler.ps1 which does the actual printer mapping.
5. The PS script first checks domain connectivity after which it checks if the printer is already mapped.
6. If the printer is not mapped, the printer is mapped by the script.

An option to deploy the scripts is to wrap them as a win32 app and deploy the package with Microsoft Intune.

The logs are saved on %programdata%\Microsoft\IntuneManagementExtension\Logs. This makes it available in the Device Diagnostics for Intune.

*Note; depending on the needed printer driver, it might be needed to deploy the printer driver separated.*

The related blog post can be found [Here](https://www.inthecloud247.com/manage-printer-mappings-on-cloud-managed-windows-devices/)
