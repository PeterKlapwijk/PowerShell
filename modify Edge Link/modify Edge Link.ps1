# Script to modify a .lnk file
# www.IntheCloud247.com
#modify variables accordingly 
$fileName ="Microsoft Edge.lnk" 
$folder = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs"
$list = Get-ChildItem -Path $folder -Filter $fileName -Recurse  | Where-Object { $_.Attributes -ne "Directory"} | select -ExpandProperty FullName 
$obj = New-Object -ComObject WScript.Shell 
 
ForEach($lnk in $list) 
      { 
      $obj = New-Object -ComObject WScript.Shell 
      $link = $obj.CreateShortcut($lnk) 
      [string]$path = $link.TargetPath 
      $link.Arguments = "--start-fullscreen" 
      $link.TargetPath = [string]$path 
      $link.Save() 
  } 
