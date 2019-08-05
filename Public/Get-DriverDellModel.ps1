function Get-DriverDellModel
{
    [CmdletBinding()]
    Param ()
    #===================================================================================================
    #   Dell Variables
    #===================================================================================================
    # Define Dell Download Sources
    $DellDownloadList = "http://downloads.dell.com/published/Pages/index.html"
    $DellDownloadBase = "http://downloads.dell.com"
    $DellDriverListURL = "http://en.community.dell.com/techcenter/enterprise-client/w/wiki/2065.dell-command-deploy-driver-packs-for-enterprise-client-os-deployment"
    $DellBaseURL = "http://en.community.dell.com"
    $Dell64BIOSUtil = "http://en.community.dell.com/techcenter/enterprise-client/w/wiki/12237.64-bit-bios-installation-utility"
    
    # Define Dell Download Sources
    $DellXMLCabinetSource = "http://downloads.dell.com/catalog/DriverPackCatalog.cab"
    $DellCatalogSource = "http://downloads.dell.com/catalog/CatalogPC.cab"
    
    # Define Dell Cabinet/XL Names and Paths
    $DellCabFile = [string]($DellXMLCabinetSource | Split-Path -Leaf)
    $DellCatalogFile = [string]($DellCatalogSource | Split-Path -Leaf)
    $DellXMLFile = $DellCabFile.Trim(".cab")
    $DellXMLFile = $DellXMLFile + ".xml"
    $DellCatalogXMLFile = $DellCatalogFile.Trim(".cab") + ".xml"
    
    # Define Dell Global Variables
    $global:DellCatalogXML = $null
    $global:DellModelXML = $null
    $global:DellModelCabFiles = $null
    #===================================================================================================
    #   Driver
    #===================================================================================================
<#     (New-Object System.Net.WebClient).DownloadFile($DellCatalogSource, "$env:TEMP\CatalogPC.cab")
    Expand "$env:TEMP\CatalogPC.cab" "$env:TEMP\CatalogPC.xml"
    Remove-Item -Path "$env:TEMP\CatalogPC.cab" -Force
    [xml]$DellDriverCatalog = Get-Content "$env:TEMP\CatalogPC.xml" -ErrorAction Stop
    $DellDriverList = $DellDriverCatalog.DriverPackManifest.DriverPackage #>
    #===================================================================================================
    #   DriverPack
    #===================================================================================================
    (New-Object System.Net.WebClient).DownloadFile($DellXMLCabinetSource, "$env:TEMP\DriverPackCatalog.cab")
    Expand "$env:TEMP\DriverPackCatalog.cab" "$env:TEMP\DriverPackCatalog.xml" | Out-Null
    Remove-Item -Path "$env:TEMP\DriverPackCatalog.cab" -Force | Out-Null
    [xml]$DriverPackageCatalog = Get-Content "$env:TEMP\DriverPackCatalog.xml" -ErrorAction Stop
    $DellDriverPackCatalog = $DriverPackageCatalog.DriverPackManifest.DriverPackage
    #Write-Verbose "$env:TEMP\DriverPackCatalog.xml" -Verbose

<# 	$FilteredDellDriverPackCatalog = @($DellDriverPackCatalog | select-object -Property @{Label="Name";Expression={($_.Name.Display.'#cdata-section'.Trim())}},
        @{Label="Model";Expression={($_.SupportedSystems.Brand.Model.Name.Trim() | Select-Object -unique )}},
        @{Label="OperatingSystem";Expression={ ($_.SupportedOperatingSystems.OperatingSystem | %{ $_.Display.'#cdata-section'.Trim() } | Select-Object -Unique ) }},
        ReleaseID, Size, DateTime, Hash, DellVersion, Path, Delta, Type,
        @{Label="SupportedOperatingSystems";Expression={ ($_.SupportedOperatingSystems) }} | Out-GridView -OutputMode Multiple -Title "Select CABS to Dowload" )
        
    Break
    Return #>
    #===================================================================================================
    #   ForEach
    #===================================================================================================
    $ErrorActionPreference = 'SilentlyContinue'
    $DriverResults = @()
    $DriverResults = foreach ($DriverPackage in $DellDriverPackCatalog) {
        #===================================================================================================
        #   Defaults
        #===================================================================================================
        $LastUpdate = [datetime] $(Get-Date)
        $OSDVersion = $(Get-Module -Name OSDDrivers | Sort-Object Version | Select-Object Version -Last 1).Version
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

        $Make = @('Dell')
        $MakeNot = @()
        $ModelLike = @()
        $ModelNotLike = @()
        $ModelMatch = @()
        $ModelNotMatch = @()

        $Generation = $null
        $SystemFamily = $null

        $Model = @()
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
        $LastUpdate         = $DriverPackage.dateTime
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
        #   Customizations
        #===================================================================================================
        if ($OsCode -eq 'XP') {Continue}
        if ($OsCode -eq 'Vista') {Continue}
        if ($OsCode -eq 'Windows8') {Continue}
        if ($OsCode -eq 'Windows8.1') {Continue}
        if ($OsCode -match 'WinPE') {Continue}
        $DriverUrl = "$DellDownloadBase/$($DriverPackage.path)"
        $OsVersion = "$($OsMajor).$($OsMinor)"
        $DriverName = "$OSDGroup $Generation $Model $OsVersion $DriverVersion"
        $DriverGrouping = "$Generation $Model $OsVersion"
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
            OsVersion               = [string] $OsVersion
            OsArch                  = [array[]] $OsArch
            OsBuildMax              = [string] $OsBuildMax
            OsBuildMin              = [string] $OsBuildMin

            Make                    = [array[]] $Make
            MakeNot                 = [array[]] $MakeNot
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
        }
        New-Object -TypeName PSObject -Property $ObjectProperties
    }
    #===================================================================================================
    #   Select-Object
    #===================================================================================================
    $DriverResults = $DriverResults | Select-Object OSDVersion, LastUpdate, OSDStatus, OSDType, OSDGroup,`
    DriverName, DriverVersion, DriverReleaseId,`
    OsVersion, OsArch,` #OperatingSystem
    Generation,`
    Make,` #MakeNot, MakeLike, MakeNotLike
    SystemFamily,`
    Model,` #ModelNe, ModelLike, ModelNotLike, ModelMatch, ModelNotMatch
    SystemSku,` #SystemSkuNe
    DriverGrouping,`
    DownloadFile, SizeMB, DriverUrl, DriverInfo,` #DriverDescription
    Hash,  OSDGuid
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