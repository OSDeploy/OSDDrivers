function New-OSDDriverTask {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [string]$OSDDriverFile,
        [string]$OSDGroup = 'Custom',
        [string]$DriverVersion = '1.0',
        [string]$DriverReleaseId = 'R0',

        [ValidateSet('x64','x86')]
        [string[]]$OsArch,

        [ValidateSet('6.1','6.2','6.3','10.0')]
        [string[]]$OsVersion,

        [string[]]$Make,

        [string[]]$Model
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
        $drvpackFile = "$DriverName.drvpack"
        
        $DriverTaskFullName = Join-Path "$($OSDDriver.DirectoryName)" "$drvpackFile"
        #===================================================================================================
        #   Defaults
        #===================================================================================================
        $OSDVersion = $(Get-Module -Name OSDDrivers | Sort-Object Version | Select-Object Version -Last 1).Version
        $LastUpdate = [datetime] $(Get-Date)
        $OSDStatus = $null
        $OSDType = 'Driver'
        #$OSDGroup = 'Custom'

        #$DriverName = ''
        #$DriverVersion = $null
        #$DriverReleaseId = $null
        $DriverGrouping = $null

        #$OperatingSystem = @()
        #$OsVersion = @()
        #$OsArch = @()
        #$OsBuildMax = @()
        #$OsBuildMin = @()
        $Make = @()
        if ($DriverName -match 'Dell') {$Make = 'Dell'}
        $MakeNe = @()
        $MakeLike = @()
        $MakeNotLike = @()
        $MakeMatch = @()
        $MakeNotMatch = @()

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
        #   Task
        #===================================================================================================
        $Task = [ordered]@{
            OSDVersion              = [string] $OSDVersion
            LastUpdate              = [datetime] $LastUpdate
            OSDStatus               = [string] $OSDStatus
            OSDType                 = [string] $OSDType
            OSDGroup                = [string] $OSDGroup

            DriverName              = [string] $DriverName
            DriverVersion           = [string] $DriverVersion
            DriverReleaseId         = [string] $DriverReleaseID

            #OperatingSystem         = [array] $OperatingSystem
            OsVersion               = [string] $OsVersion
            OsArch                  = [array[]] $OsArch
            #OsBuildMax              = [string] $OsBuildMax
            #OsBuildMin              = [string] $OsBuildMin

            Make                    = [array[]] $Make
            #MakeNe                  = [array[]] $MakeNe
            #MakeLike                = [array[]] $MakeLike
            #MakeNotLike             = [array[]] $MakeNotLike
            #MakeMatch               = [array[]] $MakeMatch
            #MakeNotMatch            = [array[]] $MakeNotMatch

            #Generation              = [string] $Generation
            #SystemFamily            = [string] $SystemFamily

            #Model                   = [array[]] $Model
            #ModelNe                 = [array[]] $ModelNe
            #ModelLike               = [array[]] $ModelLike
            #ModelNotLike            = [array[]] $ModelNotLike
            #ModelMatch              = [array[]] $ModelMatch
            #ModelNotMatch           = [array[]] $ModelNotMatch

            #SystemSku               = [array[]] $SystemSku
            #SystemSkuNe             = [array[]] $SystemSkuNe

            #DriverGrouping          = [string] $DriverGrouping
            #DriverBundle            = [string] $DriverBundle
            #DriverWeight            = [int] $DriverWeight

            #DownloadFile            = [string] $DownloadFile
            #SizeMB                  = [int] $SizeMB
            #DriverUrl               = [string] $DriverUrl
            #DriverInfo              = [string] $DriverInfo
            #DriverDescription       = [string] $DriverDescription
            #Hash                    = [string] $Hash
            OSDGuid                 = [string] $OSDGuid
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