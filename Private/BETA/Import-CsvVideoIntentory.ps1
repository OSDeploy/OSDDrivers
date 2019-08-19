function Import-CsvVideoIntentory {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [string]$CsvFile
    )

    $ImportCsvFile = Import-Csv "$CsvFile"
    $CsvVideoIntentory = foreach ($item in $ImportCsvFile) {
        $Manufacturer = $null
        $Vendor =$null
    
        $Device = ($item.HardwareId -split '\&SUBSYS')[0]
        if ($Device -match 'VEN_1002') {$Manufacturer = 'AMD'}
        if ($Device -match 'VEN_8086') {$Manufacturer = 'Intel'}
        if ($Device -match 'VEN_102B') {$Manufacturer = 'Matrox'}
        if ($Device -match 'VEN_10DE') {$Manufacturer = 'Nvidia'}
    
        $HardwareId = ($item.HardwareId -split '\&REV')[0]
        if ($HardwareId -like "*1028") {$Vendor = 'Dell'}
        if ($HardwareId -like "*1002") {$Vendor = 'AMD'}
        if ($HardwareId -like "*8086") {$Vendor = 'Intel'}
        if ($HardwareId -like "*102B") {$Vendor = 'Matrox'}
        if ($HardwareId -like "*10DE") {$Vendor = 'Nvidia'}
    
        $ObjectProperties = @{
            Manufacturer = $Manufacturer
            Device = $Device
            HardwareId = $HardwareId
            ComputerModel = [string] $item.Model
            Vendor = $Vendor
            Description = [string] $item.Description
            #HardwareId = [string] $item.HardwareId
            Driver = $null
        }
        New-Object -TypeName PSObject -Property $ObjectProperties
    }
    
    $CsvVideoIntentory = $CsvVideoIntentory | Select-Object Driver, Vendor, Manufacturer, Device, HardwareId, Description, ComputerModel


    Return $CsvVideoIntentory



    
}