<#
.SYNOPSIS
Updates the OSDDrivers PowerShell Module to the latest version

.DESCRIPTION
Updates the OSDDrivers PowerShell Module to the latest version from the PowerShell Gallery

.LINK
https://www.osdeploy.com/osddrivers/docs/functions/update-moduleosddrivers

.Example
Update-ModuleOSDDrivers
#>
function Update-ModuleOSDDrivers {
    [CmdletBinding()]
    PARAM ()
    try {
        Write-Warning "Uninstall-Module -Name OSDDrivers -AllVersions -Force"
        Uninstall-Module -Name OSDDrivers -AllVersions -Force
    }
    catch {}

    try {
        Write-Warning "Install-Module -Name OSDDrivers -Force"
        Install-Module -Name OSDDrivers -Force
    }
    catch {}

    try {
        Write-Warning "Import-Module -Name OSDDrivers -Force"
        Import-Module -Name OSDDrivers -Force
    }
    catch {}
}