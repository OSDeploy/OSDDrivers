function Get-DriverAmd {
    [CmdletBinding()]
    Param ()

    $DriverAmd = @()
    $AmdDriverPacks = @()
    $AmdDriverPacks = Get-ChildItem "$($MyInvocation.MyCommand.Module.ModuleBase)\AmdPack" *.drvpack -Recurse | Select-Object FullName
    $DriverAmd = foreach ($DrvPack in $AmdDriverPacks) {
        Get-Content $DrvPack.FullName | ConvertFrom-Json
    }
    $DriverAmd = $DriverAmd | Sort-Object -Property LastUpdate -Descending
    Return $DriverAmd
}