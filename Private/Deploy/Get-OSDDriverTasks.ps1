function Get-OSDDriverTasks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$PublishPath,
        [switch]$GridView
    )

    #===================================================================================================
    #   Get OSDDriver Tasks
    #===================================================================================================
    $OSDDriverTasks = @()
    $OSDDriverTasks = Get-ChildItem -Path "$PublishPath" -Include *.drvpack -File -Recurse | Select-Object -Property *
    #===================================================================================================
    #   Get OSDDriver Packages
    #===================================================================================================
    Return $OSDDriverTasks


<#     $OSDDriverTasks = @()
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
    } #>
}