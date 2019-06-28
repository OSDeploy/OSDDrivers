function Get-DownOSDDriverPackage {
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory)]
        [string]$DownloadPath,

        [string]$PackagePath,

        [Parameter(Mandatory)]
        [ValidateSet('Display Intel','Wireless Intel')]
        [string]$DriverGroup
    )
    #===================================================================================================
    #   Paths
    #===================================================================================================
    Write-Host "DownloadPath: $DownloadPath" -ForegroundColor Cyan
    Write-Host "PackagePath: $PackagePath" -ForegroundColor Cyan
    #===================================================================================================
    #   Create Paths
    #===================================================================================================
    if (!(Test-Path "$DownloadPath")) {New-Item -Path "$DownloadPath" -ItemType Directory -Force | Out-Null}
    if ($PackagePath) {
        if (!(Test-Path "$PackagePath")) {New-Item -Path "$PackagePath" -ItemType Directory -Force | Out-Null}
    }
    #===================================================================================================
    #   Get-OSDDriverLinks
    #===================================================================================================
    if ($DriverGroup -eq 'Display Intel') {$DriverDownloads = Get-DriverDisplayIntel -DownloadPath $DownloadPath -PackagePath $PackagePath}
    #if ($DriverGroup -eq 'Wireless Intel') {$DriverDownloads = Get-DriverWirelessIntel -DownloadPath $DownloadPath -PackagePath $PackagePath}
    #===================================================================================================
    #   Export Module
    #===================================================================================================
    if ($PackagePath) {
        Get-Content "$($MyInvocation.MyCommand.Module.ModuleBase)\Public\Expand-OSDDrivers.ps1" | Set-Content "$PackagePath\Use-OSDDrivers.ps1"
        Get-Content "$($MyInvocation.MyCommand.Module.ModuleBase)\Public\Get-OSDDrivers.ps1" | Add-Content "$PackagePath\Use-OSDDrivers.ps1"
        Get-Content "$($MyInvocation.MyCommand.Module.ModuleBase)\Public\New-OSDDriversInventory.ps1" | Add-Content "$PackagePath\Use-OSDDrivers.ps1"
        Get-Content "$($MyInvocation.MyCommand.Module.ModuleBase)\Scripts\Use-OSDDrivers.ps1" | Add-Content "$PackagePath\Use-OSDDrivers.ps1"
        #Copy-Item "$($MyInvocation.MyCommand.Module.ModuleBase)\Scripts\Use-OSDDrivers.ps1" "$PackagePath" -Force | Out-Null

    }
    #===================================================================================================
    #   Complete
    #===================================================================================================
    Write-Host "Complete!" -ForegroundColor Green
}