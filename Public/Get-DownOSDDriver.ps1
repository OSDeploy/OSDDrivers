function Get-DownOSDDriver {
    [CmdletBinding()]
    PARAM (
        #[Parameter(ValueFromPipeline = $true)]
        #[Object[]]$InputObject,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Display Intel','Wireless Intel')]
        [string]$DriverGroup,

        [Parameter(Mandatory = $true)]
        [string]$DownloadPath,

        [string]$PublishPath
    )

    BEGIN {
        #===================================================================================================
        #   DownloadPath
        #===================================================================================================
        if (!(Test-Path "$DownloadPath")) {New-Item -Path "$DownloadPath" -ItemType Directory -Force | Out-Null}
        #===================================================================================================
        #   PublishPath
        #===================================================================================================
        if ($PublishPath) {
            if (!(Test-Path "$PublishPath")) {New-Item -Path "$PublishPath" -ItemType Directory -Force | Out-Null}
        }
        #===================================================================================================
    }

    PROCESS {
        #===================================================================================================
        #   Get-OnlineOSDDriver
        #===================================================================================================
        $OnlineOSDDriver = @()
        if ($InputObject) {
            $OnlineOSDDriver = $InputObject
        } else {
            if ($DriverGroup -eq 'Display Intel') {$OnlineOSDDriver = Get-OnlineOSDDriverDisplayIntel}
            if ($DriverGroup -eq 'Wireless Intel') {$OnlineOSDDriver = Get-OnlineOSDDriverWirelessIntel}
        }
        $OnlineOSDDriver = $OnlineOSDDriver | Sort-Object -Property LastUpdated -Descending | Select-Object OSDDriverStatus,DriverGroup,DriverClass,LastUpdated,DriverName,DriverVersion,OSArch,OSVersionMin,OSVersionMax,Description,DriverDownload,DriverClassGUID,DriverPage,DriverZipFileName,DriverCab

        foreach ($OSDDriverItem in $OnlineOSDDriver) {
            if (Test-Path "$DownloadPath\$($OSDDriverItem.DriverZipFileName)") {$OSDDriverItem.OSDDriverStatus = 'Downloaded'}
            if (Test-Path "$DownloadPath\$($OSDDriverItem.DriverCab)") {$OSDDriverItem.OSDDriverStatus = 'Packaged'}
            if ($PublishPath) {
                if (Test-Path "$PublishPath\$($OSDDriverItem.DriverCab)") {$OSDDriverItem.OSDDriverStatus = 'Published'}
            }
        }

<#         $OnlineOSDDriver | Export-Clixml "$DownloadPath\OSDDrivers $DriverGroup.xml"
        if ($PublishPath) {
            $OnlineOSDDriver | Export-Clixml "$PublishPath\OSDDrivers $DriverGroup.xml"
        } #>

        $OnlineOSDDriver = $OnlineOSDDriver | Out-GridView -PassThru -Title 'Select Driver Downloads to Package and press OK'
        #Return $OnlineOSDDriver
        
<#         #===================================================================================================
        #   Download
        #===================================================================================================
        foreach ($OSDDriverItem in $OnlineOSDDriver) {
            $OSDDriverStatus = $($OSDDriverItem.OSDDriverStatus)
            $DriverGroup = $($OSDDriverItem.DriverGroup)
            $DriverClass = $($OSDDriverItem.DriverClass)
            $DriverClassGUID = $($OSDDriverItem.DriverClassGUID)
            $DriverDownload = $($OSDDriverItem.DriverDownload)
            $DriverOSArch = $($OSDDriverItem.OSArch)
            $DriverOSVersionMin = $($OSDDriverItem.OSVersionMin)
            $DriverOSVersionMax = $($OSDDriverItem.OSVersionMax)

            $DriverCab = $($OSDDriverItem.DriverCab)
            $DriverZipFileName = $($OSDDriverItem.DriverZipFileName)
            $DriverDirectory = ($DriverCab).replace('.cab','')

            Write-Host "DriverDownload: $DriverDownload" -ForegroundColor Cyan
            Write-Host "DriverZipFileName: $DownloadPath\$DriverZipFileName" -ForegroundColor Gray

            if (Test-Path "$PublishPath\$DriverCab") {
                Write-Warning "$PublishPath\$DriverCab ... Exists!"
            } elseif (Test-Path "$DownloadPath\$DriverZipFileName") {
                Write-Warning "$DownloadPath\$DriverZipFileName ... Exists!"
            } else {
                Start-BitsTransfer -Source "$DriverDownload" -Destination "$DownloadPath\$DriverZipFileName"
            }
            if ($PublishPath) {
                #===================================================================================================
                #   Expand Zip
                #   Need to add logic to unzip if necessary
                #===================================================================================================
                if (-not(Test-Path "$PublishPath\$DriverCab")) {
                    Write-Host "DriverDirectory: $DownloadPath\$DriverDirectory" -ForegroundColor Gray

                    if (Test-Path "$DownloadPath\$DriverDirectory") {
                        Write-Warning "$DownloadPath\$DriverDirectory ... Removing!"
                        Remove-Item -Path "$DownloadPath\$DriverDirectory" -Recurse -Force | Out-Null
                    }

                    Write-Host "Expanding $DownloadPath\$DriverZipFileName ..." -ForegroundColor Gray
                    Expand-Archive -Path "$DownloadPath\$DriverZipFileName" -DestinationPath "$DownloadPath\$DriverDirectory" -Force
                }

                #===================================================================================================
                #   OSDDriverPnp
                #===================================================================================================
                if (Test-Path "$DownloadPath\$DriverDirectory") {
                    $OSDDriverPnp = (New-OSDDriverPnp -DriverDirectory "$DownloadPath\$DriverDirectory" -DriverClass $DriverClass)
                }
                #===================================================================================================
                #   Create CAB
                #===================================================================================================
                if ( -not (Test-Path "$DownloadPath\$DriverCab")) {
                    Write-Verbose "Creating $DownloadPath\$DriverCab ..." -Verbose
                    New-OSDDriverCAB -SourceDirectory "$DownloadPath\$DriverDirectory" -ShowOutput
                }
                #===================================================================================================
                #   Copy CAB
                #===================================================================================================
                if ( -not (Test-Path "$PublishPath\$DriverCab")) {
                    Write-Verbose "Copying $DownloadPath\$DriverCab to $PublishPath\$DriverCab ..." -Verbose
                    Copy-Item -Path "$DownloadPath\$DriverCab" -Destination "$PublishPath" -Force | Out-Null
                }
                #===================================================================================================
                #   OSDDriverTask
                #===================================================================================================
                Write-Host "Creating OSDDriverTask $DriverOSArch $DriverOSVersionMin $DriverOSVersionMax ..." -ForegroundColor Gray
                New-OSDDriverTask -DriverCab "$PublishPath\$DriverCab" -OSArch $DriverOSArch -OSVersionMin $DriverOSVersionMin -OSVersionMax $DriverOSVersionMax
                if (Test-Path "$OSDDriverPnp") {
                    Copy-Item "$OSDDriverPnp" "$PublishPath" -Force
                }
            }
        } #>
    }

    END {
        #===================================================================================================
        #   Export Module
        #===================================================================================================
        if ($PublishPath) {
            Get-Content "$($MyInvocation.MyCommand.Module.ModuleBase)\Public\Expand-OSDDrivers.ps1" | Set-Content "$PublishPath\OSDDrivers.psm1"
            Get-Content "$($MyInvocation.MyCommand.Module.ModuleBase)\Public\Get-OSDDrivers.ps1" | Add-Content "$PublishPath\OSDDrivers.psm1"
            Get-Content "$($MyInvocation.MyCommand.Module.ModuleBase)\Public\New-OSDDriversInventory.ps1" | Add-Content "$PublishPath\OSDDrivers.psm1"
            Get-Content "$($MyInvocation.MyCommand.Module.ModuleBase)\Scripts\Use-OSDDrivers.ps1" | Add-Content "$PublishPath\OSDDrivers.psm1"
            Copy-Item "$($MyInvocation.MyCommand.Module.ModuleBase)\Scripts\Use-OSDDrivers.ps1" "$PublishPath" -Force | Out-Null
        }
        #===================================================================================================
        #   Complete
        #===================================================================================================
        Write-Host "Complete!" -ForegroundColor Green
    }
}