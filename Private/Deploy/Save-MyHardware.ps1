function Save-MyHardware {
    [CmdletBinding()]
    PARAM (
        [Parameter(Position = 0)]
        [string]$ExpandDriverPath = 'C:\Drivers'
    )
    #===================================================================================================
    #   ExpandDriverPath
    #===================================================================================================
    if (-not(Test-Path "$ExpandDriverPath")) {New-Item -Path "$ExpandDriverPath" -ItemType Directory -Force | Out-Null}
    #===================================================================================================
    #   MyHardware
    #===================================================================================================
    Write-Verbose "Generating MyHardware ..." -Verbose

    $MyHardware = @()
    $MyHardware = Get-MyHardware
    #$MyHardware = $MyHardware | Sort-Object -Property DeviceID -Unique
    
    Write-Verbose "Exporting $ExpandDriverPath\MyHardware.csv ..." -Verbose
    $MyHardware | Export-Csv -Path "$ExpandDriverPath\MyHardware.csv"

    Write-Verbose "Exporting $ExpandDriverPath\MyHardware.xml ..." -Verbose
    $MyHardware | Export-Clixml -Path "$ExpandDriverPath\MyHardware.xml"

    #Write-Host ""
    #Write-Host "Devices:"

    #foreach ($HardwareDevice in $MyHardware) {
        #Write-Host "$($HardwareDevice.DeviceID) - $($HardwareDevice.Caption)" -ForegroundColor DarkGray
    #}

    $MyHardwareExport = "$ExpandDriverPath\MyHardware.xml"
    Return $MyHardwareExport
}