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
        [ValidateSet ('x64','x86')]
        [string]$OsArch,

        [Parameter(Mandatory)]
        [ValidateSet ('10.0','6.3','6.1')]
        [string]$OsVersion,

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
    #   Sort
    #===================================================================================================
    $OSDDriverPnp = $OSDDriverPnp | Sort-Object HardwareId -Unique
    #===================================================================================================
    #   GridView
    #===================================================================================================
    if ($GridView.IsPresent) {$OSDDriverPnp = $OSDDriverPnp | Out-GridView -PassThru -Title 'Select Drivers to include in the PNP File'}
    #===================================================================================================
    #   Generate Pnp
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
    $SourceName = (Get-Item $ExpandedDriverPath).Name
    $CabName = "$SourceName.cab"
    $PackagedDriverPath = (Join-Path $PackagedDriverGroup $CabName)
    if (Test-Path "$PackagedDriverPath") {
        Write-Warning "Driver Package already exists"
    } else {
        New-CabFileOSDDriver -ExpandedDriverPath $ExpandedDriverPath -PublishPath $PackagedDriverGroup
    }
    #===================================================================================================
    #   Verify Driver Package
    #===================================================================================================
    if (-not (Test-Path "$PackagedDriverPath")) {
        Write-Warning "Driver Expand: Could not package Driver to $PackagedDriverPath ... Exiting"
        Continue
    } else {
        Publish-OSDDriverScripts -PublishPath $PackagedDriverGroup
    }
    #===================================================================================================
    #   New-OSDDriverTask
    #===================================================================================================
    New-OSDDriverTask -OSDDriverFile $PackagedDriverPath -OSDGroup 'NvidiaPack' -OsVersion $OsVersion -OsArch $OsArch -DriverVersion "$DriverVersion"
}