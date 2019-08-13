<#
.SYNOPSIS
Compresses an Nvidia Driver to CAB and generates a Task

.DESCRIPTION
Compresses an Nvidia Driver to CAB and generates a Task for Deploy-OSDDrivers

.LINK
https://osddrivers.osdeploy.com/module/functions/new-nvidiapack

.PARAMETER WorkspacePath
Directory to the OSDDrivers Workspace.  This contains the Download, Expand, and Package subdirectories
#>
function New-NvidiaPack {
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory)]
        [string]$ExpandedDriverPath,

        [Parameter(Mandatory)]
        [string]$WorkspacePath,

        [Parameter(Mandatory)]
        [string]$DriverVersion,

        [Parameter(Mandatory)]
        [string]$DriverReleaseId,

        [Parameter(Mandatory)]
        [ValidateSet ('x64','x86')]
        [string]$OsArch,

        [Parameter(Mandatory)]
        [ValidateSet ('10.0','6.3','6.1')]
        [string]$OsVersion,

        [Parameter(Mandatory)]
        [ValidateSet ('GeForce','Quadro','Dell')]
        [string]$NvidiaFamily,

        [switch]$GeForce,

        #[string]$PublishPath,
        [switch]$GridView
    )
    #===================================================================================================
    #   Defaults
    #===================================================================================================
    $OSDPnpClass = 'Display'
    #===================================================================================================
    #   Test-ExpandedDriverPath
    #===================================================================================================
    Test-ExpandedDriverPath $ExpandedDriverPath
    #===================================================================================================
    #   OSDDriverPnp
    #===================================================================================================
    $OSDDriverPnp = @()
    if ($GeForce.IsPresent) {
        $OSDDriverPnp = Get-OSDDriverPnp -ExpandedDriverPath $ExpandedDriverPath -NoHardwareIdRev -GeForce
    } else {
        $OSDDriverPnp = Get-OSDDriverPnp -ExpandedDriverPath $ExpandedDriverPath -NoHardwareIdRev
    }
    #===================================================================================================
    #   OSDPnpClass
    #===================================================================================================
    if ($OSDPnpClass) {$OSDDriverPnp = $OSDDriverPnp | Where-Object {$_.ClassName -eq $OSDPnpClass}}
    #===================================================================================================
    #   Remove PCI
    #===================================================================================================
    foreach ($DriverPnp in $OSDDriverPnp) {
        $DriverPnp.HardwareId = ($DriverPnp.HardwareId -replace 'PCI\\','')
    }
    #===================================================================================================
    #   Sort and Filter
    #===================================================================================================
    $OSDDriverPnp = $OSDDriverPnp | Sort-Object HardwareId -Unique

    $OSDDriverPnpParent = @()
    $OSDDriverPnpParent = $OSDDriverPnp | Where-Object {$_.HardwareId -notmatch 'SUBSYS'}

    $OSDDriverPnpChild = @()
    $OSDDriverPnpChild = $OSDDriverPnp | Where-Object {$_.HardwareId -match 'SUBSYS'}
    foreach ($Parent in $OSDDriverPnpParent) {
        $OSDDriverPnpChild = $OSDDriverPnpChild | Where-Object {$_.HardwareId -notmatch $($Parent.HardwareId)}
    }
    $OSDDriverPnp = @()
    [array]$OSDDriverPnp = [array]$OSDDriverPnpParent + [array]$OSDDriverPnpChild
    $OSDDriverPnp = $OSDDriverPnp | Sort-Object HardwareId -Unique
    #===================================================================================================
    #   GridView
    #===================================================================================================
    if ($GridView.IsPresent) {$OSDDriverPnp = $OSDDriverPnp | Out-GridView -PassThru -Title 'Select Drivers to include in the PNP File'}
    #===================================================================================================
    #   Generate Expanded Pnp
    #===================================================================================================
    $OSDDriverPnp = $OSDDriverPnp | Sort-Object HardwareId

    #Write-Host "Save-OSDDriverPnp: Saving $ExpandedDriverPath\OSDDriver.drvpnp" -ForegroundColor Gray
    $OSDDriverPnp | Export-Clixml -Path "$ExpandedDriverPath\OSDDriver.drvpnp"

    #Write-Host "Save-OSDDriverPnp: Saving $ExpandedDriverPath\OSDDriver-Devices.txt" -ForegroundColor Gray
    New-Item "$ExpandedDriverPath\OSDDriver-Devices.csv" -Force | Out-Null
    New-Item "$ExpandedDriverPath\OSDDriver-Devices.txt" -Force | Out-Null
    Add-Content -Path "$ExpandedDriverPath\OSDDriver-Devices.csv" -Value "HardwareId,HardwareDescription"
    foreach ($DriverPnp in $OSDDriverPnp) {
        Add-Content -Path "$ExpandedDriverPath\OSDDriver-Devices.csv" -Value "$($DriverPnp.HardwareId),$($DriverPnp.HardwareDescription)"
        Add-Content -Path "$ExpandedDriverPath\OSDDriver-Devices.txt" -Value "$($DriverPnp.HardwareId),$($DriverPnp.HardwareDescription)"
    }
    #===================================================================================================
    #   Create Package
    #===================================================================================================
    $PackagedDriverGroup = Get-PathOSDD -Path (Join-Path $WorkspacePath (Join-Path 'Package' 'NvidiaPack'))
    $PackagedDriverSubGroup = Get-PathOSDD -Path (Join-Path $PackagedDriverGroup "NvidiaPack $NvidiaFamily $DriverReleaseId $OsVersion $OsArch")
    $SourceName = (Get-Item $ExpandedDriverPath).Name
    $CabName = "$SourceName.cab"
    $PackagedDriverPath = (Join-Path $PackagedDriverSubGroup $CabName)
    if (Test-Path "$PackagedDriverPath") {
        Write-Warning "Driver Package already exists"
    } else {
        New-CabFileOSDDriver -ExpandedDriverPath $ExpandedDriverPath -PublishPath $PackagedDriverSubGroup
    }
    #===================================================================================================
    #   Generate Packaged Pnp
    #===================================================================================================
    $OSDDriverPnp | Export-Clixml -Path "$PackagedDriverSubGroup\$SourceName.drvpnp"
    New-Item "$PackagedDriverSubGroup\$SourceName.csv" -Force | Out-Null
    New-Item "$PackagedDriverSubGroup\$SourceName.txt" -Force | Out-Null
    Add-Content -Path "$PackagedDriverSubGroup\$SourceName.csv" -Value "HardwareId,HardwareDescription"
    foreach ($DriverPnp in $OSDDriverPnp) {
        Add-Content -Path "$PackagedDriverSubGroup\$SourceName.csv" -Value "$($DriverPnp.HardwareId),$($DriverPnp.HardwareDescription)"
        Add-Content -Path "$PackagedDriverSubGroup\$SourceName.txt" -Value "$($DriverPnp.HardwareId),$($DriverPnp.HardwareDescription)"
    }
    #===================================================================================================
    #   Generate WMI
    #===================================================================================================
    $WmiCodePath = Join-Path -Path "$PackagedDriverSubGroup" -ChildPath "WmiQuery.txt"
    
    $WmiCodeString = [System.Text.StringBuilder]::new()
    [void]$WmiCodeString.AppendLine('SELECT DeviceId FROM Win32_PNPEntity  WHERE')

    foreach ($Pnp in $OSDDriverPnp) {
        [void]$WmiCodeString.AppendLine("DeviceId LIKE '%$($Pnp.HardwareId)%'")
        if ($Pnp -eq $OSDDriverPnp[-1]){
            #"last item in array is $Item"
        } else {
            [void]$WmiCodeString.Append('OR ')
        }
    }
    $WmiCodeString.ToString() | Out-File -FilePath $WmiCodePath -Encoding UTF8
    #===================================================================================================
    #   Verify Driver Package
    #===================================================================================================
    if (-not (Test-Path "$PackagedDriverPath")) {
        Write-Warning "Driver Expand: Could not package Driver to $PackagedDriverPath ... Exiting"
        Continue
    } else {
        Publish-OSDDriverScripts -PublishPath $PackagedDriverGroup
        Publish-OSDDriverScripts -PublishPath $PackagedDriverSubGroup
    }
    #===================================================================================================
    #   New-OSDDriverTask
    #===================================================================================================
    New-OSDDriverTask -OSDDriverFile $PackagedDriverPath -OSDGroup 'NvidiaPack' -OsVersion $OsVersion -OsArch $OsArch -DriverVersion "$DriverVersion" -DriverReleaseId "$DriverReleaseId"
}