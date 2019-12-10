<#
.SYNOPSIS
Updates all OSDDriver Deployment Scripts in a Workspace

.DESCRIPTION
Updates all OSDDriver Deployment Scripts in a Workspace.  Updates Deploy-OSDDrivers.psm1

.LINK
https://osddrivers.osdeploy.com/module/functions/update-osddriverscripts
#>
function Update-OSDDriversScripts {
    [CmdletBinding()]
    Param ()
    Begin {
        #===================================================================================================
        #   Get-OSDDrivers
        #===================================================================================================
        Get-OSDDrivers -CreatePaths -HideDetails
    }
    Process {
        #===================================================================================================
        #   Update PathDownload
        #===================================================================================================
        Get-ChildItem $SetOSDDrivers.PathDownload Deploy-OSDDrivers.psm1 -Recurse | ForEach-Object {
            Write-Host "Updating: $($_.Directory)" -ForegroundColor Gray
            Publish-OSDDriverScripts -PublishPath $_.Directory
        }
        #===================================================================================================
        #   Update PathPackages
        #===================================================================================================
        Get-ChildItem $SetOSDDrivers.PathPackages Deploy-OSDDrivers.psm1 -Recurse | ForEach-Object {
            Write-Host "Updating: $($_.Directory)" -ForegroundColor Gray
            Publish-OSDDriverScripts -PublishPath $_.Directory
        }
    }
    End {}
}