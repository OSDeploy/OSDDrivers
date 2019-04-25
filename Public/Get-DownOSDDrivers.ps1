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
            $CompatWin7 = $null
            $CompatWin10 = $null
            $CompatArch = $null
            $DriverDownload = $UrlDownload.'data-direct-path'

            if ($DriverPage -eq 'https://downloadcenter.intel.com/download/22520/Graphics-Intel-Graphics-Media-Accelerator-Driver-for-Windows-7-Windows-Vista-64-Bit-zip-?product=80939') {
                $DriverVersion = '15.22.58.2993'
                $CompatWin7 = $true
                $CompatArch = 'x64'
            }
            if ($DriverPage -eq 'https://downloadcenter.intel.com/download/22518/Intel-Graphics-Media-Accelerator-Driver-Windows-7-and-Windows-Vista-zip-?product=80939') {
                $DriverVersion = '15.22.58.2993'
                $CompatWin7 = $true
                $CompatArch = 'x86'
            }

            if ($null -eq $CompatArch) {
                if ($DriverDownload -like "*win64*") {
                    $CompatArch = 'x64'
                } else {
                    $CompatArch = 'x86'
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
                $CompatWin7 = $true
                $CompatWin10 = $false
            } 
            if ($DriverName -eq 'Intel Graphics HD') {
                $CompatWin7 = $true
                $CompatWin10 = $false
            }
            if ($DriverName -eq 'Intel Graphics 15.33') {
                $CompatWin7 = $true
                $CompatWin10 = $true
            }
            if ($DriverName -eq 'Intel Graphics 15.36') {
                $CompatWin7 = $true
                $CompatWin10 = $false
            }
            if ($DriverName -eq 'Intel Graphics 15.40') {
                $CompatWin7 = $true
                $CompatWin10 = $true
            }
            if ($DriverName -eq 'Intel Graphics 15.45') {
                $CompatWin7 = $true
                $CompatWin10 = $false
            }
            if ($DriverName -eq 'Intel Graphics DCH') {
                $CompatWin7 = $false
                $CompatWin10 = $true
            }
            $DriverCab = "$DriverGroup $DriverVersion $CompatArch.cab"
            $DriverZip = "$DriverGroup $DriverVersion $CompatArch.zip"
            $DriverXmlPnp = "$DriverGroup $DriverVersion $CompatArch.xmlpnp"
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
                CompatArch          = $CompatArch
                CompatWin7          = $CompatWin7
                CompatWin10         = $CompatWin10
                DriverClassGUID     = $DriverClassGUID
                DriverPage          = $DriverPage
                DriverDownload      = $DriverDownload
                DriverZip           = $DriverZip
                DriverCab           = $DriverCab
                DriverXmlPnp        = $DriverXmlPnp
            }
            New-Object -TypeName PSObject -Property $ObjectProperties
        }
    }


    $DriverDownloads = $DriverDownloads | Sort-Object -Property DriverVersion -Descending | Select-Object DriverGroup,DriverClass,DriverStatus,DriverName,DriverVersion,CompatArch,CompatWin7,CompatWin10,DriverDownload,DriverClassGUID,DriverPage,DriverZip,DriverCab,DriverXmlPnp

    $DriverDownloads | Export-Clixml "$DownloadPath\OSDDrivers $DriverGroup.xml"
    $DriverDownloads | Export-Clixml "$PackagePath\OSDDrivers $DriverGroup.xml"

    $DriverDownloads = $DriverDownloads | Out-GridView -PassThru -Title 'Select Driver Downloads to Package and press OK'

    #===================================================================================================
    #   Download
    #===================================================================================================
    foreach ($SelectedDriverDownload in $DriverDownloads) {
        $DriverStatus = $($SelectedDriverDownload.DriverStatus)
        $DriverGroup = $($SelectedDriverDownload.DriverGroup)
        $DriverClass = $($SelectedDriverDownload.DriverClass)
        $DriverClassGUID = $($SelectedDriverDownload.DriverClassGUID)
        $DriverDownload = $($SelectedDriverDownload.DriverDownload)
        $CompatWin7 = $($SelectedDriverDownload.CompatWin7)
        $CompatWin10 = $($SelectedDriverDownload.CompatWin10)

        $DriverCab = $($SelectedDriverDownload.DriverCab)
        $DriverZip = $($SelectedDriverDownload.DriverZip)
        $DriverXmlPnp = $($SelectedDriverDownload.DriverXmlPnp)
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
        #   Expand Zip
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

        #===================================================================================================
        #   Create XML
        #===================================================================================================
        if (Test-Path "$DownloadPath\$DriverDirectory") {
            if ($CompatWin7 -eq $true -and $CompatWin10 -eq $false) {
                New-OSDDriversXml -DriverDirectory "$DownloadPath\$DriverDirectory" -CompatArch $CompatArch -CompatClient 'Windows7' -DriverClass $DriverClass
            } elseif ($CompatWin7 -eq $false -and $CompatWin10 -eq $true) {
                New-OSDDriversXml -DriverDirectory "$DownloadPath\$DriverDirectory" -CompatArch $CompatArch -CompatClient 'Windows10' -DriverClass $DriverClass
            } else {
                New-OSDDriversXml -DriverDirectory "$DownloadPath\$DriverDirectory" -CompatArch $CompatArch -DriverClass $DriverClass
            }
        }

        #===================================================================================================
        #   Create CAB
        #===================================================================================================
        if (-not(Test-Path "$PackagePath\$DriverCab")) {
            Write-Host "Creating $PackagePath\$DriverCab ..." -ForegroundColor Gray
            New-OSDDriversCab -SourceDirectory "$DownloadPath\$DriverDirectory" -DestinationDirectory "$PackagePath"
        }
    }
    Write-Host "Complete!" -ForegroundColor Green
}