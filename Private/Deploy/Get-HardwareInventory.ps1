function Get-HardwareInventory {
    [CmdletBinding()]
    PARAM ()
    #===================================================================================================
    #   HardwareInventory
    #===================================================================================================
    $HardwareInventory = Get-CimInstance -Class Win32_PnPEntity | Select-Object -Property DeviceID, Caption, ClassGuid, CompatibleID, Description, HardwareID, Manufacturer, Name, ADPnpClass, PNPDeviceID, Present, DriverStatus
    $HardwareInventory = $HardwareInventory | Sort-Object -Property DeviceID -Unique
    Return $HardwareInventory
}