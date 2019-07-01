function Get-OnlineOSDDriverWirelessIntel {
    [CmdletBinding()]
    Param ()
    #===================================================================================================
    #   Defaults WirelessIntel
    #===================================================================================================
    $Global:OSDInfoUrl = $null
    $Global:OSDDownloadUrl = 'https://www.intel.com/content/www/us/en/support/articles/000017246/network-and-i-o/wireless-networking.html'
    $Global:OSDPageUrl = $null
    $Global:OSDDownloadFileName = ''
    $Global:OSDDownloadMethod = 'BITS'
    $Global:DriverClass = 'Net'
    $Global:DriverClassGUID = '{4D36E972-E325-11CE-BFC1-08002BE10318}'
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
    $DownloadPages = $DownloadPages | Where-Object {$_.href -like "*downloadcenter.intel.com/download*"}
    $DownloadPages = $DownloadPages | Select-Object -First 1
    #===================================================================================================
    #   Exclude DownloadPages
    #===================================================================================================
    #===================================================================================================
    #   Return Downloads
    #===================================================================================================
    $UrlDownloads = @()
    $OnlineOSDDriver = @()
    $OnlineOSDDriver = foreach ($Link in $DownloadPages) {
        $DriverName = $($Link.innerText)
        Write-Verbose "Intel PROSet Wireless Software and Drivers for IT Admins $DriverName" -Verbose

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
        $UrlDownloads = $UrlDownloads | Where-Object {$_.innerText -notlike "*wifi*all*"}
        $UrlDownloads = $UrlDownloads | Where-Object {$_.innerText -notlike "*proset*"}
        #===================================================================================================
        #   Driver Details
        #===================================================================================================
        foreach ($UrlDownload in $UrlDownloads) {
            $OSVersionMin = $null
            $OSVersionMax = $null
            $OSArch = $null
            $OnlineDriver = $UrlDownload.'data-direct-path'

            if ($null -eq $OSArch) {
                if (($OnlineDriver -like "*win64*") -or ($OnlineDriver -like "*Driver64*") -or ($OnlineDriver -like "*64_*") -or ($DriverPage -like "*64-Bit*")) {
                    $OSArch = 'x64'
                } else {
                    $OSArch = 'x86'
                }
            }

            if ($OnlineDriver -like "*Win7*") {
                $OSVersionMin = '6.1'
                $OSVersionMax = '6.1'
                $DriverName = "$DriverGroup $DriverVersion $OSArch Win7"
            }
            if ($OnlineDriver -like "*Win8.1*") {
                $OSVersionMin = '6.3'
                $OSVersionMax = '6.3'
                $DriverName = "$DriverGroup $DriverVersion $OSArch Win8.1"
            }
            if ($OnlineDriver -like "*Win10*") {
                $OSVersionMin = '10.0'
                $OSVersionMax = '10.0'
                $DriverName = "$DriverGroup $DriverVersion $OSArch Win10"
            }
            $DriverCabFile = "$DriverName.cab"
            $DriverZipFile = "$DriverName.zip"
            #===================================================================================================
            #   Create Object
            #===================================================================================================
            $ObjectProperties = @{
                OSDDriverStatus     = 'Online'
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
                OnlineDriver      = $OnlineDriver
                DriverZipFile       = $DriverZipFile
                DriverCabFile       = $DriverCabFile
            }
            New-Object -TypeName PSObject -Property $ObjectProperties
        }
    }
    $OnlineOSDDriver = $OnlineOSDDriver | Sort-Object -Property LastUpdated -Descending | Select-Object OSDDriverStatus,DriverGroup,DriverClass,LastUpdated,DriverName,DriverVersion,OSArch,OSVersionMin,OSVersionMax,DriverClassGUID,Description,OnlineDriver,DriverPage,DriverZipFile,DriverCabFile
    Return $OnlineOSDDriver
}