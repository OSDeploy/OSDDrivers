<#
.SYNOPSIS
Updates the OSDDriver PowerShell Module to the latest version

.DESCRIPTION
Updates the OSDDriver PowerShell Module to the latest version from the PowerShell Gallery

.LINK
https://www.osdeploy.com/osddriver/docs/functions/update-moduleosddriver

.Example
Update-ModuleOSDDriver
#>
function Update-ModuleOSDDriver {
    [CmdletBinding()]
    PARAM ()
    try {
        Write-Warning "Uninstall-Module -Name OSDDriver -AllVersions -Force"
        Uninstall-Module -Name OSDDriver -AllVersions -Force
    }
    catch {}

    try {
        Write-Warning "Install-Module -Name OSDDriver -Force"
        Install-Module -Name OSDDriver -Force
    }
    catch {}

    try {
        Write-Warning "Import-Module -Name OSDDriver -Force"
        Import-Module -Name OSDDriver -Force
    }
    catch {}
}