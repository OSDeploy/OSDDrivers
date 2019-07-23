function Get-OSDDriverTasks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$PublishPath,
        [switch]$GridView
    )

    begin {
        #===================================================================================================
        #   OSDVersion
        #===================================================================================================
        $OSDVersion = $(Get-Module -Name OSDDrivers | Sort-Object Version | Select-Object Version -Last 1).Version
        #===================================================================================================
        #   Get All Drivers Jsons
        #===================================================================================================
        $AllOSDDriverTasks = @()
        $AllOSDDriverTasks = Get-ChildItem -Path "$PublishPath" *.drvtask -File -Recurse | Select-Object -Property *
    }

    process {
        $OSDDriverTasks = @()
        foreach ($OSDDriverTask in $AllOSDDriverTasks) {
            #===================================================================================================
            #   
            #===================================================================================================
            $OSDDriverFullName = $OSDDriverTask.FullName
            Write-Verbose "OSDDriver Full Name: $OSDDriverFullName"

            $OSDDriver = @()
            $OSDDriver = Get-Content "$OSDDriverFullName" | ConvertFrom-Json

            $OSDDriver.OSDTaskFile = $OSDDriverFullName

            $OSDPnpFile = $OSDDriver.OSDPnpFile
            if ($OSDPnpFile) {
                if (Test-Path "$($OSDDriverTask.Directory)\$OSDPnpFile") {
                    $OSDDriver.OSDPnpFile = "$($OSDDriverTask.Directory)\$OSDPnpFile"
                }
            }

            $OSDPackageFile = $OSDDriver.OSDPackageFile
            if ($OSDPackageFile) {
                if (Test-Path "$($OSDDriverTask.Directory)\$OSDPackageFile") {
                    $OSDDriver.OSDPackageFile = "$($OSDDriverTask.Directory)\$OSDPackageFile"
                }
            }

            $OSDDriverTasks += $OSDDriver
        }

        #===================================================================================================
        #   Output
        #===================================================================================================

        $OSDDriverTasks = $OSDDriverTasks | Select-Object -Property *

        if ($GridView.IsPresent) {$OSDDriverTasks = $OSDDriverTasks | Out-GridView -PassThru -Title 'PSDriverTasks'}
        Return $OSDDriverTasks
    }

    end {}
}