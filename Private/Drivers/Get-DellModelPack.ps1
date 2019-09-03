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
function Get-DellModelPack {
    [CmdletBinding()]
    Param (
        [string]$DownloadPath
    )
    #===================================================================================================
    #   OSDDrivers.json
    #===================================================================================================
    if (Test-Path "$env:ProgramData\OSDDrivers\OSDDrivers.json") {
        $OSDDrivers = Get-Content "$env:ProgramData\OSDDrivers\OSDDrivers.json" | ConvertFrom-Json
    } else {
        Write-Verbose "Creating $env:ProgramData\OSDDrivers\OSDDrivers.json" -Verbose
        if (!(Test-Path "$env:ProgramData\OSDDrivers")) {New-Item "$env:ProgramData\OSDDrivers" -ItemType Directory -Force | Out-Null}
        $OSDDrivers = New-Object -TypeName PSObject -Property @{
            WorkspacePath = $null
            DellModels = $null
            HPModels = $null
        }
        $OSDDrivers | ConvertTo-Json | Out-File -FilePath "$env:ProgramData\OSDDrivers\OSDDrivers.json" -Force
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
    $DellDownloadsListUrl = "http://downloads.dell.com/published/Pages/index.html"
    $DellDownloadsBaseUrl = "http://downloads.dell.com"
    $DellDriverListUrl = "http://en.community.dell.com/techcenter/enterprise-client/w/wiki/2065.dell-command-deploy-driver-packs-for-enterprise-client-os-deployment"
    $DellCommunityUrl = "http://en.community.dell.com"
    $Dell64BiosUtilityUtl = "http://en.community.dell.com/techcenter/enterprise-client/w/wiki/12237.64-bit-bios-installation-utility"
    
    # Define Dell Download Sources
    $DellDriverPackCatalogUrl = "http://downloads.dell.com/catalog/DriverPackCatalog.cab"
    $DellCatalogPcUrl = "http://downloads.dell.com/catalog/CatalogPC.cab"
    
    # Define Dell Cabinet/XL Names and Paths
    $DellCabFile = [string]($DellDriverPackCatalogUrl | Split-Path -Leaf)
    $DellCatalogFile = [string]($DellCatalogPcUrl | Split-Path -Leaf)
    #$DellXMLFile = $DellCabFile.Trim(".cab")
    #$DellXMLFile = $DellXMLFile + ".xml"
    #$DellCatalogXMLFile = $DellCatalogFile.Trim(".cab") + ".xml"
    
    # Define Dell Global Variables
    #$global:DellCatalogXML = $null
    #$global:DellModelXML = $null
    #$global:DellModelCabFiles = $null
    #===================================================================================================
    #   Driver
    #===================================================================================================
<#     (New-Object System.Net.WebClient).DownloadFile($DellCatalogPcUrl, "$env:TEMP\CatalogPC.cab")
    Expand "$env:TEMP\CatalogPC.cab" "$env:TEMP\CatalogPC.xml"
    Remove-Item -Path "$env:TEMP\CatalogPC.cab" -Force
    [xml]$DellDriverCatalog = Get-Content "$env:TEMP\CatalogPC.xml" -ErrorAction Stop
    $DellDriverList = $DellDriverCatalog.DriverPackManifest.DriverPackage #>
    #===================================================================================================
    #   DriverPackCatalog
    #===================================================================================================
    if (-not(Test-Path "$DownloadPath")) {New-Item "$DownloadPath" -ItemType Directory -Force | Out-Null}
    (New-Object System.Net.WebClient).DownloadFile($DellDriverPackCatalogUrl, "$DownloadPath\DriverPackCatalog.cab")

    Expand "$DownloadPath\DriverPackCatalog.cab" "$DownloadPath\DriverPackCatalog.xml" | Out-Null

    if (Test-Path "$DownloadPath\DriverPackCatalog.cab") {
        Remove-Item -Path "$DownloadPath\DriverPackCatalog.cab" -Force | Out-Null
    }

    [xml]$DriverPackageCatalog = Get-Content "$DownloadPath\DriverPackCatalog.xml" -ErrorAction Stop
    $DellDriverPackCatalog = $DriverPackageCatalog.DriverPackManifest.DriverPackage
    #===================================================================================================
    #   ForEach
    #===================================================================================================
    $ErrorActionPreference = 'SilentlyContinue'
    $DriverResults = @()
    $DriverResults = foreach ($DriverPackage in $DellDriverPackCatalog) {
        #===================================================================================================
        #   Defaults
        #===================================================================================================
        $OSDVersion = $(Get-Module -Name OSDDrivers | Sort-Object Version | Select-Object Version -Last 1).Version
        $LastUpdate = [datetime] $(Get-Date)
        $OSDStatus = $null
        $OSDType = 'ModelPack'
        $OSDGroup = 'DellModel'

        $DriverName = $null
        $DriverVersion = $null
        $DriverReleaseId = $null
        $DriverGrouping = $null

        $OperatingSystem = @()
        $OsVersion = @()
        $OsArch = @()
        $OsBuildMax = @()
        $OsBuildMin = @()

        $Make = 'Dell'
        $MakeNe = @()
        $MakeLike = @()
        $MakeNotLike = @()
        $MakeMatch = @()
        $MakeNotMatch = @()

        $Generation = $null
        $SystemFamily = $null

        $Model = $null
        $ModelNe = @()
        $ModelLike = @()
        $ModelNotLike = @()
        $ModelMatch = @()
        $ModelNotMatch = @()

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
        #   Get Values
        #===================================================================================================
        $LastUpdate         = [datetime] $DriverPackage.dateTime
        $DriverVersion      = $DriverPackage.dellVersion.Trim()
        $DriverDelta        = $DriverPackage.delta.Trim()
        $DriverFormat       = $DriverPackage.format.Trim()
        $Hash               = $DriverPackage.hashMD5.Trim()
        $DownloadFile       = $DriverPackage.Name.Display.'#cdata-section'.Trim()
        $DriverReleaseId    = $DriverPackage.releaseID.Trim()
        $SizeMB             = ($DriverPackage.size.Trim() | Select-Object -Unique) / 1024
        $DriverType         = $DriverPackage.type.Trim()
        $VendorVersion      = $DriverPackage.vendorVersion.Trim()
        $DriverInfo         = $DriverPackage.ImportantInfo.URL.Trim() | Select-Object -Unique
        $OperatingSystem    = $DriverPackage.SupportedOperatingSystems.OperatingSystem.Display.'#cdata-section'.Trim() | Select-Object -Unique
        $OsArch             = $DriverPackage.SupportedOperatingSystems.OperatingSystem.osArch.Trim() | Select-Object -Unique
        $OsCode             = $DriverPackage.SupportedOperatingSystems.OperatingSystem.osCode.Trim() | Select-Object -Unique
        $OsType             = $DriverPackage.SupportedOperatingSystems.OperatingSystem.osType.Trim() | Select-Object -Unique
        $OsVendor           = $DriverPackage.SupportedOperatingSystems.OperatingSystem.osVendor.Trim() | Select-Object -Unique
        $OsMajor            = $DriverPackage.SupportedOperatingSystems.OperatingSystem.majorVersion.Trim() | Select-Object -Unique
        $OsMinor            = $DriverPackage.SupportedOperatingSystems.OperatingSystem.minorVersion.Trim() | Select-Object -Unique
        $ModelBrand         = $DriverPackage.SupportedSystems.Brand.Display.'#cdata-section'.Trim() | Select-Object -Unique
        $ModelBrandKey      = $DriverPackage.SupportedSystems.Brand.Key.Trim() | Select-Object -Unique
        $ModelId            = $DriverPackage.SupportedSystems.Brand.Model.Display.'#cdata-section'.Trim() | Select-Object -Unique
        $Generation         = $DriverPackage.SupportedSystems.Brand.Model.Generation.Trim() | Select-Object -Unique
        $Model              = $DriverPackage.SupportedSystems.Brand.Model.Name.Trim() | Select-Object -Unique
        $ModelRtsDate       = [datetime] $($DriverPackage.SupportedSystems.Brand.Model.rtsdate.Trim() | Select-Object -Unique)
        $SystemSku          = $DriverPackage.SupportedSystems.Brand.Model.systemID.Trim() | Select-Object -Unique
        $ModelPrefix        = $DriverPackage.SupportedSystems.Brand.Prefix.Trim() | Select-Object -Unique
        #===================================================================================================
        #   DriverFamily
        #===================================================================================================
        if ($ModelPrefix -Contains 'IOT') {
            $SystemFamily = 'IOT'
            $IsDesktop = $true
        }
        if ($ModelPrefix -Contains 'LAT') {
            $SystemFamily = 'Latitude'
            $IsLaptop = $true
        }
        if ($ModelPrefix -Contains 'OP') {
            $SystemFamily = 'Optiplex'
            $IsDesktop = $true
        }
        if ($ModelPrefix -Contains 'PRE') {$SystemFamily = 'Precision'}
        if ($ModelPrefix -Contains 'TABLET') {
            $SystemFamily = 'Tablet'
            $IsLaptop = $true
        }
        if ($ModelPrefix -Contains 'XPSNOTEBOOK') {
            $SystemFamily = 'XPS'
            $IsLaptop = $true
        }
        #===================================================================================================
        #   Corrections
        #===================================================================================================
        if ($Model -eq 'Precision M4600') {$Generation = 'X3'}
        if ($Model -eq 'Precision M3800') {$Model = 'Dell Precision M3800'}
        #===================================================================================================
        #   Customizations
        #===================================================================================================
        if ($OsCode -eq 'XP') {Continue}
        if ($OsCode -eq 'Vista') {Continue}
        #if ($OsCode -eq 'Windows8') {Continue}
        #if ($OsCode -eq 'Windows8.1') {Continue}
        if ($OsCode -match 'WinPE') {Continue}
        $DriverUrl = "$DellDownloadsBaseUrl/$($DriverPackage.path)"
        $OsVersion = "$($OsMajor).$($OsMinor)"
        $DriverName = "$OSDGroup $Generation $Model $OsVersion $DriverVersion"
        $DriverGrouping = "$Generation $Model $OsVersion"
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

            DriverName              = $DriverName
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

            SystemSku               = $SystemSku
            SystemSkuNe             = $SystemSkuNe

            DriverGrouping          = $DriverGrouping
            DriverBundle            = $DriverBundle
            DriverWeight            = [int] $DriverWeight

            DownloadFile            = $DownloadFile
            SizeMB                  = [int] $SizeMB
            DriverUrl               = $DriverUrl
            DriverInfo              = $DriverInfo
            DriverDescription       = $DriverDescription
            Hash                    = $Hash
            OSDGuid                 = $OSDGuid
        }
        New-Object -TypeName PSObject -Property $ObjectProperties
    }
    #===================================================================================================
    #   Select-Object
    #===================================================================================================
    $DriverResults = $DriverResults | Select-Object LastUpdate,`
    OSDType, OSDGroup, OSDStatus, `
    DriverGrouping, DriverName, Make, Generation, Model, SystemSku,`
    DriverVersion, DriverReleaseId,`
    OsVersion, OsArch,
    DownloadFile, SizeMB, DriverUrl, DriverInfo,`
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