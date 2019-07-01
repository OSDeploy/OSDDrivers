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
            if ($DriverGroup -eq 'Display Intel') {$OnlineOSDDriver = Get-DriverGroupDisplayIntel}
            if ($DriverGroup -eq 'Wireless Intel') {$OnlineOSDDriver = Get-DriverGroupWirelessIntel}
        }
        $OnlineOSDDriver = $OnlineOSDDriver | Sort-Object -Property LastUpdated -Descending | Select-Object OSDDriverStatus,DriverGroup,DriverClass,LastUpdated,DriverName,DriverVersion,OSArch,OSVersionMin,OSVersionMax,DriverClassGUID,Description,DriverURL,DriverPage,DriverZipFile,DriverCabFile

        foreach ($OSDDriverItem in $OnlineOSDDriver) {
            if (Test-Path "$DownloadPath\$($OSDDriverItem.DriverZipFile)") {$OSDDriverItem.OSDDriverStatus = 'Downloaded'}
            if (Test-Path "$DownloadPath\$($OSDDriverItem.DriverCabFile)") {$OSDDriverItem.OSDDriverStatus = 'Packaged'}
            if ($PublishPath) {
                if (Test-Path "$PublishPath\$($OSDDriverItem.DriverCabFile)") {$OSDDriverItem.OSDDriverStatus = 'Published'}
            }
        }

        $OnlineOSDDriver | Export-Clixml "$DownloadPath\OSDDrivers $DriverGroup.xml"
        if ($PublishPath) {
            $OnlineOSDDriver | Export-Clixml "$PublishPath\OSDDrivers $DriverGroup.xml"
        }

        $OnlineOSDDriver = $OnlineOSDDriver | Out-GridView -PassThru -Title 'Select Driver Downloads to Package and press OK'
        
        #===================================================================================================
        #   Process Drivers
        #===================================================================================================
        foreach ($OSDDriverItem in $OnlineOSDDriver) {
            $OSDDriverStatus = $($OSDDriverItem.OSDDriverStatus)
            $DriverGroup = $($OSDDriverItem.DriverGroup)
            $DriverClass = $($OSDDriverItem.DriverClass)
            $DriverClassGUID = $($OSDDriverItem.DriverClassGUID)
            $DriverURL = $($OSDDriverItem.DriverURL)
            $DriverOSArch = $($OSDDriverItem.OSArch)
            $DriverOSVersionMin = $($OSDDriverItem.OSVersionMin)
            $DriverOSVersionMax = $($OSDDriverItem.OSVersionMax)

            $DriverCabFile = $($OSDDriverItem.DriverCabFile)
            $DriverZipFile = $($OSDDriverItem.DriverZipFile)
            $DriverDirectory = ($DriverCabFile).replace('.cab','')

            Write-Host "DriverURL: $DriverURL" -ForegroundColor Gray

            #===================================================================================================
            #   Download
            #===================================================================================================
            if (Test-Path "$DownloadPath\$DriverZipFile") {
                Write-Warning "$DownloadPath\$DriverZipFile ... Skip Download"
            } else {
                Write-Host "DriverZipFile: $DownloadPath\$DriverZipFile" -ForegroundColor Gray
                Start-BitsTransfer -Source "$DriverURL" -Destination "$DownloadPath\$DriverZipFile"
            }
            #===================================================================================================
            #   Publish
            #===================================================================================================
            if ($PublishPath) {
                #===================================================================================================
                #   Expand Zip
                #===================================================================================================
                if (-not(Test-Path "$PublishPath\$DriverCabFile")) {
                    Write-Host "DriverDirectory: $DownloadPath\$DriverDirectory" -ForegroundColor Gray

                    if (Test-Path "$DownloadPath\$DriverDirectory") {
                        Write-Warning "$DownloadPath\$DriverDirectory ... Remove Existing"
                        Remove-Item -Path "$DownloadPath\$DriverDirectory" -Recurse -Force | Out-Null
                    }

                    Write-Host "Expand $DownloadPath\$DriverZipFile ..." -ForegroundColor Gray
                    Expand-Archive -Path "$DownloadPath\$DriverZipFile" -DestinationPath "$DownloadPath\$DriverDirectory" -Force
                }
                #===================================================================================================
                #   OSDDriverPnp
                #===================================================================================================
                if (Test-Path "$DownloadPath\$DriverDirectory") {
                    $OSDDriverPnp = (New-OSDDriverCabPnp -DriverDirectory "$DownloadPath\$DriverDirectory" -DriverClass $DriverClass)
                }
                #===================================================================================================
                #   Create CAB
                #===================================================================================================
                if (Test-Path "$DownloadPath\$DriverCabFile") {
                    Write-Warning "$DownloadPath\$DriverCabFile ... Remove Existing"

                } else {
                    Write-Verbose "Creating $DownloadPath\$DriverCabFile ..." -Verbose
                    New-OSDDriverCab -SourceDirectory "$DownloadPath\$DriverDirectory" -ShowOutput
                }
                #===================================================================================================
                #   Copy CAB
                #===================================================================================================
                if ( -not (Test-Path "$PublishPath\$DriverCabFile")) {
                    Write-Verbose "Copying $DownloadPath\$DriverCabFile to $PublishPath\$DriverCabFile ..." -Verbose
                    Copy-Item -Path "$DownloadPath\$DriverCabFile" -Destination "$PublishPath" -Force | Out-Null
                }
                #===================================================================================================
                #   OSDDriverTask
                #===================================================================================================
                Write-Host "Creating OSDDriverTask $DriverOSArch $DriverOSVersionMin $DriverOSVersionMax ..." -ForegroundColor Gray
                Write-Host "DriverCabFile: $PublishPath\$DriverCabFile"
                New-OSDDriverCabTask -DriverCabPath "$PublishPath\$DriverCabFile" -OSArch $DriverOSArch -OSVersionMin $DriverOSVersionMin -OSVersionMax $DriverOSVersionMax
                if (Test-Path "$OSDDriverPnp") {
                    Copy-Item "$OSDDriverPnp" "$PublishPath" -Force
                }
            }
        }
    }

    END {
        #===================================================================================================
        #   Export Module
        #===================================================================================================
        if ($PublishPath) {
            #Get-Content "$($MyInvocation.MyCommand.Module.ModuleBase)\Public\Expand-OSDDrivers.ps1" | Set-Content "$PublishPath\OSDDrivers.psm1"
            #Get-Content "$($MyInvocation.MyCommand.Module.ModuleBase)\Public\Get-OSDDrivers.ps1" | Add-Content "$PublishPath\OSDDrivers.psm1"
            #Get-Content "$($MyInvocation.MyCommand.Module.ModuleBase)\Public\New-OSDDriversInventory.ps1" | Add-Content "$PublishPath\OSDDrivers.psm1"
            #Get-Content "$($MyInvocation.MyCommand.Module.ModuleBase)\Scripts\Use-OSDDrivers.ps1" | Add-Content "$PublishPath\OSDDrivers.psm1"
            #Copy-Item "$($MyInvocation.MyCommand.Module.ModuleBase)\Scripts\Use-OSDDrivers.ps1" "$PublishPath" -Force | Out-Null
        }
        #===================================================================================================
        #   Complete
        #===================================================================================================
        Write-Host "Complete!" -ForegroundColor Green
    }
}