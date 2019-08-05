function Get-DriverIntelWireless {
    [CmdletBinding()]
    Param ()
    #===================================================================================================
    #   Uri
    #===================================================================================================
    $Uri = 'https://www.intel.com/content/www/us/en/support/articles/000017246/network-and-i-o/wireless-networking.html'
    #===================================================================================================
    #   DriverWebContentRaw
    #===================================================================================================
    $DriverWebContentRaw = @()
    try {
        $DriverWebContentRaw = (Invoke-WebRequest $Uri).Links
    }
    catch {
        Write-Error "Could not connect to $Uri" -ErrorAction Stop
    }
    #===================================================================================================
    #   DriverWebContent
    #===================================================================================================
    $DriverWebContent = @()
    $DriverWebContent = $DriverWebContentRaw
    #===================================================================================================
    #   Filter Results
    #===================================================================================================
    $DriverWebContent = $DriverWebContent | Select-Object -Property innerText, href
    $DriverWebContent = $DriverWebContent | Where-Object {$_.href -like "*downloadcenter.intel.com/download*"}
    $DriverWebContent = $DriverWebContent | Select-Object -First 1
    #===================================================================================================
    #   ForEach
    #===================================================================================================
    $UrlDownloads = @()
    $DriverResults = @()
    $DriverResults = foreach ($DriverLink in $DriverWebContent) {
        $DriverResultsName = $($DriverLink.innerText)
        Write-Host "Intel PROSet Wireless Software and Drivers for IT Admins $DriverResultsName " -ForegroundColor Cyan

        $DriverInfo = $($DriverLink.href)
        Write-Host "$DriverInfo" -ForegroundColor Gray
        #===================================================================================================
        #   Intel WebRequest
        #===================================================================================================
        $DriverInfoContent = Invoke-WebRequest -Uri $DriverInfo -Method Get

        $DriverHTML = $DriverInfoContent.ParsedHtml.childNodes | Where-Object {$_.nodename -eq 'HTML'} 
        $DriverHEAD = $DriverHTML.childNodes | Where-Object {$_.nodename -eq 'HEAD'}
        $DriverMETA = $DriverHEAD.childNodes | Where-Object {$_.nodename -like "meta*"}

<#         $DriverVersion = $DriverMETA | Where-Object {$_.name -eq 'DownloadVersion'} | Select-Object -ExpandProperty Content
        $DriverType = $DriverMETA | Where-Object {$_.name -eq 'DownloadType'} | Select-Object -ExpandProperty Content
        $DriverCompatibility = $DriverMETA | Where-Object {$_.name -eq 'DownloadOSes'} | Select-Object -ExpandProperty Content
        Write-Verbose "DriverCompatibility: $DriverCompatibility" -Verbose #>
        #===================================================================================================
        #   Driver Filter
        #===================================================================================================
        $UrlDownloads = ($DriverInfoContent).Links
        $UrlDownloads = $UrlDownloads | Where-Object {$_.'data-direct-path' -like "*.zip"}
        $UrlDownloads = $UrlDownloads | Where-Object {$_.innerText -notlike "*wifi*all*"}
        $UrlDownloads = $UrlDownloads | Where-Object {$_.innerText -notlike "*proset*"}
        #===================================================================================================
        #   Driver Details
        #===================================================================================================
        foreach ($UrlDownload in $UrlDownloads) {
            #===================================================================================================
            #   Defaults
            #===================================================================================================
            $LastUpdate = [datetime] $(Get-Date)
            $OSDVersion = $(Get-Module -Name OSDDrivers | Sort-Object Version | Select-Object Version -Last 1).Version
            $OSDStatus = $null
            $OSDGroup = 'IntelWireless'
            $OSDType = 'Driver'

            $DriverName = $null
            $DriverVersion = $null
            $DriverGrouping = $null

            $DriverFamilyChild = $null
            $DriverFamily = $null
            $DriverChild = $null

            $IsDesktop = $true
            $IsLaptop = $true
            $IsServer = $true

            $MakeLike = @()
            $MakeNotLike = @()
            $MakeMatch = @()
            $MakeNotMatch = @()

            $ModelLike = @()
            $ModelNotLike = @()
            $ModelMatch = @()
            $ModelNotMatch = @()
            $ModelEq = @()
            $ModelNe = @()

            $SystemFamilyMatch = @()
            $SystemFamilyNotMatch = @()

            $SystemSkuMatch = @()
            $SystemSkuNotMatch = @()

            $OSNameMatch = @()
            $OSNameNotMatch = @()
            $OSArchMatch = @()
            $OSArchNotMatch = @()

            $OSVersionMatch = @()
            $OSVersionNotMatch = @()
            $OSBuildGE = $null
            $OSBuildLE = $null
            $OSInstallationType = $null

            $OSDPnpClass = 'Net'
            $OSDPnpClassGuid = '{4D36E972-E325-11CE-BFC1-08002BE10318}'

            $DriverBundle = $null
            $DriverWeight = 100
            
            $DownloadFile = $null
            $OSDPnpFile = $null
            $OSDCabFile = $null
            $OSDTaskFile = $null
            $FileType = $null
            $SizeMB = $null
            $IsSuperseded = $false

            $DriverUrl = $null
            $DriverDescription = $null
            $DriverInfo = $DriverLink.href
            #$DriverCleanup = @()
            $OSDGuid = $(New-Guid)
            #===================================================================================================
            #   LastUpdate
            #===================================================================================================
            $LastUpdateRaw = $DriverMETA | Where-Object {$_.name -eq 'LastUpdate'} | Select-Object -ExpandProperty Content
            $LastUpdate = [datetime]::ParseExact($LastUpdateRaw, "MM/dd/yyyy HH:mm:ss", $null)
            #===================================================================================================
            #   DriverVersion
            #===================================================================================================
            $DriverVersion = $DriverMETA | Where-Object {$_.name -eq 'DownloadVersion'} | Select-Object -ExpandProperty Content
            #===================================================================================================
            #   DriverUrl
            #===================================================================================================
            $DriverUrl = $UrlDownload.'data-direct-path'
            #===================================================================================================
            #   OSArchMatch
            #===================================================================================================
            if (($DriverUrl -match 'Win64') -or ($DriverUrl -match 'Driver64') -or ($DriverUrl -match '64_') -or ($DriverInfo -match '64-Bit')) {
                $OSArchMatch = 'x64'
            } else {
                $OSArchMatch = 'x86'
            }
            #===================================================================================================
            #   DriverDescription
            #===================================================================================================
            $DriverDescription = $DriverMETA | Where-Object {$_.name -eq 'Description'} | Select-Object -ExpandProperty Content
            #===================================================================================================
            #   DownloadFile
            #===================================================================================================
            $DownloadFile = Split-Path $DriverUrl -Leaf
            #===================================================================================================
            #   FileType
            #===================================================================================================
            if ($DownloadFile -match 'cab') {$FileType = 'cab'}
            if ($DownloadFile -match 'zip') {$FileType = 'zip'}
            $FileType = $FileType.ToLower()
            #===================================================================================================
            #   OS
            #===================================================================================================
            if ($DownloadFile -match 'Win10') {
                $OSNameMatch = @('Win10')
                $OSVersionMatch = @('10.0')
            } 
            if ($DownloadFile -match 'Win8.1') {
                $OSNameMatch = @('Win8.1')
                $OSVersionMatch = @('6.3')
            }
            if ($DownloadFile -match 'Win7') {
                $OSNameMatch = @('Win7')
                $OSVersionMatch = @('6.1')
            }
            #===================================================================================================
            #   DriverName
            #===================================================================================================
            $DriverName = "$OSDGroup $DriverVersion $OSNameMatch $OSArchMatch"
            #===================================================================================================
            #   DriverGrouping
            #===================================================================================================
            $DriverGrouping = "Intel Wireless $OSNameMatch $OSArchMatch"
            #===================================================================================================
            #   OSDFiles
            #===================================================================================================
            $OSDPnpFile = "$($DriverName).drvpnp"
            $OSDCabFile = "$($DriverName).cab"
            $OSDTaskFile = "$($DriverName).drvpack"
            #===================================================================================================
            #   Create Object
            #===================================================================================================
            $ObjectProperties = @{
                LastUpdate              = [datetime] $LastUpdate
                OSDVersion              = [string] $OSDVersion
                OSDStatus               = [string] $OSDStatus
                OSDGroup                = [string] $OSDGroup
                OSDType                 = [string] $OSDType
    
                DriverName              = [string] $DriverName
                DriverVersion           = [string] $DriverVersion
                DriverGrouping          = [string] $DriverGrouping
    
                DriverFamilyChild       = [string] $DriverFamilyChild
                DriverFamily            = [string] $DriverFamily
                DriverChild             = [string] $DriverChild

                IsDesktop               = [bool]$IsDesktop
                IsLaptop                = [bool]$IsLaptop
                IsServer                = [bool]$IsServer
    
                MakeLike                = [array[]] $MakeLike
                MakeNotLike             = [array[]] $MakeNotLike
                MakeMatch               = [array[]] $MakeMatch
                MakeNotMatch            = [array[]] $MakeNotMatch
    
                ModelLike               = [array[]] $ModelLike
                ModelNotLike            = [array[]] $ModelNotLike
                ModelMatch              = [array[]] $ModelMatch
                ModelNotMatch           = [array[]] $ModelNotMatch
                ModelEq                 = [array[]] $ModelEq
                ModelNe                 = [array[]] $ModelNe
    
                SystemFamilyMatch       = [array[]] $SystemFamilyMatch
                SystemFamilyNotMatch    = [array[]] $SystemFamilyNotMatch
    
                SystemSkuMatch          = [array[]] $SystemSkuMatch
                SystemSkuNotMatch       = [array[]] $SystemSkuNotMatch
    
                OSNameMatch             = [array[]] $OSNameMatch
                OSNameNotMatch          = [array[]] $OSNameNotMatch
                OSArchMatch             = [array[]] $OSArchMatch
                OSArchNotMatch          = [array[]] $OSArchNotMatch
    
                OSVersionMatch          = [array[]] $OSVersionMatch
                OSVersionNotMatch       = [array[]] $OSVersionNotMatch
                OSBuildGE               = [string] $OSBuildGE
                OSBuildLE               = [string] $OSBuildLE
                OSInstallationType      = [string]$OSInstallationType
    
                OSDPnpClass             = [string] $OSDPnpClass
                OSDPnpClassGuid         = [string] $OSDPnpClassGuid
    
                DriverBundle            = [string] $DriverBundle
                DriverWeight            = [int] $DriverWeight
    
                DownloadFile            = [string] $DownloadFile
                OSDPnpFile              = [string] $OSDPnpFile
                OSDCabFile          = [string] $OSDCabFile
                OSDTaskFile             = [string] $OSDTaskFile
                FileType                = [string] $FileType
                SizeMB                  = [int] $SizeMB
                IsSuperseded            = [bool] $IsSuperseded
    
                DriverUrl               = [string] $DriverUrl
                DriverDescription       = [string] $DriverDescription
                DriverInfo              = [string] $DriverInfo
                DriverCleanup           = [array] $DriverCleanup
                OSDGuid                 = [string] $(New-Guid)
            }
            New-Object -TypeName PSObject -Property $ObjectProperties
        }
    }
    #===================================================================================================
    #   Select-Object
    #===================================================================================================
    $DriverResults = $DriverResults | Select-Object LastUpdate, `
    OSDVersion,OSDStatus,OSDGroup,OSDType,`
    DriverName, DriverVersion, DriverGrouping,`
    #OSNameMatch,`
    OSVersionMatch, OSArchMatch,`
    #DriverFamilyChild, DriverFamily, DriverChild,`
    #IsDesktop,IsLaptop,IsServer,`
    #MakeLike, MakeNotLike,`
    #MakeMatch, MakeNotMatch,`
    #ModelLike, ModelNotLike, ModelMatch, ModelNotMatch, ModelEq, ModelNe,`
    #SystemFamilyMatch, SystemFamilyNotMatch,`
    #SystemSkuMatch, SystemSkuNotMatch,`
    #OSNameNotMatch, OSArchNotMatch, OSVersionNotMatch, OSBuildGE, OSBuildLE,`
    #OSInstallationType,`
    OSDPnpClass,OSDPnpClassGuid,`
    #DriverBundle, DriverWeight,`
    DownloadFile,`
    #OSDPnpFile, OSDCabFile, OSDTaskFile,`
    #FileType,`
    #SizeMB,`
    #IsSuperseded,`
    DriverUrl, DriverDescription, DriverInfo,`
    #DriverCleanup,`
    OSDGuid
    #===================================================================================================
    #   Sort-Object
    #===================================================================================================
    $DriverResults = $DriverResults | Sort-Object -Property LastUpdate -Descending
    #===================================================================================================
    #   Return
    #===================================================================================================
    Return $DriverResults
    #===================================================================================================
}