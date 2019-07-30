function Get-MyHardware {
    [CmdletBinding()]
    PARAM ()
    #===================================================================================================
    #   MyHardware
    #===================================================================================================
    $MyHardware = Get-CimInstance -Class Win32_PnPEntity | Select-Object -Property DeviceID, Caption, ClassGuid, CompatibleID, Description, HardwareID, Manufacturer, Name, ADPnpClass, PNPDeviceID, Present, DriverStatus
    $MyHardware = $MyHardware | Sort-Object -Property DeviceID -Unique
    Return $MyHardware
}