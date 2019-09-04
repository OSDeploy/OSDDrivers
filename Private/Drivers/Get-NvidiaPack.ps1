function Get-NvidiaPack {
    [CmdletBinding()]
    Param ()

    $ModuleNvidiaPacks = @()
    $ModuleNvidiaPacks = Get-ChildItem "$($MyInvocation.MyCommand.Module.ModuleBase)\NvidiaPacks" *.drvpack -Recurse | Select-Object FullName

    $NvidiaPack = @()
    $NvidiaPack = foreach ($ModelNvidiaPack in $ModuleNvidiaPacks) {
        Get-Content $ModelNvidiaPack.FullName | ConvertFrom-Json
    }
    $NvidiaPack = $NvidiaPack | Sort-Object -Property LastUpdate -Descending
    Return $NvidiaPack
}