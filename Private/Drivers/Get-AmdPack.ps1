function Get-AmdPack {
    [CmdletBinding()]
    Param ()

    $ModuleAmdPacks = @()
    $ModuleAmdPacks = Get-ChildItem "$($MyInvocation.MyCommand.Module.ModuleBase)\AmdPacks" *.drvpack -Recurse | Select-Object FullName

    $AmdPack = @()
    $AmdPack = foreach ($ModelAmdPack in $ModuleAmdPacks) {
        Get-Content $ModelAmdPack.FullName | ConvertFrom-Json
    }
    $AmdPack = $AmdPack | Sort-Object -Property LastUpdate -Descending
    Return $AmdPack
}