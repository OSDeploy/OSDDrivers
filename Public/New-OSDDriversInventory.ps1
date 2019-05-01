function New-OSDDriversInventory {
    [CmdletBinding()]
    PARAM (
        [Parameter(Position=0)]
        [string]$PathExpandedDrivers = 'C:\Drivers'
    )
    #===================================================================================================
    #   PathExpandedDrivers
    #===================================================================================================
    if (-not(Test-Path "$PathExpandedDrivers")) {New-Item -Path "$PathExpandedDrivers" -ItemType Directory -Force | Out-Null}
    #===================================================================================================
    #   Hardware
    #===================================================================================================
    Write-Host "Generating Hardware List ..." -ForegroundColor Cyan
    $HardwareDevices = Get-CimInstance -Class Win32_PnPEntity | Select-Object -Property DeviceID, Caption, ClassGuid, CompatibleID, Description, HardwareID, Manufacturer, Name, PNPClass, PNPDeviceID, Present, Status
    $HardwareDevices = $HardwareDevices | Sort-Object -Property DeviceID -Unique
    
    Write-Host "Exporting $PathExpandedDrivers\Hardware.csv ..." -ForegroundColor Cyan
    $HardwareDevices | Export-Csv -Path "$PathExpandedDrivers\Hardware.csv"

    Write-Host "Exporting $PathExpandedDrivers\Hardware.xml ..." -ForegroundColor Cyan
    $HardwareDevices | Export-Clixml -Path "$PathExpandedDrivers\Hardware.xml"

    #Write-Host ""
    #Write-Host "Devices:"

    #foreach ($HardwareDevice in $HardwareDevices) {
        #Write-Host "$($HardwareDevice.DeviceID) - $($HardwareDevice.Caption)" -ForegroundColor DarkGray
    #}
    $OSDDriversInventory = "$PathExpandedDrivers\Hardware.xml"
    Return $OSDDriversInventory
}