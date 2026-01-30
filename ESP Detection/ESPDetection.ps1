# ------------------------------------------------------------------------------------------------------------------#
# Author(s)    : Peter Klapwijk (Original version from jannikreinhard.com)                  				        #
# Version      : 1.1                                                                                                #
#                                                                                                                   #
# Description  : Script checks if the explorer.exe process runs under defaultuser0 or defaultuser1.                 #
#                Should be used as application requirement rule in Intune. Script returns True when the ESP runs.   #
#                Data type; Boolean, Operator; Equals. Value; No (to prohibit installation during ESP).             #
#                                                                                                                   # 
# Changes      : v1.0 - Initial version of Jannik Reinhard                                                          #
#                v1.1 - Added error handling, optimized loop, and improved output                                   #
#                                                                                                                   #                     
#-------------------------------------------------------------------------------------------------------------------#

$processesExplorer = @(Get-CimInstance -ClassName 'Win32_Process' -Filter "Name like 'explorer.exe'" -ErrorAction 'Ignore')
$esp = $false

foreach ($processExplorer in $processesExplorer) {
    try {
        $user = (Invoke-CimMethod -InputObject $processExplorer -MethodName GetOwner).User
        if ($user -eq 'defaultuser0' -or $user -eq 'defaultuser1') {
            $esp = $true
            break # Exit loop early if condition is met
        }
    } catch {
        Write-Output "Error retrieving process owner: $_"
    }
}

Write-Output $esp # Use Write-Output for better integration
