function New-OSDDriverCabPnp {
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory)]
        [string]$DriverDirectoryPath,
        [ValidateSet('Bluetooth','Camera','Display','HDC','HIDClass','Keyboard','Media','Monitor','Mouse','Net','SCSIAdapter','SmartCardReader','System','USBDevice')]
        [string]$DriverClass,
        [switch]$GridView
    )
    $DriverDirectory = Get-Item $DriverDirectoryPath
    $DriverDirectoryParent = (Get-Item "$DriverDirectory").parent.FullName
    $DriverDirectoryName = (Get-Item "$DriverDirectory").Name


    if (Test-Path "$DriverDirectoryPath") {
        Get-ChildItem "$DriverDirectoryPath" autorun.inf -Recurse | ForEach-Object {$_ | Rename-Item -NewName $_.Name.Replace('.inf', '.txt') -Force}
        Get-ChildItem "$DriverDirectoryPath" setup.inf -Recurse | ForEach-Object {$_ | Rename-Item -NewName $_.Name.Replace('.inf', '.txt') -Force}
        $ExpandInfs = Get-ChildItem -Path "$DriverDirectoryPath" -Recurse -Include *.inf -File | Where-Object {$_.Name -notlike "*autorun.inf*"} | Select-Object -Property FullName
        $OSDDriverPnp = @()
        foreach ($ExpandInf in $ExpandInfs) {
            Write-Host "Processing $($ExpandInf.FullName)" -ForegroundColor DarkGray
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
        if ($GridView.IsPresent) {$OSDDriverPnp = $OSDDriverPnp | Out-GridView -PassThru -Title 'Select Drivers to include in the PNP File'}
        #===================================================================================================
        #   Create XML
        #===================================================================================================
        Write-Host "Generating $DriverDirectoryPath\OSDDriver.pnp ..." -ForegroundColor DarkGray
        $OSDDriverPnp | Export-Clixml -Path "$DriverDirectoryPath\OSDDriver.pnp"
        Write-Host "Generating $DriverDirectoryParent\$DriverDirectoryName.cab.pnp ..." -ForegroundColor DarkGray
        $OSDDriverPnp | Export-Clixml -Path "$DriverDirectoryParent\$DriverDirectoryName.cab.pnp"
        $OSDDriverPnp = "$DriverDirectoryParent\$DriverDirectoryName.cab.pnp"
        Return $OSDDriverPnp
    }
}