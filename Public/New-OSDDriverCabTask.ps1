function New-OSDDriverCabTask {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [string]$DriverCabPath,

        [ValidateSet('x64','x86')]
        [string]$OSArch,

        [string]$OSBuildMin,
        [string]$OSBuildMax,

        [ValidateSet('Client','Server')]
        [string]$OSInstallationType,

        [ValidateSet('6.1','6.2','6.3','10.0')]
        [string]$OSVersionMin,

        [ValidateSet('6.1','6.2','6.3','10.0')]
        [string]$OSVersionMax,

        [string[]]$MakeLike,
        [string[]]$MakeNotLike,
        [string[]]$ModelLike,
        [string[]]$ModelNotLike
    )

    begin {
        #===================================================================================================
        #   OSDDriversVersion
        #===================================================================================================
        $OSDDriversVersion = $(Get-Module -Name OSDDrivers | Sort-Object Version | Select-Object Version -Last 1).Version
    }

    process {
        #===================================================================================================
        #   Generate Task
        #===================================================================================================
        $DriverCabFile = Get-Item "$DriverCabPath" -ErrorAction Stop | Select-Object -Property *

        $TaskName = $DriverCabFile.BaseName
        $TaskFileName = "$TaskName.cab.task"
        $DriverPnpFile = "$TaskName.cab.pnp"

        $TaskJsonFullName = Join-Path "$($DriverCabFile.DirectoryName)" "$TaskFileName"
        #===================================================================================================
        #   Task
        #===================================================================================================
        $Task = [ordered]@{
            "TaskType"          = [string] 'OSDDriver';
            "TaskVersion"       = [string] $OSDDriversVersion;
            "TaskName"          = [string] $TaskName;
            "TaskGuid"          = [string] $(New-Guid);
            "DriverCabFile"     = [string] $DriverCabFile.Name;
            "DriverPnpFile"     = [string] $DriverPnpFile;

            "OSArch"            = [string] $OSArch;
            "OSBuildMin"        = [string] $OSBuildMin;
            "OSBuildMax"        = [string] $OSBuildMax;
            "OSInstallationType"= [string] $OSInstallationType;
            "OSVersionMin"      = [string] $OSVersionMin;
            "OSVersionMax"      = [string] $OSVersionMax;

            "MakeLike"          = [string[]] $MakeLike;
            "MakeNotLike"       = [string[]] $MakeNotLike;
            "ModelLike"         = [string[]] $ModelLike;
            "ModelNotLike"      = [string[]] $ModelNotLike;

            
        }
        #===================================================================================================
        #   Complete
        #===================================================================================================
        Write-Host "Generating $TaskJsonFullName ..." -ForegroundColor DarkGray
        $Task | ConvertTo-Json | Out-File "$TaskJsonFullName"
        $Task
    }

    end {}
}