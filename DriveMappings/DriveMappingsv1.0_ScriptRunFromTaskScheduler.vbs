'Change COMPANY in your own company name
Dim strArgs
Set oShell = CreateObject ("Wscript.Shell")
strArgs = "powershell.exe -executionpolicy bypass -windowstyle hidden -file C:\PROGRA~1\COMMON~1\Company\DRIVEM~1\DriveMappingsv1.0_ScriptRunFromTaskScheduler.ps1"
oShell.Run strArgs, 0, false