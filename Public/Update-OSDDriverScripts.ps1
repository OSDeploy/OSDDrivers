<#
.SYNOPSIS
Updates all OSDDriver Deployment Scripts in a Workspace

.DESCRIPTION
Updates all OSDDriver Deployment Scripts in a Workspace

.LINK
https://osddrivers.osdeploy.com/module/functions/update-osddriverscripts

.PARAMETER WorkspacePath
Directory to the OSDDrivers Workspace.  This contains the Download, Expand, and Package subdirectories
#>
function Update-OSDDriverScripts {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [string]$WorkspacePath
    )
    $PublishDirs = Get-ChildItem "$WorkspacePath" Deploy-OSDDrivers.psm1 -Recurse | Select-Object Directory
    foreach ($PublishDir in $PublishDirs) {
        Write-Verbose "Updating $($PublishDir.Directory)\Deploy-OSDDrivers.psm1" -Verbose
        Publish-OSDDriverScripts -PublishPath "$($PublishDir.Directory)"
    }
}