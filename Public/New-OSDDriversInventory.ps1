function New-OSDDriversInventory {
    [CmdletBinding()]
    PARAM (
        [Parameter(Position=0)]
        [string]$LocalDrivers = 'C:\Drivers'
    )
    #===================================================================================================
    #   LocalDrivers
    #===================================================================================================
    if (-not(Test-Path "$LocalDrivers")) {New-Item -Path "$LocalDrivers" -ItemType Directory -Force | Out-Null}
    #===================================================================================================
    #   Hardware
    #===================================================================================================
    Write-Host "Generating Hardware List ..."
    $HardwareDevices = Get-CimInstance -Class Win32_PnPEntity | Select-Object -Property DeviceID, Caption, ClassGuid, CompatibleID, Description, HardwareID, Manufacturer, Name, PNPClass, PNPDeviceID, Present, Status
    $HardwareDevices = $HardwareDevices | Sort-Object -Property DeviceID -Unique
    
    Write-Host "Exporting $LocalDrivers\Hardware.csv ..."
    $HardwareDevices | Export-Csv -Path "$LocalDrivers\Hardware.csv"

    Write-Host "Exporting $LocalDrivers\Hardware.xml ..."
    $HardwareDevices | Export-Clixml -Path "$LocalDrivers\Hardware.xml"

    Write-Host ""
    Write-Host "Devices:"

    foreach ($HardwareDevice in $HardwareDevices) {
        Write-Host "$($HardwareDevice.DeviceID) - $($HardwareDevice.Caption)" -ForegroundColor DarkGray
    }
    $OSDDriversInventory = "$LocalDrivers\Hardware.xml"
    Return $OSDDriversInventory
}