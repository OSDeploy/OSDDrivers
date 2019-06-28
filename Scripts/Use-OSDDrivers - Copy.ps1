#===================================================================================================
#   To use this script in a running OS or in WinPE, you must have $PSScriptRoot\Modules\OSDDrivers
#   This will be imported prior to execution
#===================================================================================================

#===================================================================================================
#   Import OSDDrivers Module
#===================================================================================================
if (-not (Get-Module -Name OSDDrivers)) {
    if (Test-Path "$PSScriptRoot\Modules\OSDDrivers\OSDDrivers.psd1") {
        Import-Module -Name "$PSScriptRoot\Modules\OSDDrivers" -Verbose
    } else {
        try {
            Import-Module OSDDrivers -Force
        }
        catch {
            Write-Warning 'OSDDrivers Module could not be loaded ... Exiting'
            Start-Sleep 10
            Exit 0
        }
    }
}
#===================================================================================================
#   Expand-OSDDrivers
#===================================================================================================
Expand-OSDDrivers -PackagePath "$PSScriptRoot"
#===================================================================================================
#   Complete
#===================================================================================================
Start-Sleep 10