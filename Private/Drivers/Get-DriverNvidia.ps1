function Get-DriverNvidia {
    [CmdletBinding()]
    Param ()

    $DriverNvidia = @()
    $NvidiaDriverPacks = @()
    $NvidiaDriverPacks = Get-ChildItem "$($MyInvocation.MyCommand.Module.ModuleBase)\NvidiaPack" *.drvpack -Recurse | Select-Object FullName
    $DriverNvidia = foreach ($DrvPack in $NvidiaDriverPacks) {
        Get-Content $DrvPack.FullName | ConvertFrom-Json
    }
    $DriverNvidia = $DriverNvidia | Sort-Object -Property LastUpdate -Descending
    Return $DriverNvidia
}