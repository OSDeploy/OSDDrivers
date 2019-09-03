<#
.SYNOPSIS
Returns a PowerShell Object of the Dell Model Packs

.DESCRIPTION
Returns a PowerShell Object of the Dell Model Packs by parsing the Dell Driver Pack Catalog from http://downloads.dell.com/catalog/DriverPackCatalog.cab"

.PARAMETER DownloadPath
Directory containing the downloaded Dell Model Packs.  This allows the function to validate if the Driver Pack was downloaded by updating OSDStatus

.LINK
https://osddrivers.osdeploy.com/functions/get-dellmodelpack
#>
function Get-HpModelPack {
    [CmdletBinding()]
    Param (
        [string]$DownloadPath
    )
    #===================================================================================================
    #   OSDDrivers.json
    #===================================================================================================
    if (Test-Path "$env:ProgramData\OSDDrivers\OSDDrivers.json") {
        $OSDDrivers = Get-Content "$env:ProgramData\OSDDrivers\OSDDrivers.json"
    }

    #===================================================================================================
    #   DownloadPath
    #===================================================================================================
    if (-not($DownloadPath)) {$DownloadPath = $env:TEMP}
    Write-Verbose "DownloadPath: $DownloadPath"
    #===================================================================================================
    #   Dell Variables
    #===================================================================================================
    # Define Dell Download Sources
    $HpDownloadsListUrl = "http://downloads.dell.com/published/Pages/index.html"
    $HpDownloadsBaseUrl = "http://downloads.dell.com"
    $HpDriverListUrl = "http://en.community.dell.com/techcenter/enterprise-client/w/wiki/2065.dell-command-deploy-driver-packs-for-enterprise-client-os-deployment"
    $HpCommunityUrl = "http://en.community.dell.com"
    $Hp64BiosUtilityUtl = "http://en.community.dell.com/techcenter/enterprise-client/w/wiki/12237.64-bit-bios-installation-utility"
    
    # Define Dell Download Sources
    $DriverPackCatalog = "https://ftp.hp.com/pub/caps-softpaq/cmit/HPClientDriverPackCatalog.cab"
    $HpCatalogPcUrl = "http://downloads.dell.com/catalog/CatalogPC.cab"
    
    # Define Dell Cabinet/XL Names and Paths
    $HpCabFile = [string]($DriverPackCatalog | Split-Path -Leaf)
    $HpCatalogFile = [string]($HpCatalogPcUrl | Split-Path -Leaf)
    #===================================================================================================
    #   DriverPackCatalog
    #===================================================================================================
    if (-not(Test-Path "$DownloadPath")) {New-Item "$DownloadPath" -ItemType Directory -Force | Out-Null}
    (New-Object System.Net.WebClient).DownloadFile($DriverPackCatalog, "$DownloadPath\DriverPackCatalog.cab")

    Expand "$DownloadPath\DriverPackCatalog.cab" "$DownloadPath\DriverPackCatalog.xml" | Out-Null

    if (Test-Path "$DownloadPath\DriverPackCatalog.cab") {
        Remove-Item -Path "$DownloadPath\DriverPackCatalog.cab" -Force | Out-Null
    }

    [xml]$DriverPackageCatalog = Get-Content "$DownloadPath\DriverPackCatalog.xml" -ErrorAction Stop
    $HpSoftPaqList = $DriverPackageCatalog.NewDataSet.HPClientDriverPackCatalog.SoftPaqList.SoftPaq
    #$HpSoftPaqList | Out-GridView
    $HpProductOSDriverPackList = $DriverPackageCatalog.NewDataSet.HPClientDriverPackCatalog.ProductOSDriverPackList.ProductOSDriverPack
    #$HpProductOSDriverPackList | Out-GridView
    Write-Warning "HpModelPack results are limited to Windows 10 x64"
    #===================================================================================================
    #   ForEach
    #===================================================================================================
    $ErrorActionPreference = 'SilentlyContinue'
    $DriverResults = @()
    $DriverResults = foreach ($DriverPackage in $HpSoftPaqList) {
        #===================================================================================================
        #   Skip
        #===================================================================================================
        if ($DriverPackage.Name -match 'IOT') {Continue}
        #===================================================================================================
        #   Defaults
        #===================================================================================================
        $OSDVersion = $(Get-Module -Name OSDDrivers | Sort-Object Version | Select-Object Version -Last 1).Version
        $LastUpdate = [datetime] $DriverPackage.DateReleased
        $OSDStatus = $null
        $OSDType = 'ModelPack'
        $OSDGroup = 'HPModel'

        $DriverName = $DriverPackage.Name
        if ($DriverName -match 'x86') {Continue}
        if ($DriverName -match 'Win7') {Continue}
        if ($DriverName -match 'Win 7') {Continue}
        if ($DriverName -match 'Windows 7') {Continue}
        if ($DriverName -match 'Win 8') {Continue}
        if ($DriverName -match 'Windows 8') {Continue}


        $DriverName = ($DriverName).Replace('/',' ')
        $DriverName = ($DriverName).Replace(' x64','')
        $DriverName = ($DriverName).Replace(' x86','')
        $DriverName = ($DriverName).Replace(' Win7','')
        $DriverName = ($DriverName).Replace(' Win10','')
        $DriverName = ($DriverName).Replace(' Win 7','')
        $DriverName = ($DriverName).Replace(' Win 10','')
        $DriverName = ($DriverName).Replace(' Windows 7','')
        $DriverName = ($DriverName).Replace(' Windows 10','')
        $DriverName = ($DriverName).Replace(' Driver Pack','')

        $DriverVersion = $DriverPackage.Version.Trim()
        $DriverReleaseId = ($DriverPackage.Url | Split-Path -Leaf).Replace('.exe','').ToUpper()
        $DriverGrouping = $null
        #===================================================================================================
        #   Matching
        #===================================================================================================
        $MatchingList = @()
        $MatchingList = $HpProductOSDriverPackList | Where-Object {$_.SoftPaqId -match $DriverReleaseId}

        $OperatingSystem = @()
        $OsVersion = $null
        $OsArch = $null
        $OsBuildMax = @()
        $OsBuildMin = @()

        $Make = 'HP'
        $MakeNe = @()
        $MakeLike = @()
        $MakeNotLike = @()
        $MakeMatch = @()
        $MakeNotMatch = @()

        $Generation = 'G0'
        $SystemFamily = $null

        $Model = ($MatchingList | Select-Object -Property SystemName -Unique)
        $Model = ($Model).SystemName
        #$Model = $null
        $ModelNe = @()
        $ModelLike = @()
        $ModelNotLike = @()
        $ModelMatch = @()
        $ModelNotMatch = @()

        $SystemSku = @()
        $SystemSku = ($MatchingList | Select-Object -Property SystemId -Unique)
        $SystemSku = ($SystemSku).SystemId
        #$SystemSku = $SystemSku | Select-Object SystemId -ExpandProperty
        $SystemSkuNe = @()

        $DriverBundle = $null
        $DriverWeight = 100

        $DownloadFile = $DriverPackage.Url | Split-Path -Leaf
        $SizeMB = ($DriverPackage.Size.Trim() | Select-Object -Unique) / 1024
        $DriverUrl = $DriverPackage.Url
        $DriverInfo = $DriverPackage.CvaFileUrl
        $DriverDescription = $DriverPackage.ReleaseNotesUrl
        $Hash = $DriverPackage.MD5.Trim()
        $OSDGuid = $(New-Guid)
        #===================================================================================================
        #   Get Values
        #===================================================================================================
        if ($DriverPackage.Name -match 'x64') {$OsArch = 'x64'}
        if ($DriverPackage.Name -match 'x86') {$OsArch = 'x86'}
        if ($null -eq $OsArch) {$OsArch = 'x64'}
        if ($DriverPackage.Name -match 'Win7') {$OsVersion = '6.1'}
        if ($DriverPackage.Name -match 'Win 7') {$OsVersion = '6.1'}
        if ($DriverPackage.Name -match 'Window 7') {$OsVersion = '6.1'}
        if ($DriverPackage.Name -match 'Windows 7') {$OsVersion = '6.1'}
        if ($DriverPackage.Name -match 'Win8') {$OsVersion = '6.3'}
        if ($DriverPackage.Name -match 'Win 8') {$OsVersion = '6.3'}
        if ($DriverPackage.Name -match 'Windows 8') {$OsVersion = '6.3'}
        if ($DriverPackage.Name -match 'Win10') {$OsVersion = '10.0'}
        if ($DriverPackage.Name -match 'Win 10') {$OsVersion = '10.0'}
        if ($DriverPackage.Name -match 'Windows 10') {$OsVersion = '10.0'}

        if ($DriverPackage.Name -match 'G1') {$Generation = 'G1'}
        if ($DriverPackage.Name -match 'G2') {$Generation = 'G2'}
        if ($DriverPackage.Name -match 'G3') {$Generation = 'G3'}
        if ($DriverPackage.Name -match 'G4') {$Generation = 'G4'}
        if ($DriverPackage.Name -match 'G5') {$Generation = 'G5'}
        if ($DriverPackage.Name -match 'G6') {$Generation = 'G6'}
        if ($DriverPackage.Name -match 'G7') {$Generation = 'G7'}
        #===================================================================================================
        #   SystemFamily
        #===================================================================================================
        #===================================================================================================
        #   Corrections
        #===================================================================================================
        if ($SystemSku -contains '81C6') {$Generation = 'G4'}
        if ($SystemSku -contains '81C7') {$Generation = 'G4'}
        if ($SystemSku -contains '824C') {$Generation = 'G4'}
        #===================================================================================================
        #   Customizations
        #===================================================================================================
        if (Test-Path "$DownloadPath\$DownloadFile") {
            $OSDStatus = 'Downloaded'
        }
        #===================================================================================================
        #   Create Object 
        #===================================================================================================
        $ObjectProperties = @{
            OSDVersion              = [string]$OSDVersion
            LastUpdate              = $(($LastUpdate).ToString("yyyy-MM-dd"))
            OSDStatus               = $OSDStatus
            OSDType                 = $OSDType
            OSDGroup                = $OSDGroup

            DriverName              = "$DriverName $OsVersion $OsArch $DriverVersion"
            DriverVersion           = $DriverVersion
            DriverReleaseId         = $DriverReleaseID

            OperatingSystem         = $OperatingSystem
            OsVersion               = $OsVersion
            OsArch                  = $OsArch
            OsBuildMax              = $OsBuildMax
            OsBuildMin              = $OsBuildMin

            Make                    = $Make
            MakeNe                  = $MakeNe
            MakeLike                = $MakeLike
            MakeNotLike             = $MakeNotLike
            MakeMatch               = $MakeMatch
            MakeNotMatch            = $MakeNotMatch

            Generation              = $Generation
            SystemFamily            = $SystemFamily

            Model                   = $Model
            ModelNe                 = $ModelNe
            ModelLike               = $ModelLike
            ModelNotLike            = $ModelNotLike
            ModelMatch              = $ModelMatch
            ModelNotMatch           = $ModelNotMatch

            SystemSku               = $SystemSku -split(',')
            SystemSkuNe             = $SystemSkuNe

            DriverGrouping          = "$DriverName $OsVersion $OsArch"
            DriverBundle            = $DriverBundle
            DriverWeight            = [int] $DriverWeight

            DownloadFile            = $DownloadFile
            SizeMB                  = [int] $SizeMB
            DriverUrl               = $DriverUrl
            DriverInfo              = $DriverInfo
            DriverDescription       = $DriverDescription
            Hash                    = $Hash
            OSDGuid                 = $OSDGuid
            IsSuperseded            = [bool] $IsSuperseded
        }
        New-Object -TypeName PSObject -Property $ObjectProperties
    }
    #===================================================================================================
    #   Supersedence
    #===================================================================================================
    $DriverResults = $DriverResults | Sort-Object LastUpdate -Descending
    $CurrentOSDDriverHpModelPack = @()
    foreach ($HpModelPack in $DriverResults) {
        if ($CurrentOSDDriverHpModelPack.DriverGrouping -match $HpModelPack.DriverGrouping) {
            $HpModelPack.IsSuperseded = $true
        } else { 
            $CurrentOSDDriverHpModelPack += $HpModelPack
        }
    }
    $DriverResults = $DriverResults | Where-Object {$_.IsSuperseded -eq $false}
    #===================================================================================================
    #   Select-Object
    #===================================================================================================
    $DriverResults = $DriverResults | Select-Object LastUpdate,`
    OSDType, OSDGroup, OSDStatus, `
    DriverGrouping, DriverName, Make, Generation, Model, SystemSku,`
    DriverVersion, DriverReleaseId,`
    OsVersion, OsArch,`
    DownloadFile, SizeMB, DriverUrl, DriverInfo, DriverDescription,
    Hash, OSDGuid, OSDVersion
    #===================================================================================================
    #   Sort Object
    #===================================================================================================
    $DriverResults = $DriverResults | Sort-Object LastUpdate -Descending
    #===================================================================================================
    #   Return
    #===================================================================================================
    Return $DriverResults
    #===================================================================================================
}