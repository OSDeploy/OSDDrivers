function Get-DriverDisplayIntel {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [string]$DownloadPath,
        [string]$PackagePath
    )
    #===================================================================================================
    #   Defaults DisplayIntel
    #===================================================================================================
    $Global:OSDInfoUrl = $null
    $Global:OSDDownloadUrl = 'https://downloadcenter.intel.com/product/80939/Graphics-Drivers'
    $Global:OSDPageUrl = $null
    $Global:OSDDownloadFileName = ''
    $Global:OSDDownloadMethod = 'BITS'
    $Global:DriverClass = 'Display'
    $Global:DriverClassGUID = '{4D36E968-E325-11CE-BFC1-08002BE10318}'
    #===================================================================================================
    #   OSDDownloadUrl
    #===================================================================================================
    Write-Host "Validating $OSDDownloadUrl" -ForegroundColor Cyan
    Write-Host ""
    #===================================================================================================
    #   Get DownloadPages
    #===================================================================================================
    $DownloadPages = @()
    $DownloadPages = (Invoke-WebRequest -Uri "$OSDDownloadUrl").Links
    #===================================================================================================
    #   Filter Results
    #===================================================================================================
    $DownloadPages = $DownloadPages | Select-Object -Property innerText, href
    $DownloadPages = $DownloadPages | Where-Object {$_.innerText -notlike "*Beta*"}
    $DownloadPages = $DownloadPages | Where-Object {$_.innerText -notlike "*embedded*"}
    $DownloadPages = $DownloadPages | Where-Object {$_.innerText -notlike "*exe*"}
    $DownloadPages = $DownloadPages | Where-Object {$_.innerText -notlike "*production*"}
    $DownloadPages = $DownloadPages | Where-Object {$_.innerText -notlike "*Radeon*"}
    $DownloadPages = $DownloadPages | Where-Object {$_.innerText -notlike "*Windows XP*"}
    $DownloadPages = $DownloadPages | Where-Object {$_.innerText -notlike "*XP32*"}
    $DownloadPages = $DownloadPages | Where-Object {$_.href -like "/download*"}

    foreach ($Link in $DownloadPages) {
        $Link.innerText = ($Link).innerText.replace('][',' ')
        $Link.innerText = $Link.innerText -replace '[[]', ''
        $Link.innerText = $Link.innerText -replace '[]]', ''
        $Link.innerText = $Link.innerText -replace '[®]', ''
        $Link.innerText = $Link.innerText -replace '[*]', ''
    }

    foreach ($Link in $DownloadPages) {
        if ($Link.innerText -like "*Graphics Media Accelerator*") {$Link.innerText = 'Intel Graphics MA'} #Win7
        if ($Link.innerText -like "*HD Graphics*") {$Link.innerText = 'Intel Graphics HD'} #Win7
        if ($Link.innerText -like "*15.33*") {$Link.innerText = 'Intel Graphics 15.33'} #Win7 #Win10
        if ($Link.innerText -like "*15.36*") {$Link.innerText = 'Intel Graphics 15.36'} #Win7
        if ($Link.innerText -like "*Intel Graphics Driver for Windows 15.40*") {$Link.innerText = 'Intel Graphics 15.40'} #Win7
        if ($Link.innerText -like "*15.40 6th Gen*") {$Link.innerText = 'Intel Graphics 15.40 G6'} #Win7
        if ($Link.innerText -like "*15.40 4th Gen*") {$Link.innerText = 'Intel Graphics 15.40 G4'} #Win10
        if ($Link.innerText -like "*15.45*") {$Link.innerText = 'Intel Graphics 15.45'} #Win7
        if ($Link.innerText -like "*DCH*") {$Link.innerText = 'Intel Graphics DCH'} #Win10
        $Link.href = "https://downloadcenter.intel.com$($Link.href)"
    }
    #===================================================================================================
    #   Exclude Drivers
    #===================================================================================================
    $DownloadPages = $DownloadPages | Where-Object {$_.innerText -notlike "*Intel Graphics 15.40 G4*"}
    $DownloadPages = $DownloadPages | Where-Object {$_.innerText -notlike "*Intel Graphics 15.40 G6*"}
    #===================================================================================================
    #   Return Downloads
    #===================================================================================================
    $UrlDownloads = @()
    $DriverDownloads = @()
    $DriverDownloads = foreach ($Link in $DownloadPages) {
        $DriverName = $($Link.innerText)
        Write-Host "$DriverName"

        $DriverPage = $($Link.href)
        Write-Host "$DriverPage" -ForegroundColor DarkGray
        #===================================================================================================
        #   Intel WebRequest
        #===================================================================================================
        $DriverPageContent = Invoke-WebRequest -Uri $DriverPage -Method Get
        $DriverPageContent = Invoke-webrequest -Uri $DriverPage -Method Get

        $DriverHTML = $DriverPageContent.ParsedHtml.childNodes | Where-Object {$_.nodename -eq 'HTML'} 
        $DriverHEAD = $DriverHTML.childNodes | Where-Object {$_.nodename -eq 'HEAD'}
        $DriverMETA = $DriverHEAD.childNodes | Where-Object {$_.nodename -like "meta*"}

        $DriverVersion = $DriverMETA | Where-Object {$_.name -eq 'DownloadVersion'} | Select-Object -ExpandProperty Content
        $DriverType = $DriverMETA | Where-Object {$_.name -eq 'DownloadType'} | Select-Object -ExpandProperty Content
        $DriverCompatibility = $DriverMETA | Where-Object {$_.name -eq 'DownloadOSes'} | Select-Object -ExpandProperty Content
        Write-Host "DriverCompatibility: $DriverCompatibility" -ForegroundColor DarkGray
        #===================================================================================================
        #   Driver Filter
        #===================================================================================================
        $UrlDownloads = ($DriverPageContent).Links
        $UrlDownloads = $UrlDownloads | Where-Object {$_.'data-direct-path' -like "*.zip"}
        #===================================================================================================
        #   Driver Details
        #===================================================================================================
        foreach ($UrlDownload in $UrlDownloads) {
            $OSVersionMin = $null
            $OSVersionMax = $null
            $OSArch = $null
            $DriverDownload = $UrlDownload.'data-direct-path'

            if ($null -eq $OSArch) {
                if (($DriverDownload -like "*win64*") -or ($DriverDownload -like "*Driver64*") -or ($DriverDownload -like "*64_*") -or ($DriverPage -like "*64-Bit*")) {
                    $OSArch = 'x64'
                } else {
                    $OSArch = 'x86'
                }
            }

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
                $OSArch = 'x64'
            }
            $DriverCab = "$DriverGroup $DriverVersion $OSArch.cab"
            $DriverZip = "$DriverGroup $DriverVersion $OSArch.zip"
            #===================================================================================================
            #   Driver Status
            #===================================================================================================
            $DriverStatus = $null
            if (Test-Path "$DownloadPath\$DriverZip") {$DriverStatus = 'Downloaded'}
            if (Test-Path "$DownloadPath\$DriverCab") {$DriverStatus = 'Packaged'}
            if (Test-Path "$PackagePath\$DriverCab") {$DriverStatus = 'Published'}
            #===================================================================================================
            #   Create Object
            #===================================================================================================
            $ObjectProperties = @{
                DriverGroup         = $DriverGroup
                DriverClass         = $DriverClass
                DriverStatus        = $DriverStatus
                LastUpdated         = $DriverMETA | Where-Object {$_.name -eq 'LastUpdate'} | Select-Object -ExpandProperty Content
                DriverName          = $DriverName
                DriverVersion       = $DriverVersion
                OSArch              = $OSArch
                OSVersionMin        = $OSVersionMin
                OSVersionMax        = $OSVersionMax
                Description         = $DriverMETA | Where-Object {$_.name -eq 'Description'} | Select-Object -ExpandProperty Content
                DriverClassGUID     = $DriverClassGUID
                DriverPage          = $DriverPage
                DriverDownload      = $DriverDownload
                DriverZip           = $DriverZip
                DriverCab           = $DriverCab
            }
            New-Object -TypeName PSObject -Property $ObjectProperties
        }
    }
    Write-Host "Exporting $env:Temp\OSDDrivers $DriverGroup.xml" -ForegroundColor Cyan
    $DriverDownloads | Export-Clixml "$env:Temp\OSDDrivers $DriverGroup.xml" -Force
    $DriverDownloads = $DriverDownloads | Sort-Object -Property LastUpdated -Descending | Select-Object DriverGroup,DriverClass,DriverStatus,LastUpdated,DriverName,DriverVersion,OSArch,OSVersionMin,OSVersionMax,Description,DriverDownload,DriverClassGUID,DriverPage,DriverZip,DriverCab

    $DriverDownloads | Export-Clixml "$DownloadPath\OSDDrivers $DriverGroup.xml"
    if ($PackagePath) {
        $DriverDownloads | Export-Clixml "$PackagePath\OSDDrivers $DriverGroup.xml"
    }

    $DriverDownloads = $DriverDownloads | Out-GridView -PassThru -Title 'Select Driver Downloads to Package and press OK'
    #Return $DriverDownloads
    
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
        if ($PackagePath) {
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
            if ( -not (Test-Path "$DownloadPath\$DriverCab")) {
                Write-Verbose "Creating $DownloadPath\$DriverCab ..." -Verbose
                New-OSDDriverCab -SourceDirectory "$DownloadPath\$DriverDirectory" -ShowOutput
            }
            #===================================================================================================
            #   Copy CAB
            #===================================================================================================
            if ( -not (Test-Path "$PackagePath\$DriverCab")) {
                Write-Verbose "Copying $DownloadPath\$DriverCab to $PackagePath\$DriverCab ..." -Verbose
                Copy-Item -Path "$DownloadPath\$DriverCab" -Destination "$PackagePath" -Force | Out-Null
            }
            #===================================================================================================
            #   OSDDriverTask
            #===================================================================================================
            Write-Host "Creating OSDDriverTask $DriverOSArch $DriverOSVersionMin $DriverOSVersionMax ..." -ForegroundColor Gray
            New-OSDDriverTask -DriverCab "$PackagePath\$DriverCab" -OSArch $DriverOSArch -OSVersionMin $DriverOSVersionMin -OSVersionMax $DriverOSVersionMax -MakeNotLike 'Microsoft'
            if (Test-Path "$OSDDriverPnp") {
                Copy-Item "$OSDDriverPnp" "$PackagePath" -Force
            }
        }
    }
}