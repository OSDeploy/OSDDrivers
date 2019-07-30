function New-OSDDriverTask {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$OSDDriverFile,

        [string]$OSDGroup = 'Custom',
        [string]$DriverVersion = '1.0',

        [ValidateSet('Client','Server')]
        [string]$OSInstallationType,

        [string[]]$MakeLike,
        [string[]]$MakeNotLike,
        [string[]]$MakeMatch,
        [string[]]$MakeNotMatch,

        [string[]]$ModelLike,
        [string[]]$ModelNotLike,
        [string[]]$ModelMatch,
        [string[]]$ModelNotMatch,
        [string[]]$ModelEq,
        [string[]]$ModelNe,

        [string[]]$SystemFamilyMatch,
        [string[]]$SystemFamilyNotMatch,

        [string[]]$SystemSkuMatch,
        [string[]]$SystemSkuNotMatch,
        [ValidateSet('Win7','Win8.1','Win10')]
        [string[]]$OSNameMatch,
        [string[]]$OSNameNotMatch,
        [ValidateSet('x64','x86')]
        [string[]]$OSArchMatch,
        [ValidateSet('x64','x86')]
        [string[]]$OSArchNotMatch,

        [ValidateSet('6.1','6.2','6.3','10.0')]
        [string[]]$OSVersionMatch,
        [ValidateSet('6.1','6.2','6.3','10.0')]
        [string[]]$OSVersionNotMatch,
        [string]$OSBuildGE,
        [string]$OSBuildLE,
        [ValidateSet('Bluetooth','Camera','Display','HDC','HIDClass','Keyboard','Media','Monitor','Mouse','Net','SCSIAdapter','SmartCardReader','System','USBDevice')]
        [string]$OSDPnpClass
    )

    Begin {}

    Process {
        #===================================================================================================
        #   Generate Task
        #===================================================================================================
        try {
            $OSDDriver = Get-Item "$OSDDriverFile" -ErrorAction Stop | Select-Object -Property *
        }
        catch {
            Write-Error "Could not find the OSDDriver at $OSDDriver" -ErrorAction Stop
            Break
        }

        $DriverName = $OSDDriver.BaseName
        $DrvTaskFile = "$DriverName.drvtask"
        $PnpFile = "$DriverName.drvpnp"
        
        $DriverPnpFullName = Join-Path "$($OSDDriver.DirectoryName)" "$PnpFile"
        $DriverTaskFullName = Join-Path "$($OSDDriver.DirectoryName)" "$DrvTaskFile"

        #===================================================================================================
        #   Defaults
        #===================================================================================================
        $LastUpdate = [datetime] $(Get-Date)
        $OSDVersion = $(Get-Module -Name OSDDrivers | Sort-Object Version | Select-Object Version -Last 1).Version
        $OSDStatus = $null
        #$OSDGroup = $null
        $OSDType = 'Driver'

        $IsDesktop = $null
        $IsLaptop = $null
        $IsServer = $null

        #$DriverName = $null
        #$DriverVersion = $null
        $DriverGrouping = $null

        $DriverFamilyChild = $null
        $DriverFamily = $null
        $DriverChild = $null

        #$OSDPnpClass = $null
        if ($OSDPnpClass -eq 'Net') {$OSDPnpClassGuid = '{4D36E968-E325-11CE-BFC1-08002BE10318}'}
        #$OSDPnpClassGuid = $null

        $DriverBundle = $null
        $DriverWeight = 100
        
        $DownloadFile = $null
        $OSDPnpFile = "$($DriverName).drvpnp"
        $OSDCabFile = "$($DriverName).cab"
        $OSDTaskFile = "$($DriverName).drvtask"
        $FileType = 'zip'
        $SizeMB = $null
        $IsSuperseded = $false

        $DriverUrl = $null
        $DriverDescription = $null
        $DriverInfo = $DriverLink.href
        $DriverCleanup = @()
        $OSDGuid = $(New-Guid)
        #===================================================================================================
        #   Task
        #===================================================================================================
        $Task = [ordered]@{
            LastUpdate              = [datetime] $LastUpdate
            OSDVersion              = [string] $OSDVersion
            OSDStatus               = [string] $OSDStatus
            OSDGroup                = [string] $OSDGroup
            OSDType                 = [string] $OSDType

            DriverName              = [string] $DriverName
            DriverVersion           = [string] $DriverVersion
            #DriverGrouping          = [string] $DriverGrouping

            #DriverFamilyChild       = [string] $DriverFamilyChild
            #DriverFamily            = [string] $DriverFamily
            #DriverChild             = [string] $DriverChild

            #IsDesktop               = [bool]$IsDesktop
            #IsLaptop                = [bool]$IsLaptop
            #IsServer                = [bool]$IsServer

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

            #SystemFamilyMatch       = [array[]] $SystemFamilyMatch
            #SystemFamilyNotMatch    = [array[]] $SystemFamilyNotMatch

            #SystemSkuMatch          = [array[]] $SystemSkuMatch
            #SystemSkuNotMatch       = [array[]] $SystemSkuNotMatch

            #OSNameMatch             = [array[]] $OSNameMatch
            #OSNameNotMatch          = [array[]] $OSNameNotMatch
            OSVersionMatch          = [array[]] $OSVersionMatch
            OSVersionNotMatch       = [array[]] $OSVersionNotMatch
            OSArchMatch             = [array[]] $OSArchMatch
            OSArchNotMatch          = [array[]] $OSArchNotMatch
            OSBuildGE               = [string] $OSBuildGE
            OSBuildLE               = [string] $OSBuildLE
            OSInstallationType		= [string] $OSInstallationType

            #OSDPnpClass             = [string] $OSDPnpClass
            #OSDPnpClassGuid         = [string] $OSDPnpClassGuid

            #DriverBundle            = [string] $DriverBundle
            #DriverWeight            = [int] $DriverWeight

            #DownloadFile            = [string] $DownloadFile
            #OSDPnpFile              = [string] $OSDPnpFile
            #OSDCabFile              = [string] $OSDCabFile
            #OSDTaskFile             = [string] $OSDTaskFile
            #FileType                = [string] $FileType
            #SizeMB                  = [int] $SizeMB
            #IsSuperseded            = [bool] $IsSuperseded

            #DriverUrl               = [string] $DriverUrl
            #DriverDescription       = [string] $DriverDescription
            #DriverInfo              = [string] $DriverInfo
            #DriverCleanup           = [array] $DriverCleanup
            OSDGuid                 = [string] $(New-Guid)
        }
        #===================================================================================================
        #   Complete
        #===================================================================================================
        Write-Host "Generating $DriverTaskFullName ..." -ForegroundColor DarkGray
        $Task | ConvertTo-Json | Out-File "$DriverTaskFullName"
        $Task
    }

    End {}
}