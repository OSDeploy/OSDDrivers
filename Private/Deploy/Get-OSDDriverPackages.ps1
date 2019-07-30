function Get-OSDDriverPackages {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$PublishPath
    )
    #===================================================================================================
    #   Get OSDDriver Packages
    #===================================================================================================
    $OSDDriverPackages = @()
    $OSDDriverPackages = Get-ChildItem -Path "$PublishPath" -Include *.cab,*.zip -File -Recurse | Select-Object -Property *
    #===================================================================================================
    #   Get OSDDriver Packages
    #===================================================================================================
    Return $OSDDriverPackages
}