function Save-PnpOSDIntelPack {
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$ExpandedDriverPath,

        #[string]$PublishPath,

        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateSet('Bluetooth','Camera','Display','HDC','HIDClass','Keyboard','Media','Monitor','Mouse','Net','SCSIAdapter','SmartCardReader','System','USBDevice')]
        [string]$OSDPnpClass,

        [switch]$GridView
    )
    #===================================================================================================
    #   Test-ExpandedDriverPath
    #===================================================================================================
    Test-ExpandedDriverPath $ExpandedDriverPath
    #===================================================================================================
    #   OSDDriverPnp
    #===================================================================================================
    $OSDDriverPnp = @()
    $OSDDriverPnp = Get-OSDDriverPnp -ExpandedDriverPath $ExpandedDriverPath -NoHardwareIdRev -NoHardwareIdSubsys
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

<#     if ($PublishPath) {
        #===================================================================================================
        #   Test-PublishPath
        #===================================================================================================
        Test-PublishPath $PublishPath
        #===================================================================================================
        #   Get-DirectoryName
        #===================================================================================================
        $DirectoryName = Get-DirectoryName $ExpandedDriverPath
        #===================================================================================================
        #   Publish-OSDDriverPnp
        #===================================================================================================
        Write-Host "OSDDriverPnp: Saving $PublishPath\$($DirectoryName).drvpnp ..." -ForegroundColor Gray
        $OSDDriverPnp | Export-Clixml -Path "$PublishPath\$($DirectoryName).drvpnp"
    } #>
}