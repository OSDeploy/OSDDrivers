function Get-PathOSDD {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Path
    )

    if (-not(Test-Path "$Path")) {
        try {New-Item -Path "$Path" -ItemType Directory -Force -ErrorAction Stop | Out-Null}
        catch {Write-Error "Could not create the OSDDrivers Directory at $Path" -ErrorAction Stop}
    }

    try {Get-Item -Path "$Path" -ErrorAction Stop | Out-Null}
    catch {Write-Error "Could not get the OSDDrivers Directory at $Path" -ErrorAction Stop}

    $PathOSDD = (Get-Item "$Path").FullName
    Return $PathOSDD
}
function Get-DirectoryName {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$DriverPath
    )

    $DirectoryName = (Get-Item "$DriverPath").Name
    Return $DirectoryName
}
function Get-ParentDirectoryFullName {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$DriverPath
    )

    $ParentDirectoryFullName = (Get-Item "$DriverPath").parent.FullName
    Return $ParentDirectoryFullName
}
function Test-DriverPath {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$DriverPath
    )

    try {Get-Item -Path $DriverPath -ErrorAction Stop | Out-Null}
    catch {Write-Error "Could not find the DriverPath at $DriverPath" -ErrorAction Stop}
}
function Test-ExpandedDriverPath {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$ExpandedDriverPath
    )

    try {Get-Item -Path $ExpandedDriverPath -ErrorAction Stop | Out-Null}
    catch {Write-Error "Could not find the ExpandedDriverPath at $ExpandedDriverPath" -ErrorAction Stop}
}