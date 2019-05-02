function New-OSDDriversInventory {
    [CmdletBinding()]
    PARAM (
        [Parameter(Position=0)]
        [string]$PathDrivers = 'C:\Drivers'
    )
    #===================================================================================================
    #   PathDrivers
    #===================================================================================================
    if (-not(Test-Path "$PathDrivers")) {New-Item -Path "$PathDrivers" -ItemType Directory -Force | Out-Null}
    #===================================================================================================
    #   Hardware
    #===================================================================================================
    Write-Host "Generating Hardware List ..." -ForegroundColor Cyan
    $HardwareDevices = Get-CimInstance -Class Win32_PnPEntity | Select-Object -Property DeviceID, Caption, ClassGuid, CompatibleID, Description, HardwareID, Manufacturer, Name, PNPClass, PNPDeviceID, Present, Status
    $HardwareDevices = $HardwareDevices | Sort-Object -Property DeviceID -Unique
    
    Write-Host "Exporting $PathDrivers\Hardware.csv ..." -ForegroundColor Cyan
    $HardwareDevices | Export-Csv -Path "$PathDrivers\Hardware.csv"

    Write-Host "Exporting $PathDrivers\Hardware.xml ..." -ForegroundColor Cyan
    $HardwareDevices | Export-Clixml -Path "$PathDrivers\Hardware.xml"

    #Write-Host ""
    #Write-Host "Devices:"

    #foreach ($HardwareDevice in $HardwareDevices) {
        #Write-Host "$($HardwareDevice.DeviceID) - $($HardwareDevice.Caption)" -ForegroundColor DarkGray
    #}
    $OSDDriversInventory = "$PathDrivers\Hardware.xml"
    Return $OSDDriversInventory
}