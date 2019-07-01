function Get-OSDDrivers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$PackagePath,
        [switch]$GridView
    )

    begin {
        $global:OSDDriversVersion = $(Get-Module -Name OSDDrivers | Sort-Object Version | Select-Object Version -Last 1).Version

        #===================================================================================================
        #   Get All Drivers Jsons
        #===================================================================================================
        $OSDDriverJsons = @()
        $OSDDriverJsons = Get-ChildItem -Path "$PackagePath" *.cab.task -File -Recurse | Select-Object -Property *
    }

    process {
        $OSDDrivers = foreach ($Item in $OSDDriverJsons) {
            #===================================================================================================
            #   
            #===================================================================================================
            $OSDDriverTaskPath = $($Item.FullName)
            Write-Verbose "OSDDriverTask Full Path: $OSDDriverTaskPath"
            $OSDDTask = @()
            $OSDDTask = Get-Content "$($Item.FullName)" | ConvertFrom-Json

            $OSDDTaskProps = @()
            $OSDDTaskProps = Get-Item "$($Item.FullName)" | Select-Object -Property *

            $DriverCabFile = $OSDDTask.DriverCabFile
            $DriverCabFileFullName = "$($Item.Directory)\$DriverCabFile"
            if (Test-Path "$DriverCabFileFullName") {$DriverCabFile = 'Ready'}
            else {$DriverCabFile = 'Missing'}

            $DriverPnpFile = $OSDDTask.DriverPnpFile
            $DriverPnpFullName = "$($Item.Directory)\$DriverPnpFile"
            if (Test-Path "$DriverPnpFullName") {$DriverPnpFile = 'Detect'}
            else {$DriverPnpFile = $null}

            $ObjectProperties = @{
                TaskType            = $OSDDTask.TaskType
                TaskVersion         = [version]$OSDDTask.TaskVersion
                TaskName            = $OSDDTask.TaskName
                TaskGuid            = $OSDDTask.TaskGuid
                DriverCabFile       = $DriverCabFile
                DriverCabFullName   = $DriverCabFileFullName
                DriverPnpFile       = $DriverPnpFile
                DriverPnpFullName   = $DriverPnpFullName

                OSInstallationType  = $OSDDTask.OSInstallationType
                OSArch              = $OSDDTask.OSArch
                OSVersionMin        = $OSDDTask.OSVersionMin
                OSVersionMax        = $OSDDTask.OSVersionMax
                OSBuildMin          = $OSDDTask.OSBuildMin
                OSBuildMax          = $OSDDTask.OSBuildMax

                MakeLike            = $OSDDTask.MakeLike
                MakeNotLike         = $OSDDTask.MakeNotLike
                ModelLike           = $OSDDTask.ModelLike
                ModelNotLike        = $OSDDTask.ModelNotLike
            }
            New-Object -TypeName PSObject -Property $ObjectProperties
            Write-Verbose ""
        }

        #===================================================================================================
        #Write-Verbose '19.1.3 Output'
        #===================================================================================================
        $OSDDrivers = $OSDDrivers | Select-Object -Property TaskType,TaskVersion,TaskName,DriverCabFile,DriverPnpFile,OSInstallationType,OSArch,OSVersionMin,OSVersionMax,OSBuildMin,OSBuildMax,MakeLike,MakeNotLike,ModelLike,ModelNotLike,TaskGuid,DriverCabFullName,DriverPnpFullName | Sort-Object TaskName

        if ($GridView.IsPresent) {$OSDDrivers = $OSDDrivers | Out-GridView -PassThru -Title 'OSDDrivers'}

        Return $OSDDrivers
    }

    end {}
}