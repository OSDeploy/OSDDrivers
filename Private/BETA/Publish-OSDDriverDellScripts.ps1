function Publish-OSDDriverDellScripts {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [string]$PublishPath
    )

$DellGenerationScript = @'
#===================================================================================================
#   Defaults
#===================================================================================================
$DellGeneration = 'X0'
#===================================================================================================
#   Connect to Task Sequence Environment
#===================================================================================================
try {
    $TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
}
catch [System.Exception] {
    Write-Warning -Message "Unable to construct Microsoft.SMS.TSEnvironment object"
}
#===================================================================================================
#   DellModelPack.clixml
#===================================================================================================
try {
    $DellModelPack = Import-Clixml "$PSScriptRoot\DellModelPack.clixml"
}
catch {
    Write-Warning -Message "Cannot import $PSScriptRoot\DellModelPack.clixml"
    if ($TSEnv) {$TSEnv.Value('DellGeneration') = $DellGeneration}
    Return $DellGeneration
}
#===================================================================================================
#   SystemMake
#===================================================================================================
$SystemMake = $null
try {
    $SystemMake = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
}
catch {
    Write-Warning -Message "Cannot determine System Make"
}
if ($SystemMake -notmatch 'Dell') {
    Write-Warning -Message "This function is only for Dell Systems"
    if ($TSEnv) {$TSEnv.Value('DellGeneration') = $DellGeneration}
    Return $DellGeneration
}
#===================================================================================================
#   SystemSKUNumber
#===================================================================================================
$SystemSKUNumber = $null
try {
    $SystemSKUNumber = (Get-CimInstance -ClassName Win32_ComputerSystem).SystemSKUNumber
}
catch {
    Write-Warning -Message "Cannot determine System SKUNumber"
}
if ($SystemSKUNumber) {
    $DellGeneration = ($DellModelPack | Where-Object {$_.SystemSku -contains $SystemSKUNumber}).Generation
    if ($TSEnv) {$TSEnv.Value('DellGeneration') = $DellGeneration}
    Return $DellGeneration
}
#===================================================================================================
#   SystemModel
#===================================================================================================
$SystemModel = $null
try {
    $SystemModel = (Get-CimInstance -ClassName Win32_ComputerSystem).Model
}
catch {
    Write-Warning -Message "Cannot determine System Model"
    Return 'X0'
}
if ($SystemModel) {
    $DellGeneration = ($DellModelPack | Where-Object {$_.Model -contains $SystemModel}).Generation
    if ($TSEnv) {$TSEnv.Value('DellGeneration') = $DellGeneration}
    Return $DellGeneration
}
#===================================================================================================
if ($TSEnv) {$TSEnv.Value('DellGeneration') = $DellGeneration}
Return $DellGeneration
'@


    if (!(Test-Path "$PublishPath")) {New-Item -Path "$PublishPath" -ItemType Directory -Force | Out-Null}

    #Write-Verbose "Generating $PublishPath\Deploy-OSDDrivers.psm1" -Verbose
    Get-Content "$($MyInvocation.MyCommand.Module.ModuleBase)\Private\Deploy\DellModelPack.clixml" | Set-Content "$PublishPath\DellModelPack.clixml"

    $DellGenerationScript | Out-File "$PublishPath\Deploy-GetDellGeneration.ps1"
}