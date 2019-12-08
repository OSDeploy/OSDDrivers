<#
.SYNOPSIS
Initializes the OSDDrivers Module

.DESCRIPTION
Initializes the OSDDrivers Module

.LINK
https://osddrivers.osdeploy.com/module/functions/initialize-osddrivers
#>
function Initialize-OSDDrivers {
    [CmdletBinding()]
    Param (
        #Sets the OSDDrivers Path in the Registry
        [string]$SetHome
    )
    #===================================================================================================
    #   GetOSDDriversHome
    #===================================================================================================
    if (! (Test-Path HKCU:\Software\OSDeploy)) {
        Try {New-Item HKCU:\Software -Name OSDeploy -Force | Out-Null}
        Catch {Write-Warning 'Unable to New-Item HKCU:\Software\OSDeploy'; Break}
    }

    if (Get-ItemProperty -Path 'HKCU:\Software\OSDeploy' -Name OSBuilderPath -ErrorAction SilentlyContinue) {
        Try {Rename-ItemProperty -Path 'HKCU:\Software\OSDeploy' -Name OSBuilderPath -NewName GetOSDDriversHome -Force | Out-Null}
        Catch {Write-Warning 'Unable to Rename-ItemProperty HKCU:\Software\OSDeploy OSBuilderPath to GetOSDDriversHome'; Break}
    }

    if (! (Get-ItemProperty -Path HKCU:\Software\OSDeploy -Name GetOSDDriversHome -ErrorAction SilentlyContinue)) {
        Try {New-ItemProperty -Path HKCU:\Software\OSDeploy -Name GetOSDDriversHome -Force | Out-Null}
        Catch {Write-Warning 'Unable to New-ItemProperty HKCU:\Software\OSDeploy GetOSDDriversHome'; Break}
    }

    if ($SetHome) {
        Try {Set-ItemProperty -Path HKCU:\Software\OSDeploy -Name GetOSDDriversHome -Value $SetHome -Force}
        Catch {Write-Warning "Unable to Set-ItemProperty HKCU:\Software\OSDeploy GetOSDDriversHome to $SetHome"; Break}
    }

    $global:GetOSDDriversHome = $(Get-ItemProperty "HKCU:\Software\OSDeploy").GetOSDDriversHome

    if (! $global:GetOSDDriversHome) {
        Set-ItemProperty -Path HKCU:\Software\OSDeploy -Name GetOSDDriversHome -Value "$env:SystemDrive\OSDDrivers" -Force
        $global:GetOSDDriversHome = "$env:SystemDrive\OSDDrivers"
    }
    #===================================================================================================
    #   Initialize OSDDrivers Variables
    #===================================================================================================
    Write-Verbose "Initializing OSDDrivers ..." -Verbose

    $global:GetOSDDrivers   = [ordered]@{
        Home                = $global:GetOSDDriversHome
        Initialize          = $true
        JsonLocal           = Join-Path $global:GetOSDDriversHome 'OSDDrivers.json'
        JsonGlobal          = Join-Path $env:ProgramData 'OSDeploy\OSDDrivers.json'
    }

    $global:SetOSDDrivers   = [ordered]@{
        AllowGlobalOptions  = $true
        PathDownload        = Join-Path $global:GetOSDDriversHome 'Download'
        PathExpand          = Join-Path $global:GetOSDDriversHome 'Expand'
        PathPackages        = Join-Path $global:GetOSDDriversHome 'Packages'
    }
    #===================================================================================================
    #   Import Local JSON
    #===================================================================================================
    if (Test-Path $global:GetOSDDrivers.JsonLocal) {
        Write-Verbose "Importing OSDDrivers Local Settings $($global:GetOSDDrivers.JsonLocal)"
        Try {
            $global:GetOSDDrivers.LocalSettings = (Get-Content $global:GetOSDDrivers.JsonLocal -RAW | ConvertFrom-Json).PSObject.Properties | foreach {[ordered]@{Name = $_.Name; Value = $_.Value}} | ConvertTo-Json | ConvertFrom-Json
            $global:GetOSDDrivers.LocalSettings | foreach {
                Write-Verbose "$($_.Name) = $($_.Value)"
                $global:SetOSDDrivers.$($_.Name) = $($_.Value)
            }
        }
        Catch {Write-Warning "Unable to import $($global:GetOSDDrivers.JsonLocal)"}
    }

    if ($global:SetOSDDrivers.AllowGlobalOptions -eq $true) {
        if (Test-Path $global:GetOSDDrivers.JsonGlobal) {
            Write-Verbose "Importing OSDDrivers Global Settings $($global:GetOSDDrivers.JsonGlobal)"
            Try {
                $global:GetOSDDrivers.GlobalSettings = (Get-Content $global:GetOSDDrivers.JsonGlobal -RAW | ConvertFrom-Json).PSObject.Properties | foreach {[ordered]@{Name = $_.Name; Value = $_.Value}} | ConvertTo-Json | ConvertFrom-Json
                $global:GetOSDDrivers.GlobalSettings | foreach {
                    Write-Verbose "$($_.Name) = $($_.Value)"
                    $global:SetOSDDrivers.$($_.Name) = $($_.Value)
                }
            }
            Catch {Write-Warning "Unable to import $($global:GetOSDDrivers.JsonGlobal)"}
        }
    }
    #===================================================================================================
    #   Get Variables
    #===================================================================================================
    $global:GetOSDDriversHome           = $global:GetOSDDrivers.Home
    #===================================================================================================
    #   Set Variables
    #===================================================================================================
    $global:SetOSDDriversPathDownload   = $global:SetOSDDrivers.PathDownload
    $global:SetOSDDriversPathExpand     = $global:SetOSDDrivers.PathExpand
    $global:SetOSDDriversPathPackages   = $global:SetOSDDrivers.PathPackages
}