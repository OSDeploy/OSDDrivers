function Save-HardwareInventory {
    [CmdletBinding()]
    PARAM (
        [Parameter(Position = 0)]
        [string]$ExpandDriverPath = 'C:\Drivers'
    )
    #===================================================================================================
    #   ExpandDriverPath
    #===================================================================================================
    if (-not(Test-Path "$ExpandDriverPath")) {New-Item -Path "$ExpandDriverPath" -ItemType Directory -Force | Out-Null}
    #===================================================================================================
    #   HardwareInventory
    #===================================================================================================
    Write-Verbose "Generating HardwareInventory ..." -Verbose

    $HardwareInventory = @()
    $HardwareInventory = Get-HardwareInventory
    #$HardwareInventory = $HardwareInventory | Sort-Object -Property DeviceID -Unique
    
    Write-Verbose "Exporting $ExpandDriverPath\HardwareInventory.csv ..." -Verbose
    $HardwareInventory | Export-Csv -Path "$ExpandDriverPath\HardwareInventory.csv"

    Write-Verbose "Exporting $ExpandDriverPath\HardwareInventory.xml ..." -Verbose
    $HardwareInventory | Export-Clixml -Path "$ExpandDriverPath\HardwareInventory.xml"

    #Write-Host ""
    #Write-Host "Devices:"

    #foreach ($HardwareDevice in $HardwareInventory) {
        #Write-Host "$($HardwareDevice.DeviceID) - $($HardwareDevice.Caption)" -ForegroundColor DarkGray
    #}

    $HardwareInventoryExport = "$ExpandDriverPath\HardwareInventory.xml"
    Return $HardwareInventoryExport
}