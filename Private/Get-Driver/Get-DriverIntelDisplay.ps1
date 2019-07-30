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
            $LastUpdate = [datetime] $(Get-Date)
            $OSDVersion = $(Get-Module -Name OSDDrivers | Sort-Object Version | Select-Object Version -Last 1).Version
            $OSDStatus = $null
            $OSDGroup = 'IntelDisplay'
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
            $MakeNotMatch = @('Microsoft')

            $ModelLike = @()
            $ModelNotLike = @()
            $ModelMatch = @()
            $ModelNotMatch = @('Surface')
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

            $OSDPnpClass = 'Display'
            $OSDPnpClassGuid = '{4D36E968-E325-11CE-BFC1-08002BE10318}'

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
            #   OS
            #===================================================================================================
            if ($DriverResultsName -eq 'Intel Graphics MA') {
                $OSNameMatch = @('Win7')
                $OSVersionMatch = @('6.1')
            } 
            if ($DriverResultsName -eq 'Intel Graphics HD') {
                $OSNameMatch = @('Win7','Win8.1')
                $OSVersionMatch = @('6.1','6.3')
            }
            if ($DriverResultsName -eq 'Intel Graphics 15.33') {
                $OSNameMatch = @('Win7','Win8.1','Win10')
                $OSVersionMatch = @('6.1','6.3','10.0')
            }
            if ($DriverResultsName -eq 'Intel Graphics 15.36') {
                $OSNameMatch = @('Win7','Win8.1')
                $OSVersionMatch = @('6.1','6.3')
            }
            if ($DriverResultsName -eq 'Intel Graphics 15.40') {
                $OSNameMatch = @('Win7','Win8.1','Win10')
                $OSVersionMatch = @('6.1','6.3','10.0')
            }
            if ($DriverResultsName -eq 'Intel Graphics 15.45') {
                $OSNameMatch = @('Win7','Win8.1')
                $OSVersionMatch = @('6.1','6.3')
            }
            if ($DriverResultsName -eq 'Intel Graphics DCH') {
                $OSNameMatch = @('Win10')
                $OSVersionMatch = @('10.0')
                $OSArchMatch = 'x64'
            }
            #===================================================================================================
            #   DriverName
            #===================================================================================================
            $DriverName = "$OSDGroup $DriverVersion $OSArchMatch"
            #===================================================================================================
            #   DriverGrouping
            #===================================================================================================
            $DriverGrouping = "$DriverResultsName $OSArchMatch"
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
            #   OSDFiles
            #===================================================================================================
            $OSDPnpFile = "$($DriverName).drvpnp"
            $OSDCabFile = "$($DriverName).cab"
            $OSDTaskFile = "$($DriverName).drvtask"
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