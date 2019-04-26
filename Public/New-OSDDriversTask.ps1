function New-OSDDriversTask {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [string]$CabFullName,

        [ValidateSet('Any','Windows7','Windows10','Server2016','Server2019')]
        [string[]]$OperatingSystem = 'Any',

        [ValidateSet('Any','6.1','6.2','6.3','10')]
        [string]$OSVersionMin = 'Any',

        [ValidateSet('Any','6.1','6.2','6.3','10')]
        [string]$OSVersionMax = 'Any',

        [ValidateSet('Any','1507','1511','1607','1703','1709','1803','1809','1903')]
        [string]$OSBuildMin,

        [ValidateSet('Any','1507','1511','1607','1703','1709','1803','1809','1903')]
        [string]$OSBuildMax,

        [ValidateSet('Any','x64','x86')]
        [string]$OSArch = 'Any',

        [string[]]$MakeLike = 'Any',
        [string[]]$MakeNotLike = 'Any',
        [string[]]$ModelLike = 'Any',
        [string[]]$ModelNotLike = 'Any'
    )

    begin {
        $global:OSDDriversVersion = $(Get-Module -Name OSDDrivers | Sort-Object Version | Select-Object Version -Last 1).Version
    }

    process {
        $Cab = Get-Item "$CabFullName" -ErrorAction Stop | Select-Object -Property *

        $TaskName = $Cab.BaseName
        $TaskFileName = "$TaskName.json"
        $TaskFullName = Join-Path "$($Cab.DirectoryName)" "$TaskFileName"
        #===================================================================================================
        #   Task
        #===================================================================================================
        $Task = [ordered]@{
            "TaskVersion"       = [string] $OSDDriversVersion;
            "TaskGuid"          = [string] $(New-Guid);
            "TaskName"          = [string] $TaskName;
            "TaskCab"           = [string] $Cab.Name;

            "MakeLike"          = [string[]] $MakeLike;
            "MakeNotLike"       = [string[]] $MakeNotLike;
            "ModelLike"         = [string[]] $ModelLike;
            "ModelNotLike"      = [string[]] $ModelNotLike;
            "OperatingSystem"   = [string[]] $OperatingSystem;
            "OSVersionMin"      = [string] $OSVersionMin;
            "OSVersionMax"      = [string] $OSVersionMax;
            "OSBuildMin"        = [string] $OSBuildMin;
            "OSBuildMax"        = [string] $OSBuildMax;
        }

        #===================================================================================================
        #   Complete
        #===================================================================================================
        Write-Host '========================================================================================' -ForegroundColor DarkGray
        Write-Host "OSDDrivers Task: $TaskName" -ForegroundColor Green
        $Task | ConvertTo-Json | Out-File "$TaskFullName"
        $Task
    }

    end {
        
    }

}