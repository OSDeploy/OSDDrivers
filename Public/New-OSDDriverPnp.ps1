function New-OSDDriverPnp {
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory)]
        [string]$DriverDirectory,
        [ValidateSet('Bluetooth','Camera','Display','HDC','HIDClass','Keyboard','Media','Monitor','Mouse','Net','SCSIAdapter','SmartCardReader','System','USBDevice')]
        [string]$DriverClass,
        [switch]$GridView
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
        #   DriverClass
        #===================================================================================================
        if ($DriverClass) {$OSDDriverPnp = $OSDDriverPnp | Where-Object {$_.ClassName -eq $DriverClass}}
        #===================================================================================================
        #   Sort
        #===================================================================================================
        $OSDDriverPnp = $OSDDriverPnp | Sort-Object HardwareId
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
        $OSDDriverPnp = "$DriverParent\$DriverDirectoryName.pnp.xml"
        Return $OSDDriverPnp
    }
}