<#
.SYNOPSIS
Returns a DellFamily Pack Object

.DESCRIPTION
Returns a DellFamily Pack Object
Requires BITS for downloading the Downloads
Requires Internet access for downloading the Downloads

.LINK
https://osddrivers.osdeploy.com/functions/get-driverdellfamily
#>
function Get-DriverDellFamily {
    [CmdletBinding()]
    Param ()
    #===================================================================================================
    #   Uri
    #===================================================================================================
    $Uri = 'http://downloads.delltechcenter.com/DIA/Drivers/'
    #===================================================================================================
    #   DriverWebContentRaw
    #===================================================================================================
    $DriverWebContentRaw = @()
    try {
        $DriverWebContentRaw = (Invoke-WebRequest $Uri).Content
    }
    catch {
        Write-Error "Could not connect to $Uri" -ErrorAction Stop
    }
    #===================================================================================================
    #   DriverWebContentByLine
    #===================================================================================================
    $DriverWebContentByLine = @()
    try {
        $DriverWebContentByLine = $DriverWebContentRaw.Split("`n")
    }
    catch {
        Write-Error "Unable to parse $Uri" -ErrorAction Stop
    }
    #===================================================================================================
    #   DriverWebContent
    #===================================================================================================
    $DriverWebContent = @()
    foreach ($ContentLine in $DriverWebContentByLine) {
        if ($ContentLine -notmatch 'FILE') {Continue}
        if ($ContentLine -notmatch 'HREF') {Continue}

        $ContentLine = $ContentLine -replace '\s+', ' '

        $DriverWebContent += $ContentLine
    }
    #===================================================================================================
    #   ForEach
    #===================================================================================================
    $DriverResults = @()
    $DriverResults = foreach ($ContentLine in $DriverWebContent) {
        #===================================================================================================
        #   Defaults
        #===================================================================================================
        $LastUpdate = [datetime] $(Get-Date)
        $OSDVersion = $(Get-Module -Name OSDDrivers | Sort-Object Version | Select-Object Version -Last 1).Version
        $OSDStatus = $null
        $OSDGroup = 'DellFamily'
        $OSDType = 'FamilyPack'

        $DriverName = $null
        $DriverVersion = $null
        $DriverGrouping = $null

        $DriverFamilyChild = $null
        $DriverFamily = $null
        $DriverChild = $null

        $IsDesktop = $null
        $IsLaptop = $null
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
        $SystemSkuNotMatch = @()

        $OSNameMatch = @()
        $OSNameNotMatch = @()
        $OSArchMatch = @()
        $OSArchNotMatch = @()

        $OSVersionMatch = @()
        $OSVersionNotMatch = @()
        $OSBuildGE = $null
        $OSBuildLE = $null
        $OSInstallationType = 'Client'

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
        $DriverInfo = $DriverLink.href
        $DriverCleanup = @('\\Audio\\','\\Video\\')
        $OSDGuid = $(New-Guid)
        #===================================================================================================
        #   DriverFamily
        #===================================================================================================
        if ($ContentLine -match 'Latitude') {$DriverFamily = 'Latitude'}
        elseif ($ContentLine -match 'OptiPlex') {$DriverFamily = 'OptiPlex'}
        elseif ($ContentLine -match 'Precision') {$DriverFamily = 'Precision'}
        elseif ($ContentLine -match 'Venue') {$DriverFamily = 'Venue'}
        elseif ($ContentLine -match 'Vostro') {$DriverFamily = 'Vostro'}
        elseif ($ContentLine -match 'XPS') {$DriverFamily = 'XPS'}
        else {$DriverFamily = ''}
        #===================================================================================================
        #   OSNameMatch OSVersionMatch OSVersionMax
        #===================================================================================================
        if ($ContentLine -match "Win7") {
            $OSNameMatch = 'Win7'
            $OSVersionMatch = '6.1'
        }
        if ($ContentLine -match "Win8") {
            $OSNameMatch = 'Win8.1'
            $OSVersionMatch = '6.3'
        }
        if ($ContentLine -match "Win10") {
            $OSNameMatch = 'Win10'
            $OSVersionMatch = '10.0'
            $OSArchMatch = 'x64'
        }
        #===================================================================================================
        #   DriverPackFile
        #===================================================================================================
        $DriverPackFile = ($ContentLine.Split('<>')[4]).Trim()
        $DriverUrl = $Uri + $DriverPackFile
        #===================================================================================================
        #   SizeMB
        #===================================================================================================
        $SizeMB = (($ContentLine.Split('<>')[6]).Trim()).Split(' ')[2] -replace 'M',''
        $SizeMB = [int]$SizeMB

        $DriverChild = $DriverPackFile.split('_')[1]
        $DriverChild = $DriverChild -replace "$DriverFamily"
        $DriverChild = $DriverChild.Trim()
        $DriverChild = $DriverChild.ToUpper()

        $DriverFamilyChild = "$DriverFamily $DriverChild"

        $DriverVersion = $DriverPackFile.split('_.')[2]
        $DriverVersion = $DriverVersion.Trim()
        $DriverVersion = $DriverVersion.ToUpper()
        #===================================================================================================
        #   Model Latitude
        #===================================================================================================
        if ($DriverFamilyChild -match 'Latitude') {
            $IsLaptop = $true
            $IsDesktop = $false
        }
        if ($DriverFamilyChild -eq 'Latitude 3X40') {$ModelMatch = 'Latitude 3340','Latitude 3440','Latitude 3540'}

        if ($DriverFamilyChild -eq 'Latitude E1') {$ModelMatch = 'Latitude E4200','Latitude E4300','Latitude E5400','Latitude E5500','Latitude E6400','Latitude E6500','Precision M2400','Precision M4400','Precision M6400'}
        if ($DriverFamilyChild -eq 'Latitude E2') {$ModelMatch = 'Latitude E4310','Latitude E5410','Latitude E5510','Latitude E6410','Latitude E6510','Precision M2400','Precision M4500','Precision M6500','Latitude Z600'}
        if ($DriverFamilyChild -eq 'Latitude E3') {$ModelMatch = 'Latitude 13','Latitude E5420','Latitude E5520','Latitude E6220','Latitude E6320','Latitude E6420','Latitude E6520','Precision M4600','Precision M6600','Latitude XT2'}
        if ($DriverFamilyChild -eq 'Latitude E4') {$ModelMatch = 'Precision M4700','Precision M4700'}

        if ($DriverFamilyChild -eq 'Latitude E5') {$ModelMatch = 'Latitude E5440','Latitude E5540','Latitude E6440','Latitude E6540','Latitude E7240','Latitude E7440'}
        if ($DriverFamilyChild -eq 'Latitude E6') {$ModelMatch = 'Latitude 3150','Latitude 3450','Latitude 3550','Latitude 5250','Latitude 5450','Latitude 5550','Latitude 7250','Latitude 7350','Latitude 7450','Latitude E5250','Latitude E5450','Latitude E5550','Latitude E7250','Latitude E7350','Latitude E7450'}
        if ($DriverFamilyChild -eq 'Latitude E6XFR') {$ModelMatch = 'Latitude 5404','Latitude 7204','Latitude 7404'}
        if ($DriverFamilyChild -eq 'Latitude E7') {$ModelMatch = 'Latitude 3160','Latitude 3460','Latitude 3560'}

        if ($DriverFamilyChild -eq 'Latitude E8') {$ModelMatch = 'Latitude 3350','Latitude 3470','Latitude 3570','Latitude 7370','Latitude E3350','Latitude E5270','Latitude E5470','Latitude E5570','Latitude E7270','Latitude E7470'}
        if ($DriverFamilyChild -eq 'Latitude E8RUGGED') {$ModelMatch = 'Latitude 5414','Latitude 7214','Latitude 7414'}
        if ($DriverFamilyChild -eq 'Latitude E8TABLET') {$ModelMatch = 'Latitude 3379','Latitude 5175','Latitude 5179','Latitude 7275','Latitude E7275'}

        if ($DriverFamilyChild -eq 'Latitude E9') {$ModelMatch = 'Latitude 3180','Latitude 3189','Latitude 3380','Latitude 3480','Latitude 3580','Latitude 5280','Latitude 5289','Latitude 5480','Latitude 5580','Latitude 7380','Latitude 7389','Latitude 7280','Latitude 7480'}
        if ($DriverFamilyChild -eq 'Latitude E9RUGGED') {$ModelMatch = 'Latitude 7212'}
        if ($DriverFamilyChild -eq 'Latitude E9TABLET') {$ModelMatch = 'Latitude 5285','Latitude 7285'}

        if ($DriverFamilyChild -eq 'Latitude E10') {$ModelMatch = 'Latitude 3190','Latitude 3490','Latitude 3590','Latitude 5290','Latitude 5490','Latitude 5590','Latitude 7290','Latitude 7390','Latitude 7490'}
        if ($DriverFamilyChild -eq 'Latitude E10CFL') {$ModelMatch = 'Latitude 5491','Latitude 5495','Latitude 5591'}
        if ($DriverFamilyChild -eq 'Latitude E10RUGGED') {$ModelMatch = 'Latitude 5420','Latitude 5424','Latitude 7424'}
        if ($DriverFamilyChild -eq 'Latitude E10TABLET') {$ModelMatch = 'Latitude 3390'}

        if ($DriverFamilyChild -eq 'Latitude E11') {$ModelMatch = 'Latitude 3300'}
        if ($DriverFamilyChild -eq 'Latitude E11WHL') {$ModelMatch = 'Latitude 3400','Latitude 3500','Latitude 5300','Latitude 5400','Latitude 5500'}
        if ($DriverFamilyChild -eq 'Latitude E11WHL2') {$ModelMatch = 'Latitude 7200','Latitude 7300','Latitude 7400'}
        if ($DriverFamilyChild -eq 'Latitude E11WHL3301') {$ModelMatch = 'Latitude 3301'}
        if ($DriverFamilyChild -eq 'Latitude E11WHL5x01') {$ModelMatch = 'Latitude 5401','Latitude 5501'}
        #===================================================================================================
        #   Model OptiPlex
        #===================================================================================================
        if ($DriverFamilyChild -match 'OptiPlex') {
            $IsLaptop = $false
            $IsDesktop = $true
        }
        if ($DriverFamilyChild -eq 'OptiPlex D1') {$ModelEq = 'OptiPlex 360','OptiPlex 760','OptiPlex 760'} #Win7
        if ($DriverFamilyChild -eq 'OptiPlex D2') {$ModelEq = 'OptiPlex 380','OptiPlex 780','OptiPlex 980','OptiPlex XE'} #Win7
        if ($DriverFamilyChild -eq 'OptiPlex D3') {$ModelEq = 'OptiPlex 390','OptiPlex 790','OptiPlex 990'} #Win7

        if ($DriverFamilyChild -eq 'OptiPlex D4') {$ModelMatch = 'OptiPlex 3010','OptiPlex 7010','OptiPlex 9010'}
        if ($DriverFamilyChild -eq 'OptiPlex D5') {$ModelEq = 'OptiPlex 3020','OptiPlex 9020','OptiPlex XE2'}
        if ($DriverFamilyChild -eq 'OptiPlex D6') {$ModelMatch = 'OptiPlex 3020M','OptiPlex 3030','OptiPlex 7020','OptiPlex 9020M','OptiPlex 9030'}
        if ($DriverFamilyChild -eq 'OptiPlex D7') {$ModelMatch = 'OptiPlex 3040','OptiPlex 3046','OptiPlex 3240','OptiPlex 5040','OptiPlex 7040','OptiPlex 7440'}
        if ($DriverFamilyChild -eq 'OptiPlex D8') {
            $ModelMatch = 'OptiPlex 3050','OptiPlex 5050','OptiPlex 5055','OptiPlex 5250','OptiPlex 7050','OptiPlex 7450'
            $ModelNotMatch = '5055r'
        }
        if ($DriverFamilyChild -eq 'OptiPlex D9') {$ModelMatch = 'OptiPlex 3060','OptiPlex 5060','OptiPlex 5260','OptiPlex 7060','OptiPlex 7460','OptiPlex 7760','OptiPlex XE3'}
        if ($DriverFamilyChild -eq 'OptiPlex D9MLK') {$ModelMatch = 'OptiPlex 3070','OptiPlex 5070','OptiPlex 5270','OptiPlex 7070','OptiPlex 7470','OptiPlex 7770'}
        
        if ($DriverFamilyChild -eq 'OptiPlex 5055') {$ModelEq = 'OptiPlex 5055'}
        if ($DriverFamilyChild -eq 'OptiPlex 5055R') {$ModelEq = 'OptiPlex 5055R'}
        #===================================================================================================
        #   Model Precision M
        #===================================================================================================
        if ($DriverFamilyChild -match 'Precision M') {
            $IsLaptop = $true
            $IsDesktop = $false
        }
        if ($DriverFamilyChild -eq 'Precision M3800') {$ModelMatch = 'Precision M3800'}
        if ($DriverFamilyChild -eq 'Precision M5') {$ModelMatch = 'Precision M2800','Precision M4800','Precision M6800'}
        if ($DriverFamilyChild -eq 'Precision M6') {$ModelMatch = 'Precision 3510','Precision 5510','Precision 7510','Precision 7710','XPS*9550'}
        if ($DriverFamilyChild -eq 'Precision M7') {$ModelMatch = 'Precision 3520','Precision 5520','Precision 7520','Precision 7720'}
        if ($DriverFamilyChild -eq 'Precision M8') {$ModelMatch = 'Precision 3530','Precision 5530','Precision 7530','Precision 7730'}
        if ($DriverFamilyChild -eq 'Precision M8WHL') {$ModelMatch = 'Precision 3540'}
        if ($DriverFamilyChild -eq 'Precision M9') {$ModelMatch = 'Precision 3541'}
        if ($DriverFamilyChild -eq 'Precision M9CFLR5540') {$ModelMatch = 'Precision 5540'}
        if ($DriverFamilyChild -eq 'Precision M9MLK') {$ModelMatch = 'Precision 7540','Precision 7740'}
        #===================================================================================================
        #   Model Precision M
        #===================================================================================================
        if ($DriverFamilyChild -match 'Precision W') {
            $IsLaptop = $false
            $IsDesktop = $true
        }
        if ($DriverFamilyChild -eq 'Precision WS5') {$ModelMatch = 'Precision T1700'}
        if ($DriverFamilyChild -eq 'Precision WS6') {$ModelMatch = 'Precision 5810','Precision T5810','Precision 7810','Precision T7810','Precision 7910','Precision R7910','Precision T7910'}
        if ($DriverFamilyChild -eq 'Precision WS7') {$ModelMatch = 'Precision 3420','Precision 3620'}
        if ($DriverFamilyChild -eq 'Precision WS8') {$ModelMatch = 'Precision 5720','Precision 5820','Precision 7820','Precision 7920'}
        if ($DriverFamilyChild -eq 'Precision WS9') {$ModelMatch = 'Precision 3430','Precision 3630','Precision 3930'}
        if ($DriverFamilyChild -eq 'Precision WS9CFL3431') {$ModelMatch = 'Precision 3431'}
        #===================================================================================================
        #   Model Venue Pro
        #===================================================================================================
        if ($DriverFamilyChild -match 'Venue') {
            $IsLaptop = $true
            $IsDesktop = $false
        }
        if ($DriverFamilyChild -eq 'Venue PRO2') {$ModelMatch = 'Venue 8 Pro 5830','Venue 11 Pro 5130','Venue 11 Pro 7130','Venue 11 Pro 7139'}
        if ($DriverFamilyChild -eq 'Venue PRO3') {$ModelMatch = 'Venue 11 Pro 7140'}
        if ($DriverFamilyChild -eq 'Venue PRO4') {$ModelMatch = 'Venue 5056','Venue 10PRO5056','Venue5855','Venue 8PRO5855'}
        #===================================================================================================
        #   Model Vostro
        #===================================================================================================
        if ($DriverFamilyChild -match 'Vostro') {
            $IsLaptop = $true
            $IsDesktop = $false
        }
        if ($DriverFamilyChild -eq 'Vostro D8') {$ModelMatch = 'CHENGMING 3967','CHENGMING 3968'}
        if ($DriverFamilyChild -eq 'Vostro D9') {$ModelMatch = 'CHENGMING 3980'}
        #===================================================================================================
        #   Model XPS
        #===================================================================================================
        if ($DriverFamilyChild -match 'XPS NOTEBOOK') {
            $IsLaptop = $true
            $IsDesktop = $false
        }
        if ($DriverFamilyChild -eq 'XPS NOTEBOOK1') {$ModelMatch = 'XPS 9530'}
        if ($DriverFamilyChild -eq 'XPS NOTEBOOK3') {$ModelMatch = 'XPS 9343'}
        if ($DriverFamilyChild -eq 'XPS NOTEBOOK4') {$ModelMatch = 'XPS 9250','XPS 9350'}
        if ($DriverFamilyChild -eq 'XPS NOTEBOOK5') {$ModelMatch = 'XPS 9360','XPS 9365','XPS 9560'}
        if ($DriverFamilyChild -eq 'XPS NOTEBOOK6') {$ModelMatch = 'XPS 9370','XPS 9570','XPS 9575'}
        if ($DriverFamilyChild -eq 'XPS NOTEBOOK7') {$ModelMatch = 'XPS 9380'}
        if ($DriverFamilyChild -eq 'XPS NOTEBOOK8') {$ModelMatch = 'XPS 7590'}
        #===================================================================================================
        #   LastUpdate
        #===================================================================================================
        $LastUpdateRaw = ((($ContentLine.Split('<>')[6]).Trim()).Split(' ')[0,1])
        $LastUpdate = [datetime]::ParseExact($LastUpdateRaw, "dd-MMM-yyyy HH:mm", $null)
        #===================================================================================================
        #   DriverName
        #===================================================================================================
        $DriverName = "$OSDGroup $DriverFamily $DriverChild $OSNameMatch $DriverVersion"
        #if ($OSArch) {$DriverName = "$OSDGroup $DriverFamily $DriverChild $OSNameMatch $OSArch $DriverVersion"}
        #===================================================================================================
        #   DriverGrouping
        #===================================================================================================
        $DriverGrouping = "$DriverFamily $DriverChild $OSNameMatch"
        #===================================================================================================
        #   DriverDescription
        #===================================================================================================
        $DriverDescription = ''
        #===================================================================================================
        #   FileType
        #===================================================================================================
        $FileType = $DriverPackFile.split('.')[1]
        $FileType = $FileType.ToLower()
        #===================================================================================================
        #   FileType
        #===================================================================================================
        $FileName = Split-Path $DriverUrl -Leaf
        $FileName = $FileName.split('.')[1]
        $FileType = $FileName.ToLower()
        #===================================================================================================
        #   DownloadFile
        #===================================================================================================
        $OSNameEdit = $OSNameMatch
        $OSNameEdit = $OSNameEdit.Replace('.','')
        $DownloadFile = "$OSNameEdit`_$DriverFamily$DriverChild`_$DriverVersion.$FileType"
        #===================================================================================================
        #   DriverInfo
        #===================================================================================================
        $DriverInfo = 'https://www.dell.com/support/article/us/en/04/how13322/dell-family-driver-packs?lang=en'
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
    #===================================================================================================
    #   Select-Object
    #===================================================================================================
    $DriverResults = $DriverResults | Select-Object LastUpdate, `
    OSDVersion,OSDStatus,OSDGroup,OSDType,`
    DriverName, DriverVersion, DriverGrouping,`
    #OSNameMatch,OSNameNotMatch,`
    OSVersionMatch, OSArchMatch,`
    DriverFamilyChild, DriverFamily, DriverChild,`
    IsDesktop,IsLaptop,`
    #IsServer,`
    #MakeLike, MakeNotLike,`
    MakeMatch,`
    #MakeNotMatch,`
    #ModelLike, ModelNotLike,`
    ModelMatch, ModelNotMatch, ModelEq,`
    #ModelNe,`
    #SystemFamilyMatch, SystemFamilyNotMatch,`
    #SystemSkuMatch, SystemSkuNotMatch,`
    #OSNameNotMatch, OSArchNotMatch, OSVersionNotMatch, OSBuildGE, OSBuildLE,`
    OSInstallationType,`
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
    $DriverResults = $DriverResults | Sort-Object DriverName -Descending
    $CurrentOSDDriverDellFamily = @()
    foreach ($FamilyPack in $DriverResults) {
        if ($CurrentOSDDriverDellFamily.DriverGrouping -match $FamilyPack.DriverGrouping) {
            $FamilyPack.IsSuperseded = $true
        } else { 
            $CurrentOSDDriverDellFamily += $FamilyPack
        }
    }
    $DriverResults = $DriverResults | Where-Object {$_.IsSuperseded -eq $false}
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