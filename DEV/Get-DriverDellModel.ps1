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
    [xml]$DellDriverPackCatalog = Get-Content "$env:TEMP\DriverPackCatalog.xml" -ErrorAction Stop
    $DellDriverPackList = $DellDriverPackCatalog.DriverPackManifest.DriverPackage
    #Write-Verbose "$env:TEMP\DriverPackCatalog.xml" -Verbose

<# 	$FilteredDellDriverPackList = @($DellDriverPackList | select-object -Property @{Label="Name";Expression={($_.Name.Display.'#cdata-section'.Trim())}},
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
    $DriverResults = foreach ($DellDriverPack in $DellDriverPackList) {
        #===================================================================================================
        #   Defaults
        #===================================================================================================
        $LastUpdate = [datetime] $(Get-Date)
        $OSDVersion = $(Get-Module -Name OSDDrivers | Sort-Object Version | Select-Object Version -Last 1).Version
        $OSDStatus = $null
        $OSDGroup = 'DellModel'
        $OSDType = 'ModelPack'

        $DriverName = $null
        $DriverVersion = $null
        $DriverGrouping = $null

        $DriverFamilyChild = $null
        $DriverFamily = $null
        $DriverChild = $null

        $IsDesktop = $false
        $IsLaptop = $false
        $IsServer = $false

        $MakeLike = @()
        $MakeNotLike = @()
        $MakeMatch = @('Dell')
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

        $OSDPnpClass = $null
        $OSDPnpClassGuid = $null

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
        $DriverInfo = $null
        $DriverCleanup = @('\\Audio\\','\\Video\\')
        $OSDGuid = $(New-Guid)
        #===================================================================================================
        #   DriverVersion
        #===================================================================================================
        $LastUpdate = $DellDriverPack.dateTime
        $DownloadFile = $DellDriverPack.Name.Display.'#cdata-section'.Trim()
        $DriverFamily = $DellDriverPack.SupportedSystems.Brand.Prefix.Trim()
        $DriverChild = $DellDriverPack.SupportedSystems.Brand.Model.Generation.Trim() | Select-Object -Unique
        $ModelEq = $DellDriverPack.SupportedSystems.Brand.Model.Name.Trim() | Select-Object -Unique
        $SystemSkuMatch = $DellDriverPack.SupportedSystems.Brand.Model.systemID.Trim() | Select-Object -Unique
        $ModelRTSDate = [datetime] $($DellDriverPack.SupportedSystems.Brand.Model.rtsdate.Trim() | Select-Object -Unique)
        $DriverVersion = $DellDriverPack.dellVersion
        $DriverUrl = "$DellDownloadBase/$($DellDriverPack.path)"
        $DriverInfo = $DellDriverPack.ImportantInfo.URL.Trim() | Select-Object -Unique
        $OSNameMatch = $DellDriverPack.SupportedOperatingSystems.OperatingSystem.Display.'#cdata-section'.Trim() | Select-Object -Unique
        $SizeMB = ($DellDriverPack.size.Trim() | Select-Object -Unique) / 1024
        $OSArchMatch = $DellDriverPack.SupportedOperatingSystems.OperatingSystem.osArch.Trim() | Select-Object -Unique
        #===================================================================================================
        #   DriverFamily
        #===================================================================================================
        if ($DriverFamily -Contains 'IOT') {
            $DriverFamily = 'IOT'
            $IsDesktop = $true
        }
        if ($DriverFamily -Contains 'LAT') {
            $DriverFamily = 'Latitude'
            $IsLaptop = $true
        }
        if ($DriverFamily -Contains 'OP') {
            $DriverFamily = 'OptiPlex'
            $IsDesktop = $true
        }
        if ($DriverFamily -Contains 'PRE') {$DriverFamily = 'Precision'}
        if ($DriverFamily -Contains 'TABLET') {
            $DriverFamily = 'Tablet'
            $IsLaptop = $true
        }
        if ($DriverFamily -Contains 'XPSNOTEBOOK') {
            $DriverFamily = 'XPS'
            $IsLaptop = $true
        }
        $DriverFamilyChild = "$DriverFamily $DriverChild"
        #===================================================================================================
        #   OSNameMatch OSVersionMatch OSVersionMax
        #===================================================================================================
        if ($OSNameMatch -match 'Windows PE') {Continue}
        if ($OSNameMatch -match 'Windows XP') {Continue}
        if ($OSNameMatch -match 'Windows Vista') {Continue}
        if ($OSNameMatch -match 'Windows 7') {Continue}
        if ($OSNameMatch -match 'Windows 8 ') {Continue}
        if ($OSNameMatch -match 'Windows 8.1') {Continue}

        if ($OSNameMatch -match "Windows 7") {
            $OSNameMatch = 'Win7'
            $OSVersionMatch = '6.1'
        }
        if ($OSNameMatch -match "Windows 8.1") {
            $OSNameMatch = 'Win8.1'
            $OSVersionMatch = '6.3'
        }
        if ($OSNameMatch -match "Windows 10") {
            $OSNameMatch = 'Win10'
            $OSVersionMatch = '10.0'
        }
        #===================================================================================================
        #   DriverName
        #===================================================================================================
        $DriverName = "$OSDGroup $ModelEq $DriverVersion"
        $DriverGrouping = "$ModelEq"
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
            OSDCabFile              = [string] $OSDCabFile
            OSDTaskFile             = [string] $OSDTaskFile
            FileType                = [string] $FileType
            SizeMB                  = [int] $SizeMB
            IsSuperseded            = [bool] $IsSuperseded

            DriverUrl               = [string] $DriverUrl
            DriverDescription       = [string] $DriverDescription
            DriverInfo              = [string] $DriverInfo
            DriverCleanup           = [array] $DriverCleanup
            OSDGuid                 = [string] $(New-Guid)
            
            #RTSDate                 = [datetime] $RTSDate
            #Generation              = [string] $Generation
        }
        New-Object -TypeName PSObject -Property $ObjectProperties
    }
    #===================================================================================================
    #   Select-Object
    #===================================================================================================
    $DriverResults = $DriverResults | Select-Object LastUpdate, `
    OSDVersion,OSDStatus,OSDGroup,OSDType,`
    DriverName, DriverVersion, DriverGrouping,`
    #OSNameMatch,`
    OSVersionMatch, OSArchMatch,`
    #OSNameNotMatch,`
    DriverFamilyChild, DriverFamily, DriverChild,`
    IsDesktop,IsLaptop,`
    #IsServer,`
    #MakeLike, MakeNotLike,`
    MakeMatch,`
    #MakeNotMatch,`
    #ModelLike, ModelNotLike,`
    #ModelMatch, ModelNotMatch,`
    ModelEq,`
    #ModelNe,`
    #SystemFamilyMatch, SystemFamilyNotMatch,`
    SystemSkuMatch,`
    #SystemSkuNotMatch,`
    #OSNameNotMatch, OSArchNotMatch, OSVersionNotMatch, OSBuildGE, OSBuildLE,`
    #OSInstallationType,`
    #OSDPnpClass,OSDPnpClassGuid,`
    #DriverBundle, DriverWeight,`
    DownloadFile,`
    #OSDPnpFile, OSDCabFile, OSDTaskFile,`
    #FileType,`
    SizeMB,`
    IsSuperseded,`
    DriverUrl,`
    #DriverDescription,`
    DriverInfo,`
    #DriverCleanup,`
    OSDGuid
    #===================================================================================================
    #   Supersedence
    #===================================================================================================
<#     $DriverResults = $DriverResults | Sort-Object DriverName -Descending
    $CurrentOSDDriverDellFamily = @()
    foreach ($FamilyPack in $DriverResults) {
        if ($CurrentOSDDriverDellFamily.DriverGrouping -match $FamilyPack.DriverGrouping) {
            $FamilyPack.IsSuperseded = $true
        } else { 
            $CurrentOSDDriverDellFamily += $FamilyPack
        }
    }
    $DriverResults = $DriverResults | Where-Object {$_.IsSuperseded -eq $false} #>
    #$DriverResults = $DriverResults | Where-Object {$_.OSVersionMatch -match '10.0'}
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