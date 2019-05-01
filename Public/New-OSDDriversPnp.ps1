function New-OSDDriversPnp {
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory)]
        [string]$DriverDirectory,

        [ValidateSet('Bluetooth','Camera','Display','HDC','HIDClass','Keyboard','Media','Monitor','Mouse','Net','SCSIAdapter','SmartCardReader','System','USBDevice')]
        [string]$DriverClass,

        [switch]$GridView,

        [ValidateSet('Any','Windows7','Windows10','Server2016','Server2019')]
        [string[]]$OperatingSystem = 'Any',

        [ValidateSet('Any','x64','x86')]
        [string]$OSArch = 'Any',

        [ValidateSet('Any','1507','1511','1607','1703','1709','1803','1809','1903')]
        [string]$OSBuildMin = 'Any',

        [ValidateSet('Any','1507','1511','1607','1703','1709','1803','1809','1903')]
        [string]$OSBuildMax = 'Any',

        [ValidateSet('Any','6.1','6.2','6.3','10')]
        [string]$OSVersionMin = 'Any',

        [ValidateSet('Any','6.1','6.2','6.3','10')]
        [string]$OSVersionMax = 'Any',

        [string[]]$MakeLike = 'Any',
        [string[]]$MakeNotLike = 'Any',
        [string[]]$ModelLike = 'Any',
        [string[]]$ModelNotLike = 'Any'
    )
    $DriverDirectory = Get-Item $DriverDirectory
    $DriverParent = (Get-Item "$DriverDirectory").parent.FullName
    $DriverDirectoryName = (Get-Item "$DriverDirectory").Name


    if (Test-Path "$DriverDirectory") {
        Get-ChildItem "$DriverDirectory" autorun.inf -Recurse | Remove-Item -Force
        Get-ChildItem "$DriverDirectory" setup.inf -Recurse | Remove-Item -Force
        $ExpandInfs = Get-ChildItem -Path "$DriverDirectory" -Recurse -Include *.inf -File | Where-Object {$_.Name -notlike "*autorun.inf*"} | Select-Object -Property FullName
        $OSDDriverPnp = @()
        foreach ($ExpandInf in $ExpandInfs) {
            Write-Host "$($ExpandInf.FullName)" -ForegroundColor DarkGray
            $OSDDriverPnp += Get-WindowsDriver -Online -Driver "$($ExpandInf.FullName)" | `
            Select-Object -Property HardwareId,Version,ManufacturerName,HardwareDescription,`
            Architecture,ServiceName,CompatibleIds,ExcludeIds,Driver,Inbox,CatalogFile,`
            ClassName,ClassGuid,ClassDescription,BootCritical,DriverSignature,ProviderName,`
            Date,MajorVersion,MinorVersion,Build,Revision
        }
        #===================================================================================================
        #   Properties
        #===================================================================================================
        $OSDDriverPnp | Add-Member -NotePropertyName OperatingSystem -NotePropertyValue $OperatingSystem
        $OSDDriverPnp | Add-Member -NotePropertyName OSArch -NotePropertyValue $OSArch
        $OSDDriverPnp | Add-Member -NotePropertyName OSBuildMin -NotePropertyValue $OSBuildMin
        $OSDDriverPnp | Add-Member -NotePropertyName OSBuildMax -NotePropertyValue $OSBuildMax
        $OSDDriverPnp | Add-Member -NotePropertyName OSVersionMin -NotePropertyValue $OSVersionMin
        $OSDDriverPnp | Add-Member -NotePropertyName OSVersionMax -NotePropertyValue $OSVersionMax
        $OSDDriverPnp | Add-Member -NotePropertyName MakeLike -NotePropertyValue $MakeLike
        $OSDDriverPnp | Add-Member -NotePropertyName MakeNotLike -NotePropertyValue $MakeNotLike
        $OSDDriverPnp | Add-Member -NotePropertyName ModelLike -NotePropertyValue $ModelLike
        $OSDDriverPnp | Add-Member -NotePropertyName ModelNotLike -NotePropertyValue $ModelNotLike
        #$OSDDriverPnp | Add-Member -NotePropertyName CompatManufacturer -NotePropertyValue $CompatManufacturer
        #$OSDDriverPnp | Add-Member -NotePropertyName CompatModel -NotePropertyValue $CompatModel
        #===================================================================================================
        #   DriverClass
        #===================================================================================================
        if ($DriverClass) {$OSDDriverPnp = $OSDDriverPnp | Where-Object {$_.ClassName -eq $DriverClass}}
        #===================================================================================================
        #   Sort
        #===================================================================================================
        $OSDDriverPnp = $OSDDriverPnp | Sort-Object HardwareId #-Unique
        #===================================================================================================
        #   GridView
        #===================================================================================================
        if ($GridView.IsPresent) {$OSDDriverPnp = $OSDDriverPnp | Out-GridView -PassThru -Title 'Select Drivers for PNP Xml'}
        #===================================================================================================
        #   Create XML
        #===================================================================================================
        Write-Host "Generating $DriverDirectory\OSDDriver.pnp.xml ..." -ForegroundColor Gray
        $OSDDriverPnp | Export-Clixml -Path "$DriverDirectory\OSDDriver.pnp.xml"
        Write-Host "Generating $DriverParent\$DriverDirectoryName.pnp.xml ..." -ForegroundColor Gray
        $OSDDriverPnp | Export-Clixml -Path "$DriverParent\$DriverDirectoryName.pnp.xml"
    }
}