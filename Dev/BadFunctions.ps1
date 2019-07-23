


function Test-DownloadPath {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$DownloadPath
    )

    if (-not(Test-Path "$DownloadPath")) {
        try {New-Item -Path "$DownloadPath" -ItemType Directory -Force -ErrorAction Stop | Out-Null}
        catch {Write-Error "Could not create the DownloadPath at $DownloadPath" -ErrorAction Stop}
    }
}
function Test-PublishPath {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$PublishPath
    )

    if (-not(Test-Path "$PublishPath")) {
        try {New-Item -Path "$PublishPath" -ItemType Directory -Force -ErrorAction Stop | Out-Null}
        catch {Write-Error "Could not create the PublishPath at $PublishPath" -ErrorAction Stop}
    }
}


<# 
    if (-not(Test-Path "$Workspace\$OSDGroup")) {
        try {New-Item -Path "$Workspace\$OSDGroup" -ItemType Directory -Force -ErrorAction Stop | Out-Null}
        catch {Write-Error "Could not create $Workspace\$OSDGroup" -ErrorAction Stop}
    }
    if (-not(Test-Path "$Workspace\$OSDGroup\Download")) {
        try {New-Item -Path "$Workspace\$OSDGroup\Download" -ItemType Directory -Force -ErrorAction Stop | Out-Null}
        catch {Write-Error "Could not create the Workspace at $Workspace\$OSDGroup\Download" -ErrorAction Stop}
    }
    if (-not(Test-Path "$Workspace\$OSDGroup\Expand")) {
        try {New-Item -Path "$Workspace\$OSDGroup\Expand" -ItemType Directory -Force -ErrorAction Stop | Out-Null}
        catch {Write-Error "Could not create the Workspace at $Workspace\$OSDGroup\Expand" -ErrorAction Stop}
    }
    if (-not(Test-Path "$Workspace\$OSDGroup\Pack")) {
        try {New-Item -Path "$Workspace\$OSDGroup\Pack" -ItemType Directory -Force -ErrorAction Stop | Out-Null}
        catch {Write-Error "Could not create the Workspace at $Workspace\$OSDGroup\Pack" -ErrorAction Stop}
    }
    if (-not(Test-Path "$Workspace\$OSDGroup\Publish")) {
        try {New-Item -Path "$Workspace\$OSDGroup\Publish" -ItemType Directory -Force -ErrorAction Stop | Out-Null}
        catch {Write-Error "Could not create the WorkspacePath at $Workspace\$OSDGroup\Publish" -ErrorAction Stop}
    }
 #>

function Test-WorkspaceDriver {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$WorkspacePath
    )

    if (-not(Test-Path "$WorkspacePath")) {
        try {New-Item -Path "$WorkspacePath" -ItemType Directory -Force -ErrorAction Stop | Out-Null}
        catch {Write-Error "Could not create the WorkspacePath at $WorkspacePath" -ErrorAction Stop}
    }
    if (-not(Test-Path "$WorkspacePath\Driver")) {
        try {New-Item -Path "$WorkspacePath\Driver" -ItemType Directory -Force -ErrorAction Stop | Out-Null}
        catch {Write-Error "Could not create $WorkspacePath\Driver" -ErrorAction Stop}
    }
    if (-not(Test-Path "$WorkspacePath\Driver\Download")) {
        try {New-Item -Path "$WorkspacePath\Driver\Download" -ItemType Directory -Force -ErrorAction Stop | Out-Null}
        catch {Write-Error "Could not create the WorkspacePath at $WorkspacePath\Driver\Download" -ErrorAction Stop}
    }
    if (-not(Test-Path "$WorkspacePath\Driver\Expand")) {
        try {New-Item -Path "$WorkspacePath\Driver\Expand" -ItemType Directory -Force -ErrorAction Stop | Out-Null}
        catch {Write-Error "Could not create the WorkspacePath at $WorkspacePath\Driver\Expand" -ErrorAction Stop}
    }
    if (-not(Test-Path "$WorkspacePath\Driver\Publish")) {
        try {New-Item -Path "$WorkspacePath\Driver\Publish" -ItemType Directory -Force -ErrorAction Stop | Out-Null}
        catch {Write-Error "Could not create the WorkspacePath at $WorkspacePath\Driver\Publish" -ErrorAction Stop}
    }
}


function Test-WorkspacePath {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$WorkspacePath

        #[Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        #$OSDGroup
    )

    if (-not(Test-Path "$WorkspacePath")) {
        try {New-Item -Path "$WorkspacePath" -ItemType Directory -Force -ErrorAction Stop | Out-Null}
        catch {Write-Error "Could not create the WorkspacePath at $WorkspacePath" -ErrorAction Stop}
    }

    try {Get-Item -Path "$WorkspacePath" -ErrorAction Stop | Out-Null}
    catch {Write-Error "Could not get the WorkspacePath at $WorkspacePath" -ErrorAction Stop}

    $Workspace = (Get-Item "$WorkspacePath").FullName

    Return $Workspace
}