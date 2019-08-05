function Get-OSDDriverMultiPacks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$PublishPath
    )
    #===================================================================================================
    #   Get OSDDriver Packages
    #===================================================================================================
    $OSDDriverMultiPacks = @()
    $OSDDriverMultiPacks = Get-ChildItem -Path "$PublishPath" -Include *.multipack -File -Recurse | Select-Object -Property *
    #===================================================================================================
    #   Get OSDDriver Packages
    #===================================================================================================
    Return $OSDDriverMultiPacks
}