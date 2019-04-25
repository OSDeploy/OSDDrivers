function New-OSDDriversXml {
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory)]
        [string]$DriverDirectory,

        [ValidateSet('Bluetooth','Camera','Display','HDC','HIDClass','Keyboard','Media','Monitor','Mouse','Net','SCSIAdapter','SmartCardReader','System','USBDevice')]
        [string]$DriverClass,

        [ValidateSet('Windows7','Windows10')]
        [string]$CompatClient,

        [ValidateSet('Server2016','Server2019')]
        [string]$CompatServer,

        [ValidateSet('x64','x86')]
        [string]$CompatArch,

        [switch]$GridView
        #[string]$CompatManufacturer,
        #[string[]]$CompatModel
        #[ValidateSet('Any','PNPID','DriverClass','OS','Arch','Manufacturer','Model')]
        #[string]$MatchA = $null,
        #[ValidateSet('Any','PNPID','DriverClass','OS','Arch','Manufacturer','Model')]
        #[string]$MatchB = $null,
        #[ValidateSet('Any','PNPID','DriverClass','OS','Arch','Manufacturer','Model')]
        #[string]$MatchC = $null,
        #[ValidateSet('Any','PNPID','DriverClass','OS','Arch','Manufacturer','Model')]
        #[string]$MatchD = $null
    )
    $DriverDirectory = Get-Item $DriverDirectory
    $DriverParent = (Get-Item "$DriverDirectory").parent.FullName
    $DriverDirectoryName = (Get-Item "$DriverDirectory").Name


    if (Test-Path "$DriverDirectory") {
        Get-ChildItem "$DriverDirectory" autorun.inf -Recurse | Remove-Item -Force
        Get-ChildItem "$DriverDirectory" setup.inf -Recurse | Remove-Item -Force
        $ExpandInfs = Get-ChildItem -Path "$DriverDirectory" -Recurse -Include *.inf -File | Where-Object {$_.Name -notlike "*autorun.inf*"} | Select-Object -Property FullName
        $CabDrivers = @()
        foreach ($ExpandInf in $ExpandInfs) {
            Write-Host "$($ExpandInf.FullName)" -ForegroundColor DarkGray
            $CabDrivers += Get-WindowsDriver -Online -Driver "$($ExpandInf.FullName)" | `
            Select-Object -Property HardwareId,Version,ManufacturerName,HardwareDescription,`
            Architecture,ServiceName,CompatibleIds,ExcludeIds,Driver,Inbox,CatalogFile,`
            ClassName,ClassGuid,ClassDescription,BootCritical,DriverSignature,ProviderName,`
            Date,MajorVersion,MinorVersion,Build,Revision
        }
        #===================================================================================================
        #   Properties
        #===================================================================================================
        $CabDrivers | Add-Member -NotePropertyName CompatClient -NotePropertyValue $CompatClient
        $CabDrivers | Add-Member -NotePropertyName CompatServer -NotePropertyValue $CompatServer
        $CabDrivers | Add-Member -NotePropertyName CompatArch -NotePropertyValue $CompatArch
        #$CabDrivers | Add-Member -NotePropertyName CompatManufacturer -NotePropertyValue $CompatManufacturer
        #$CabDrivers | Add-Member -NotePropertyName CompatModel -NotePropertyValue $CompatModel
        #===================================================================================================
        #   DriverClass
        #===================================================================================================
        if ($DriverClass) {$CabDrivers = $CabDrivers | Where-Object {$_.ClassName -eq $DriverClass}}
        #===================================================================================================
        #   Sort
        #===================================================================================================
        $CabDrivers = $CabDrivers | Sort-Object HardwareId #-Unique
        #===================================================================================================
        #   GridView
        #===================================================================================================
        if ($GridView.IsPresent) {$CabDrivers = $CabDrivers | Out-GridView -PassThru -Title 'Select Drivers for XmlPnp'}
        #===================================================================================================
        #   Create XML
        #===================================================================================================
        Write-Host "Generating $DriverDirectory\OSDDriver.xmlpnp ..." -ForegroundColor Gray
        $CabDrivers | Export-Clixml -Path "$DriverDirectory\OSDDriver.xmlpnp"
    }
}