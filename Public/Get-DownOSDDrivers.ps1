function Get-DownOSDDrivers {
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory)]
        [string]$DownloadPath,

        [Parameter(Mandatory)]
        [string]$PackagePath,

        [Parameter(Mandatory)]
        [ValidateSet('Display Intel')]
        [string]$DriverGroup
    )
    #===================================================================================================
    #   Variables
    #===================================================================================================
    $Global:OSDInfoUrl = $null
    $Global:OSDPageUrl = $null
    $Global:OSDDownloadUrl = $null
    $Global:OSDDownloadFileName = $null
    $Global:DriverClass = $null
    $Global:DriverClassGUID = $null
    #===================================================================================================
    #   Create Paths
    #===================================================================================================
    if (!(Test-Path "$DownloadPath")) {New-Item -Path "$DownloadPath" -ItemType Directory -Force | Out-Null}
    if (!(Test-Path "$PackagePath")) {New-Item -Path "$PackagePath" -ItemType Directory -Force | Out-Null}
    #===================================================================================================
    #   DriverGroup
    #===================================================================================================
    if ($DriverGroup -eq 'Display Intel') {Get-DownDisplayIntel}
    else {Exit}
    #===================================================================================================
    #   OSDDownloadUrl
    #===================================================================================================
    Write-Host "Validating $OSDDownloadUrl" -ForegroundColor Cyan
    Write-Host ""
    #===================================================================================================
    #   Return URLLinks
    #===================================================================================================
    $URLLinks = @()
    $URLLinks = (Invoke-WebRequest -Uri "$OSDDownloadUrl").Links

    if ($DriverGroup -eq 'Display Intel') {$URLLinks = Get-DownDisplayIntelLinks}
    else {Exit}
    #===================================================================================================
    #   Return Downloads
    #===================================================================================================
    $UrlDownloads = @()
    $DriverDownloads = @()
    $DriverDownloads = foreach ($URLLink in $URLLinks) {
        $DriverName = $($URLLink.innerText)
        Write-Host "$DriverName"

        $DriverPage = $($URLLink.href)
        Write-Host "$DriverPage" -ForegroundColor DarkGray
        $UrlDownloads = (Invoke-WebRequest -Uri $($URLLink.href)).Links
        $UrlDownloads = $UrlDownloads | Where-Object {($_.'data-direct-path' -like "*.exe") -or ($_.'data-direct-path' -like "*.zip")}

        #if ($DownloadType -eq 'exe') {$UrlDownload = $UrlDownload | Where-Object {$_.'data-direct-path' -like "*.exe"}}
        $UrlDownloads = $UrlDownloads | Where-Object {$_.'data-direct-path' -like "*.zip"}

        foreach ($UrlDownload in $UrlDownloads) {
            $DriverVersion = $null
            $DriverWin7 = $null
            $DriverWin10 = $null
            $DriverArch = $null
            $DriverDownload = $UrlDownload.'data-direct-path'

            if ($DriverPage -eq 'https://downloadcenter.intel.com/download/22520/Graphics-Intel-Graphics-Media-Accelerator-Driver-for-Windows-7-Windows-Vista-64-Bit-zip-?product=80939') {
                $DriverVersion = '15.22.58.2993'
                $DriverWin7 = $true
                $DriverArch = 'x64'
            }
            if ($DriverPage -eq 'https://downloadcenter.intel.com/download/22518/Intel-Graphics-Media-Accelerator-Driver-Windows-7-and-Windows-Vista-zip-?product=80939') {
                $DriverVersion = '15.22.58.2993'
                $DriverWin7 = $true
                $DriverArch = 'x86'
            }

            if ($null -eq $DriverArch) {
                if ($DriverDownload -like "*win64*") {
                    $DriverArch = 'x64'
                } else {
                    $DriverArch = 'x86'
                }
            }

            if ($null -eq $DriverVersion) {
                $DriverVersion = Split-Path $DriverDownload -Leaf
            }
            $DriverVersion = ($DriverVersion).replace('.zip','')
            $DriverVersion = ($DriverVersion).replace('win64_','')
            $DriverVersion = ($DriverVersion).replace('win32_','')
            $DriverVersion = ($DriverVersion).replace('dch_igcc_','')
            if ($DriverVersion -eq '15407.4279') {$DriverVersion = '15.40.7.4279'}
            if ($DriverVersion -eq '154014.4352') {$DriverVersion = '15.40.14.4352'}
            if ($DriverVersion -eq '152824') {$DriverVersion = '15.28.24.4229'}

            if ($DriverName -eq 'Intel Graphics MA') {
                $DriverWin7 = $true
                $DriverWin10 = $false
            } 
            if ($DriverName -eq 'Intel Graphics HD') {
                $DriverWin7 = $true
                $DriverWin10 = $false
            }
            if ($DriverName -eq 'Intel Graphics 15.33') {
                $DriverWin7 = $true
                $DriverWin10 = $true
            }
            if ($DriverName -eq 'Intel Graphics 15.36') {
                $DriverWin7 = $true
                $DriverWin10 = $false
            }
            if ($DriverName -eq 'Intel Graphics 15.40') {
                $DriverWin7 = $true
                $DriverWin10 = $true
            }
            if ($DriverName -eq 'Intel Graphics 15.45') {
                $DriverWin7 = $true
                $DriverWin10 = $false
            }
            if ($DriverName -eq 'Intel Graphics DCH') {
                $DriverWin7 = $false
                $DriverWin10 = $true
            }
            $DriverCab = "$DriverGroup $DriverVersion $DriverArch.cab"
            $DriverZip = "$DriverGroup $DriverVersion $DriverArch.zip"
            $DriverPnpXml = "$DriverGroup $DriverVersion $DriverArch.pnpxml"
            $DriverStatus = $null
            if (Test-Path "$DownloadPath\$DriverZip") {$DriverStatus = 'Downloaded'}
            if (Test-Path "$PackagePath\$DriverCab") {$DriverStatus = 'Packaged'}
            #===================================================================================================
            #   Create Object
            #===================================================================================================
            $ObjectProperties = @{
                DriverGroup         = $DriverGroup
                DriverClass         = $DriverClass
                DriverStatus        = $DriverStatus
                DriverName          = $DriverName
                DriverVersion       = $DriverVersion
                DriverArch          = $DriverArch
                Windows7            = $DriverWin7
                Windows10           = $DriverWin10
                DriverClassGUID     = $DriverClassGUID
                DriverPage          = $DriverPage
                DriverDownload      = $DriverDownload
                DriverZip           = $DriverZip
                DriverCab           = $DriverCab
                DriverPnpXml        = $DriverPnpXml
            }
            New-Object -TypeName PSObject -Property $ObjectProperties
        }
    }


    $DriverDownloads = $DriverDownloads | Sort-Object -Property DriverVersion -Descending | Select-Object DriverGroup,DriverClass,DriverStatus,DriverName,DriverVersion,DriverArch,Windows7,Windows10,DriverDownload,DriverClassGUID,DriverPage,DriverZip,DriverCab,DriverPnpXml

    $DriverDownloads | Export-Clixml "$DownloadPath\OSDCoreDrivers $DriverGroup.xml"
    $DriverDownloads | Export-Clixml "$PackagePath\OSDCoreDrivers $DriverGroup.xml"

    $DriverDownloads = $DriverDownloads | Out-GridView -PassThru -Title 'Select Driver Downloads to Package and press OK'

    #===================================================================================================
    #   Download
    #===================================================================================================
    foreach ($OSDDriverPNP in $DriverDownloads) {
        $DriverStatus = $($OSDDriverPNP.DriverStatus)
        $DriverGroup = $($OSDDriverPNP.DriverGroup)
        $DriverClass = $($OSDDriverPNP.DriverClass)
        $DriverClassGUID = $($OSDDriverPNP.DriverClassGUID)
        $DriverDownload = $($OSDDriverPNP.DriverDownload)

        $DriverCab = $($OSDDriverPNP.DriverCab)
        $DriverZip = $($OSDDriverPNP.DriverZip)
        $DriverPnpXml = $($OSDDriverPNP.DriverPnpXml)
        $DriverDirectory = ($DriverCab).replace('.cab','')
        $DriverPnpTxt = "$PackagePath\$DriverDirectory.txt"

        Write-Host "DriverDownload: $DriverDownload" -ForegroundColor Cyan
        Write-Host "DriverZip: $DownloadPath\$DriverZip" -ForegroundColor Gray

        if (Test-Path "$PackagePath\$DriverCab") {
            Write-Warning "$PackagePath\$DriverCab ... Exists!"
        } elseif (Test-Path "$DownloadPath\$DriverZip") {
            Write-Warning "$DownloadPath\$DriverZip ... Exists!"
        } else {
            Start-BitsTransfer -Source "$DriverDownload" -Destination "$DownloadPath\$DriverZip"
        }
        #===================================================================================================
        #   Expand
        #===================================================================================================
        if (-not(Test-Path "$PackagePath\$DriverCab")) {
            Write-Host "DriverDirectory: $DownloadPath\$DriverDirectory" -ForegroundColor Gray

            if (Test-Path "$DownloadPath\$DriverDirectory") {
                Write-Warning "$DownloadPath\$DriverDirectory ... Removing!"
                Remove-Item -Path "$DownloadPath\$DriverDirectory" -Recurse -Force | Out-Null
            }

            Write-Host "Expanding $DownloadPath\$DriverZip ..." -ForegroundColor Gray
            Expand-Archive -Path "$DownloadPath\$DriverZip" -DestinationPath "$DownloadPath\$DriverDirectory" -Force
        }

        if (Test-Path "$DownloadPath\$DriverDirectory") {
            $ExpandInfs = Get-ChildItem -Path "$DownloadPath\$DriverDirectory" -Recurse -Include *.inf -File | Where-Object {$_.Name -notlike "*autorun.inf*"} | Select-Object -Property FullName
            $CabDrivers = @()
            foreach ($ExpandInf in $ExpandInfs) {
                Write-Host "$($ExpandInf.FullName)" -ForegroundColor DarkGray
                $CabDrivers += Get-WindowsDriver -Online -Driver "$($ExpandInf.FullName)" | `
                Select-Object -Property Version,ManufacturerName,HardwareDescription,HardwareId,`
                Architecture,ServiceName,CompatibleIds,ExcludeIds,Driver,Inbox,CatalogFile,`
                ClassName,ClassGuid,ClassDescription,BootCritical,DriverSignature,ProviderName,`
                Date,MajorVersion,MinorVersion,Build,Revision
            }
            $CabDrivers = $CabDrivers | Where-Object {$_.ClassGuid -eq $DriverClassGUID}
            $CabDrivers = $CabDrivers | Sort-Object HardwareId
            #$CabDrivers | Out-GridView
            Write-Host "Generating $DownloadPath\$DriverPnpXml ..." -ForegroundColor Gray
            $CabDrivers | Export-Clixml -Path "$DownloadPath\$DriverPnpXml"
            Write-Host "Generating $PackagePath\$DriverPnpXml ..." -ForegroundColor Gray
            $CabDrivers | Export-Clixml -Path "$PackagePath\$DriverPnpXml"
        }

        if (-not(Test-Path "$PackagePath\$DriverCab")) {
            Write-Host "Creating $PackagePath\$DriverCab ..." -ForegroundColor Gray
            New-OSDriverCAB -Path "$DownloadPath\$DriverDirectory" -HighCompression -RemoveSource -DestinationFolder "$PackagePath"
        }
    }
    Write-Host "Complete!" -ForegroundColor Green
}