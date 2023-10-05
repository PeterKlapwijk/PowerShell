Dim strArgs
Set oShell = CreateObject ("Wscript.Shell")
strArgs = "powershell.exe -executionpolicy bypass -windowstyle hidden -file C:\PROGRA~1\COMMON~1\Klapwijk\PRINTE~1\Printermappingv1.0_ScriptRunFromTaskScheduler.ps1"
oShell.Run strArgs, 0, false