function Publish-OSDDriverScripts {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [string]$PublishPath
    )

$DeployOSDDrivers = @'
#===================================================================================================
#   Import Deploy-OSDDrivers Module
#===================================================================================================
Import-Module -Name "$PSScriptRoot\Deploy-OSDDrivers.psm1" -Force -Verbose
#===================================================================================================
#   Expand-OSDDrivers
#===================================================================================================
Expand-OSDDrivers -PublishPath "$PSScriptRoot"
#===================================================================================================
#   Complete
#===================================================================================================
#Start-Sleep 10
'@

$DeployOSDDriversBeta = @'
#===================================================================================================
#   Import Deploy-OSDDrivers Module
#===================================================================================================
if (-not (Get-Module -Name OSDDrivers)) {
    if (Test-Path "$PSScriptRoot\Deploy-OSDDrivers.psm1") {
        Import-Module -Name "$PSScriptRoot\Deploy-OSDDrivers.psm1" -Force -Verbose
    } else {
        try {
            Import-Module OSDDrivers -Force
        }
        catch {
            Write-Warning 'PowerShell Module Deploy-OSDDrivers could not be loaded ... Exiting'
            Start-Sleep 10
            Exit 0
        }
    }
}
#===================================================================================================
#   Expand-OSDDrivers
#===================================================================================================
Expand-OSDDrivers -PublishPath "$PSScriptRoot"
#===================================================================================================
#   Complete
#===================================================================================================
#Start-Sleep 10
'@

    if (!(Test-Path "$PublishPath")) {New-Item -Path "$PublishPath" -ItemType Directory -Force | Out-Null}

    #Write-Verbose "Generating $PublishPath\Deploy-OSDDrivers.psm1" -Verbose
    Get-Content "$($MyInvocation.MyCommand.Module.ModuleBase)\Private\Deploy\Get-OSDDriverPackages.ps1" | Set-Content "$PublishPath\Deploy-OSDDrivers.psm1"
    Get-Content "$($MyInvocation.MyCommand.Module.ModuleBase)\Private\Deploy\Get-OSDDriverMultiPacks.ps1" | Add-Content "$PublishPath\Deploy-OSDDrivers.psm1"
    Get-Content "$($MyInvocation.MyCommand.Module.ModuleBase)\Private\Deploy\Get-MyHardware.ps1" | Add-Content "$PublishPath\Deploy-OSDDrivers.psm1"
    Get-Content "$($MyInvocation.MyCommand.Module.ModuleBase)\Private\Deploy\Save-MyHardware.ps1" | Add-Content "$PublishPath\Deploy-OSDDrivers.psm1"
    Get-Content "$($MyInvocation.MyCommand.Module.ModuleBase)\Private\Deploy\Expand-OSDDrivers.ps1" | Add-Content "$PublishPath\Deploy-OSDDrivers.psm1"

    #Write-Verbose "Generating $PublishPath\Deploy-OSDDrivers.ps1" -Verbose
    $DeployOSDDrivers | Out-File "$PublishPath\Deploy-OSDDrivers.ps1"
}