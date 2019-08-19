<#
.SYNOPSIS
Returns a Intel Display Driver Object

.DESCRIPTION
Returns a Intel Display Driver Object
Requires BITS for downloading the Downloads
Requires Internet access for downloading the Downloads

.LINK
https://osddrivers.osdeploy.com/functions/get-driverinteldisplay
#>
function Get-DriverIntelDisplay {
    [CmdletBinding()]
    Param ()
    #===================================================================================================
    #   Uri
    #===================================================================================================
    $Uri = 'https://downloadcenter.intel.com/product/80939/Graphics-Drivers'
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
    $DriverWebContent = $DriverWebContent | Where-Object {$_.innerText -notlike "*Beta*"}
    $DriverWebContent = $DriverWebContent | Where-Object {$_.innerText -notlike "*embedded*"}
    $DriverWebContent = $DriverWebContent | Where-Object {$_.innerText -notlike "*exe*"}
    $DriverWebContent = $DriverWebContent | Where-Object {$_.innerText -notlike "*production*"}
    $DriverWebContent = $DriverWebContent | Where-Object {$_.innerText -notlike "*Radeon*"}
    $DriverWebContent = $DriverWebContent | Where-Object {$_.innerText -notlike "*Windows XP*"}
    $DriverWebContent = $DriverWebContent | Where-Object {$_.innerText -notlike "*XP32*"}
    $DriverWebContent = $DriverWebContent | Where-Object {$_.href -like "/download*"}

    foreach ($DriverLink in $DriverWebContent) {
        $DriverLink.innerText = ($DriverLink).innerText.replace('][',' ')
        $DriverLink.innerText = $DriverLink.innerText -replace '[[]', ''
        $DriverLink.innerText = $DriverLink.innerText -replace '[]]', ''
        $DriverLink.innerText = $DriverLink.innerText -replace '[®]', ''
        $DriverLink.innerText = $DriverLink.innerText -replace '[*]', ''
    }

    foreach ($DriverLink in $DriverWebContent) {
        if ($DriverLink.innerText -like "*Graphics Media Accelerator*") {$DriverLink.innerText = 'Intel Graphics MA'} #Win7
        if ($DriverLink.innerText -like "*HD Graphics*") {$DriverLink.innerText = 'Intel Graphics HD'} #Win7
        if ($DriverLink.innerText -like "*15.33*") {$DriverLink.innerText = 'Intel Graphics 15.33'} #Win7 #Win10
        if ($DriverLink.innerText -like "*15.36*") {$DriverLink.innerText = 'Intel Graphics 15.36'} #Win7
        if ($DriverLink.innerText -like "*Intel Graphics Driver for Windows 15.40*") {$DriverLink.innerText = 'Intel Graphics 15.40'} #Win7
        if ($DriverLink.innerText -like "*15.40 6th Gen*") {$DriverLink.innerText = 'Intel Graphics 15.40 G6'} #Win7
        if ($DriverLink.innerText -like "*15.40 4th Gen*") {$DriverLink.innerText = 'Intel Graphics 15.40 G4'} #Win10
        if ($DriverLink.innerText -like "*15.45*") {$DriverLink.innerText = 'Intel Graphics 15.45'} #Win7
        if ($DriverLink.innerText -like "*DCH*") {$DriverLink.innerText = 'Intel Graphics DCH'} #Win10
        $DriverLink.href = "https://downloadcenter.intel.com$($DriverLink.href)"
    }

    $DriverWebContent = $DriverWebContent | Where-Object {$_.innerText -notlike "*Intel Graphics 15.40 G4*"}
    $DriverWebContent = $DriverWebContent | Where-Object {$_.innerText -notlike "*Intel Graphics 15.40 G6*"}
    #===================================================================================================
    #   ForEach
    #===================================================================================================
    $UrlDownloads = @()
    $DriverResults = @()
    $DriverResults = foreach ($DriverLink in $DriverWebContent) {
        $DriverResultsName = $($DriverLink.innerText)
        Write-Host "$DriverResultsName " -ForegroundColor Cyan -NoNewline

        $DriverInfo = $($DriverLink.href)
        Write-Host "$DriverInfo" -ForegroundColor Gray
        #===================================================================================================
        #   Intel WebRequest
        #===================================================================================================
        $DriverInfoContent = Invoke-WebRequest -Uri $DriverInfo -Method Get

        $DriverHTML = $DriverInfoContent.ParsedHtml.childNodes | Where-Object {$_.nodename -eq 'HTML'} 
        $DriverHEAD = $DriverHTML.childNodes | Where-Object {$_.nodename -eq 'HEAD'}
        $DriverMETA = $DriverHEAD.childNodes | Where-Object {$_.nodename -like "meta*"}

        #$DriverType = $DriverMETA | Where-Object {$_.name -eq 'DownloadType'} | Select-Object -ExpandProperty Content
        #$DriverCompatibility = $DriverMETA | Where-Object {$_.name -eq 'DownloadOSes'} | Select-Object -ExpandProperty Content
        #Write-Verbose "DriverCompatibility: $DriverCompatibility" -Verbose
        #===================================================================================================
        #   Driver Filter
        #===================================================================================================
        $UrlDownloads = ($DriverInfoContent).Links
        $UrlDownloads = $UrlDownloads | Where-Object {$_.'data-direct-path' -like "*.zip"}
        #===================================================================================================
        #   Driver Details
        #===================================================================================================
        foreach ($UrlDownload in $UrlDownloads) {
            #===================================================================================================
            #   Defaults
            #===================================================================================================
            $OSDVersion = $(Get-Module -Name OSDDrivers | Sort-Object Version | Select-Object Version -Last 1).Version
            $LastUpdate = [datetime] $(Get-Date)
            $OSDStatus = $null
            $OSDGroup = 'IntelDisplay'
            $OSDType = 'Driver'

            $DriverName = $null
            $DriverVersion = $null
            $DriverReleaseId = $null
            $DriverGrouping = $null

            $OperatingSystem = @()
            $OsVersion = @()
            $OsArch = @()
            $OsBuildMax = @()
            $OsBuildMin = @()
    
            $Make = @()
            $MakeNe = @()
            $MakeLike = @()
            $MakeNotLike = @()
            $MakeMatch = @()
            $MakeNotMatch = @('Microsoft')
    
            $Generation = $null
            $SystemFamily = $null
    
            $Model = @()
            $ModelNe = @()
            $ModelLike = @()
            $ModelNotLike = @()
            $ModelMatch = @()
            $ModelNotMatch = @('Surface')
    
            $SystemSku = @()
            $SystemSkuNe = @()
    
            $DriverBundle = $null
            $DriverWeight = 100
    
            $DownloadFile = $null
            $SizeMB = $null
            $DriverUrl = $null
            $DriverInfo = $null
            $DriverDescription = $null
            $Hash = $null
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
            #   OsArch
            #===================================================================================================
            if (($DriverUrl -match 'Win64') -or ($DriverUrl -match 'Driver64') -or ($DriverUrl -match '64_') -or ($DriverInfo -match '64-Bit')) {
                $OsArch = 'x64'
            } else {
                $OsArch = 'x86'
            }
            #===================================================================================================
            #   OS
            #===================================================================================================
            if ($DriverResultsName -eq 'Intel Graphics MA') {
                $OsVersion = @('6.1')
            } 
            if ($DriverResultsName -eq 'Intel Graphics HD') {
                $OsVersion = @('6.1','6.3')
            }
            if ($DriverResultsName -eq 'Intel Graphics 15.33') {
                $OsVersion = @('6.1','6.3','10.0')
            }
            if ($DriverResultsName -eq 'Intel Graphics 15.36') {
                $OsVersion = @('6.1','6.3')
            }
            if ($DriverResultsName -eq 'Intel Graphics 15.40') {
                $OsVersion = @('6.1','6.3','10.0')
            }
            if ($DriverResultsName -eq 'Intel Graphics 15.45') {
                $OsVersion = @('6.1','6.3')
            }
            if ($DriverResultsName -eq 'Intel Graphics DCH') {
                $OsVersion = @('10.0')
                $OsArch = 'x64'
            }
            #===================================================================================================
            #   Values
            #===================================================================================================
            $DriverName = "$OSDGroup $DriverVersion $OsArch $OsVersion"
            $DriverGrouping = "$DriverResultsName $OsArch $OsVersion"
            $DriverDescription = $DriverMETA | Where-Object {$_.name -eq 'Description'} | Select-Object -ExpandProperty Content
            $DriverInfo = $DriverLink.href
            $DownloadFile = Split-Path $DriverUrl -Leaf
            $OSDPnpClass = 'Display'
            $OSDPnpClassGuid = '{4D36E968-E325-11CE-BFC1-08002BE10318}'
            #===================================================================================================
            #   Create Object
            #===================================================================================================
            $ObjectProperties = @{
                OSDVersion              = [string] $OSDVersion
                LastUpdate              = [datetime] $LastUpdate
                OSDStatus               = [string] $OSDStatus
                OSDType                 = [string] $OSDType
                OSDGroup                = [string] $OSDGroup
    
                DriverName              = [string] $DriverName
                DriverVersion           = [string] $DriverVersion
                DriverReleaseId         = [string] $DriverReleaseID
    
                OperatingSystem         = [array] $OperatingSystem
                OsVersion               = [string[]] $OsVersion
                OsArch                  = [array[]] $OsArch
                OsBuildMax              = [string] $OsBuildMax
                OsBuildMin              = [string] $OsBuildMin
    
                Make                    = [array[]] $Make
                MakeNe                  = [array[]] $MakeNe
                MakeLike                = [array[]] $MakeLike
                MakeNotLike             = [array[]] $MakeNotLike
                MakeMatch               = [array[]] $MakeMatch
                MakeNotMatch            = [array[]] $MakeNotMatch
    
                Generation              = [string] $Generation
                SystemFamily            = [string] $SystemFamily
    
                Model                   = [array[]] $Model
                ModelNe                 = [array[]] $ModelNe
                ModelLike               = [array[]] $ModelLike
                ModelNotLike            = [array[]] $ModelNotLike
                ModelMatch              = [array[]] $ModelMatch
                ModelNotMatch           = [array[]] $ModelNotMatch
    
                SystemSku               = [array[]] $SystemSku
                SystemSkuNe             = [array[]] $SystemSkuNe
    
                SystemFamilyMatch       = [array[]] $SystemFamilyMatch
                SystemFamilyNotMatch    = [array[]] $SystemFamilyNotMatch
    
                SystemSkuMatch          = [array[]] $SystemSkuMatch
                SystemSkuNotMatch       = [array[]] $SystemSkuNotMatch
    
                DriverGrouping          = [string] $DriverGrouping
                DriverBundle            = [string] $DriverBundle
                DriverWeight            = [int] $DriverWeight
    
                DownloadFile            = [string] $DownloadFile
                SizeMB                  = [int] $SizeMB
                DriverUrl               = [string] $DriverUrl
                DriverInfo              = [string] $DriverInfo
                DriverDescription       = [string] $DriverDescription
                Hash                    = [string] $Hash
                OSDGuid                 = [string] $OSDGuid
    
                OSDPnpClass             = [string] $OSDPnpClass
                OSDPnpClassGuid         = [string] $OSDPnpClassGuid
            }
            New-Object -TypeName PSObject -Property $ObjectProperties
        }
    }
    #===================================================================================================
    #   Select-Object
    #===================================================================================================
    $DriverResults = $DriverResults | Select-Object OSDVersion, LastUpdate, OSDStatus, OSDType, OSDGroup,`
    DriverName, DriverVersion,`
    OsVersion, OsArch, MakeNotMatch, ModelNotMatch,`
    DriverGrouping,`
    DownloadFile, DriverUrl, DriverInfo, DriverDescription,`
    OSDGuid,`
    OSDPnpClass, OSDPnpClassGuid
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