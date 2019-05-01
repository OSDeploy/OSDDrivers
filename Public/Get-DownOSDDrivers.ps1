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
            $OSVersionMin = $null
            $OSVersionMax = $null
            $OSArch = $null
            $DriverDownload = $UrlDownload.'data-direct-path'

            if ($DriverPage -eq 'https://downloadcenter.intel.com/download/22520/Graphics-Intel-Graphics-Media-Accelerator-Driver-for-Windows-7-Windows-Vista-64-Bit-zip-?product=80939') {
                $DriverVersion = '15.22.58.2993'
                $OSVersionMin = $true
                $OSArch = 'x64'
            }
            if ($DriverPage -eq 'https://downloadcenter.intel.com/download/22518/Intel-Graphics-Media-Accelerator-Driver-Windows-7-and-Windows-Vista-zip-?product=80939') {
                $DriverVersion = '15.22.58.2993'
                $OSVersionMin = $true
                $OSArch = 'x86'
            }

            if ($null -eq $OSArch) {
                if ($DriverDownload -like "*win64*") {
                    $OSArch = 'x64'
                } else {
                    $OSArch = 'x86'
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
                $OSVersionMin = '6.1'
                $OSVersionMax = '6.1'
            } 
            if ($DriverName -eq 'Intel Graphics HD') {
                $OSVersionMin = '6.1'
                $OSVersionMax = '6.3'
            }
            if ($DriverName -eq 'Intel Graphics 15.33') {
                $OSVersionMin = '6.1'
                $OSVersionMax = '10.0'
            }
            if ($DriverName -eq 'Intel Graphics 15.36') {
                $OSVersionMin = '6.1'
                $OSVersionMax = '6.3'
            }
            if ($DriverName -eq 'Intel Graphics 15.40') {
                $OSVersionMin = '6.1'
                $OSVersionMax = '10.0'
            }
            if ($DriverName -eq 'Intel Graphics 15.45') {
                $OSVersionMin = '6.1'
                $OSVersionMax = '6.3'
            }
            if ($DriverName -eq 'Intel Graphics DCH') {
                $OSVersionMin = '10.0'
                $OSVersionMax = '10.0'
            }
            $DriverCab = "$DriverGroup $DriverVersion $OSArch.cab"
            $DriverZip = "$DriverGroup $DriverVersion $OSArch.zip"
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
                OSArch              = $OSArch
                OSVersionMin        = $OSVersionMin
                OSVersionMax        = $OSVersionMax
                DriverClassGUID     = $DriverClassGUID
                DriverPage          = $DriverPage
                DriverDownload      = $DriverDownload
                DriverZip           = $DriverZip
                DriverCab           = $DriverCab
            }
            New-Object -TypeName PSObject -Property $ObjectProperties
        }
    }


    $DriverDownloads = $DriverDownloads | Sort-Object -Property DriverVersion -Descending | Select-Object DriverGroup,DriverClass,DriverStatus,DriverName,DriverVersion,OSArch,OSVersionMin,OSVersionMax,DriverDownload,DriverClassGUID,DriverPage,DriverZip,DriverCab

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
        $DriverOSArch = $($SelectedDriverDownload.OSArch)
        $DriverOSVersionMin = $($SelectedDriverDownload.OSVersionMin)
        $DriverOSVersionMax = $($SelectedDriverDownload.OSVersionMax)

        $DriverCab = $($SelectedDriverDownload.DriverCab)
        $DriverZip = $($SelectedDriverDownload.DriverZip)
        $DriverDirectory = ($DriverCab).replace('.cab','')

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
        #   Need to add logic to unzip if necessary
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
        #   OSDDriverPnp
        #===================================================================================================
        if (Test-Path "$DownloadPath\$DriverDirectory") {
            $OSDDriverPnp = (New-OSDDriverPnp -DriverDirectory "$DownloadPath\$DriverDirectory" -DriverClass $DriverClass)
        }
        #===================================================================================================
        #   Create CAB
        #===================================================================================================
        if (-not(Test-Path "$PackagePath\$DriverCab")) {
            Write-Host "Creating $PackagePath\$DriverCab ..." -ForegroundColor Gray
            New-OSDDriverCab -SourceDirectory "$DownloadPath\$DriverDirectory" -DestinationDirectory "$PackagePath" -ShowOutput
        }

        #===================================================================================================
        #   OSDDriverTask
        #===================================================================================================
        Write-Host "Creating OSDDriverTask $DriverOSArch $DriverOSVersionMin $DriverOSVersionMax ..." -ForegroundColor Gray
        New-OSDDriverTask -DriverCab "$PackagePath\$DriverCab" -OSArch $DriverOSArch -OSVersionMin $DriverOSVersionMin -OSVersionMax $DriverOSVersionMax
        if (Test-Path "$OSDDriverPnp") {
            Copy-Item "$OSDDriverPnp" "$PackagePath" -Force
        }


    }
    Write-Host "Complete!" -ForegroundColor Green
}