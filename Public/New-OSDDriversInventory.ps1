function New-OSDDriversInventory {
    [CmdletBinding()]
    PARAM (
        [Parameter(Position=0)]
        [string]$LocalDirectory = 'C:\Drivers'
    )
    #===================================================================================================
    #   LocalDirectory
    #===================================================================================================
    if (-not(Test-Path "$LocalDirectory")) {New-Item -Path "$LocalDirectory" -ItemType Directory -Force | Out-Null}
    #===================================================================================================
    #   Hardware
    #===================================================================================================
    Write-Host "Generating Hardware List ..."
    $HardwareDevices = Get-CimInstance -Class Win32_PnPEntity | Select-Object -Property DeviceID, Caption, ClassGuid, CompatibleID, Description, HardwareID, Manufacturer, Name, PNPClass, PNPDeviceID, Present, Status
    $HardwareDevices = $HardwareDevices | Sort-Object -Property DeviceID -Unique
    
    Write-Host "Exporting $LocalDirectory\Hardware.csv ..."
    $HardwareDevices | Export-Csv -Path "$LocalDirectory\Hardware.csv"

    Write-Host "Exporting $LocalDirectory\Hardware.xml ..."
    $HardwareDevices | Export-Clixml -Path "$LocalDirectory\Hardware.xml"

    Write-Host ""
    Write-Host "Devices:"

    foreach ($HardwareDevice in $HardwareDevices) {
        Write-Host "$($HardwareDevice.DeviceID) - $($HardwareDevice.Caption)" -ForegroundColor DarkGray
    }
}