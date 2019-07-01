function New-OSDDriverTask {
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
        Write-Host '========================================================================================' -ForegroundColor DarkGray
        Write-Host "$($MyInvocation.MyCommand.Name) BEGIN" -ForegroundColor Green
        $global:OSDDriversVersion = $(Get-Module -Name OSDDrivers | Sort-Object Version | Select-Object Version -Last 1).Version
    }

    process {
        $DriverCabFile = Get-Item "$DriverCabPath" -ErrorAction Stop | Select-Object -Property *

        $TaskName = $DriverCabFile.BaseName
        $TaskFileName = "$TaskName.cab.json"
        $DriverPnpFile = "$TaskName.pnp.xml"

        $TaskJsonFullName = Join-Path "$($DriverCabFile.DirectoryName)" "$TaskFileName"
        #===================================================================================================
        #   Task
        #===================================================================================================
        $Task = [ordered]@{
            "TaskType"          = [string] 'OSDDriver';
            "TaskVersion"       = [string] $OSDDriversVersion;
            "TaskName"          = [string] $TaskName;
            "TaskGuid"          = [string] $(New-Guid);
            "DriverCabFile"     = [string] $DriverCabFile;
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
        Write-Host '========================================================================================' -ForegroundColor DarkGray
        Write-Host "OSDDrivers Task: $TaskName" -ForegroundColor Green
        $Task | ConvertTo-Json | Out-File "$TaskJsonFullName"
        $Task
    }

    end {
        Write-Host '========================================================================================' -ForegroundColor DarkGray
        Write-Host "$($MyInvocation.MyCommand.Name) END" -ForegroundColor Green
    }
}