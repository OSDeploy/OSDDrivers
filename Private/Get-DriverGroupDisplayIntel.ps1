function Get-DriverGroupDisplayIntel {
    [CmdletBinding()]
    Param ()
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
    Write-Verbose "Validating $OSDDownloadUrl" -Verbose
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
    #   Exclude DownloadPages
    #===================================================================================================
    $DownloadPages = $DownloadPages | Where-Object {$_.innerText -notlike "*Intel Graphics 15.40 G4*"}
    $DownloadPages = $DownloadPages | Where-Object {$_.innerText -notlike "*Intel Graphics 15.40 G6*"}
    #===================================================================================================
    #   Return Downloads
    #===================================================================================================
    $UrlDownloads = @()
    $OnlineOSDDriver = @()
    $OnlineOSDDriver = foreach ($Link in $DownloadPages) {
        $DriverName = $($Link.innerText)
        Write-Verbose "$DriverName" -Verbose

        $DriverPage = $($Link.href)
        Write-Verbose "$DriverPage" -Verbose
        #===================================================================================================
        #   Intel WebRequest
        #===================================================================================================
        $DriverPageContent = Invoke-WebRequest -Uri $DriverPage -Method Get

        $DriverHTML = $DriverPageContent.ParsedHtml.childNodes | Where-Object {$_.nodename -eq 'HTML'} 
        $DriverHEAD = $DriverHTML.childNodes | Where-Object {$_.nodename -eq 'HEAD'}
        $DriverMETA = $DriverHEAD.childNodes | Where-Object {$_.nodename -like "meta*"}

        $DriverVersion = $DriverMETA | Where-Object {$_.name -eq 'DownloadVersion'} | Select-Object -ExpandProperty Content
        $DriverType = $DriverMETA | Where-Object {$_.name -eq 'DownloadType'} | Select-Object -ExpandProperty Content
        $DriverCompatibility = $DriverMETA | Where-Object {$_.name -eq 'DownloadOSes'} | Select-Object -ExpandProperty Content
        Write-Verbose "DriverCompatibility: $DriverCompatibility" -Verbose
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
            $DriverURL = $UrlDownload.'data-direct-path'

            if ($null -eq $OSArch) {
                if (($DriverURL -like "*win64*") -or ($DriverURL -like "*Driver64*") -or ($DriverURL -like "*64_*") -or ($DriverPage -like "*64-Bit*")) {
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
            $OSDDriverName = "$DriverGroup $DriverVersion $OSArch"
            #===================================================================================================
            #   Create Object
            #===================================================================================================
            $ObjectProperties = @{
                OSDDriverStatus     = 'Online'
                OSDDriverName       = $OSDDriverName
                DriverGroup         = $DriverGroup
                DriverClass         = $DriverClass
                LastUpdated         = $DriverMETA | Where-Object {$_.name -eq 'LastUpdate'} | Select-Object -ExpandProperty Content
                DriverName          = $DriverName
                DriverVersion       = $DriverVersion
                OSArch              = $OSArch
                OSVersionMin        = $OSVersionMin
                OSVersionMax        = $OSVersionMax
                Description         = $DriverMETA | Where-Object {$_.name -eq 'Description'} | Select-Object -ExpandProperty Content
                DriverClassGUID     = $DriverClassGUID
                DriverPage          = $DriverPage
                DriverURL           = $DriverURL
                DriverZipFile       = "$OSDDriverName.zip"
                DriverCabFile       = "$OSDDriverName.cab"
            }
            New-Object -TypeName PSObject -Property $ObjectProperties
        }
    }
    $OnlineOSDDriver = $OnlineOSDDriver | Sort-Object -Property LastUpdated -Descending | Select-Object OSDDriverStatus,OSDDriverName,DriverGroup,DriverClass,LastUpdated,DriverName,DriverVersion,OSArch,OSVersionMin,OSVersionMax,DriverClassGUID,Description,DriverURL,DriverPage,DriverZipFile,DriverCabFile
    Return $OnlineOSDDriver
}