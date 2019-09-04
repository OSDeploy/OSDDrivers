function Get-OSDDrivers {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [string]$WorkspacePath,

        [Parameter(Mandatory)]
        [ValidateSet ('GetAmdPack','TestAmdPack')]
        $Action
    )

    $OSDWorkspace = Get-PathOSDD -Path $WorkspacePath
    Write-Verbose "Workspace Path: $OSDWorkspace" -Verbose

    $WorkspaceDownload = Get-PathOSDD -Path (Join-Path $OSDWorkspace 'Download')
    Write-Verbose "Workspace Download: $WorkspaceDownload" -Verbose

    $WorkspaceExpand = Get-PathOSDD -Path (Join-Path $OSDWorkspace 'Expand')
    Write-Verbose "Workspace Expand: $WorkspaceExpand" -Verbose
    $WorkspacePackages = Get-PathOSDD -Path (Join-Path $OSDWorkspace 'Packages')
    Write-Verbose "Workspace Packages: $WorkspacePackages" -Verbose

    if ($Action -eq 'GetAmdPack') {
        $AmdInfs = @()
        if (Test-Path "$WorkspaceExpand\HpModel") {
            Write-Verbose "Searching for AMD Video Drivers in $WorkspaceExpand\HpModel" -Verbose
            $AmdInfs = Get-ChildItem "$WorkspaceExpand\HpModel" *.inf -Recurse | Where-Object {$_.FullName -match '\\graphics\\amd\\' -and $_.FullName -notmatch '\\audio\\'} | Select-Object FullName
        }
        $AmdList = @()
        foreach ($AmdInf in $AmdInfs) {
            $AmdList += Get-WindowsDriver -Online -Driver "$($AmdInf.FullName)" | Select-Object -Property * #HardwareId, HardwareDescription, Version, Driver, ClassName
        }
        foreach ($Pnp in $AmdList) {
            $Pnp.HardwareId = ($Pnp.HardwareId -split '\&REV')[0]
        }
        $AmdList = $AmdList | Where-Object {$_.ClassName -eq 'Display'} | Sort-Object HardwareId -Unique #| Select-Object HardwareId, HardwareDescription

        Write-Verbose "AMD Video List saved as $OSDWorkspace\AmdPack.csv" -Verbose
        $AmdList | ConvertTo-Csv -NoTypeInformation | Set-Content -Path "$OSDWorkspace\AmdPack.csv"

        Write-Verbose "AMD Video Object saved as $OSDWorkspace\AmdPack.clixml" -Verbose
        $AmdList | Export-Clixml "$OSDWorkspace\AmdPack.clixml"
    }

    if ($Action -eq 'TestAmdPack') {
        $AmdList = @()
        if (Test-Path "$OSDWorkspace\AmdPack.clixml") {
            $AmdList = Import-Clixml "$OSDWorkspace\AmdPack.clixml" | Where-Object {$_.HardwareId -match 'PCI\\VEN_1002'}
            Write-Host ""
            Write-Host "$($AmdList.Count) Amd Video Devices from Hp Model Packs" -ForegroundColor Green
            Write-Host ""
            $AllDrivers = @()
            $DriverPnps = Get-ChildItem "$WorkspacePackages\AmdPack 10.0 x64" *.drvpnp -Recurse | Select-Object BaseName, FullName | Sort-Object BaseName -Descending | Out-Gridview -PassThru -Title 'Select Amd Drivers to Evaluate'
        
            foreach ($DriverPnp in $DriverPnps) {
                $Title = $DriverPnp.BaseName
                Write-Host "Evaluating: $Title" -Foregroundcolor Green
            
                $MatchingDriver = @()
                $NotMatchingDriver = @()
                $Drivers = @()
                $Drivers = Import-Clixml $DriverPnp.FullName
            
                foreach ($Hardware in $AmdList) {
                    $DriverMatch = $false
                    foreach ($Driver in $Drivers) {
                        if ($Hardware.HardwareId -like "*$($Driver.HardwareId)*") {
                            $DriverMatch = $true
                            Continue
                        }
                    }
                    if ($DriverMatch -eq $true) {$MatchingDriver += $Hardware}
                    if ($DriverMatch -eq $false) {$NotMatchingDriver += $Hardware}
                }
                
                Write-Host "$($MatchingDriver.Count) Devices are supported by this Driver" -ForegroundColor Cyan
            
                $AmdList = $NotMatchingDriver
                Write-Host "$($NotMatchingDriver.Count) Remaining Devices" -ForegroundColor Cyan
                Write-Host ""
            }
        
            $AmdList = $AmdList | Sort HardwareId -Unique | Select HardwareId, HardwareDescription, Driver
            $UniqueResults = ($AmdList).count
            Write-Host "$UniqueResults AMD Video Devices without a Driver" -ForegroundColor Green
            
            $AmdList | Export-Clixml "$OSDWorkspace\AmdPack-Results.clixml"
            $AmdList | Out-GridView -Title "Remaining HardwareID's that need Drivers"
        }
    }
}