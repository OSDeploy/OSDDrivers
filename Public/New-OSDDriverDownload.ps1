function New-OSDDriverDownload {
    [CmdletBinding()]
    PARAM (
        #[Parameter(ValueFromPipeline = $true)]
        #[Object[]]$InputObject,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Display Intel','Wireless Intel')]
        [string]$DriverGroup,

        [Parameter(Mandatory = $true)]
        [string]$DownloadPath,

        [string]$PackagePath
    )

    BEGIN {
        #===================================================================================================
        #   DownloadPath
        #===================================================================================================
        if (!(Test-Path "$DownloadPath")) {New-Item -Path "$DownloadPath" -ItemType Directory -Force | Out-Null}
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

        foreach ($OSDDriverItem in $OnlineOSDDriver) {
            if (Test-Path "$DownloadPath\$($OSDDriverItem.DriverZipFile)") {$OSDDriverItem.OSDDriverStatus = 'Downloaded'}
            if (Test-Path "$DownloadPath\$($OSDDriverItem.DriverCabFile)") {$OSDDriverItem.OSDDriverStatus = 'Packaged'}
            if ($PackagePath) {
                if (Test-Path "$PackagePath\$($OSDDriverItem.DriverCabFile)") {$OSDDriverItem.OSDDriverStatus = 'Published'}
            }
        }

        $OnlineOSDDriver | Export-Clixml "$DownloadPath\OSDDrivers $DriverGroup.xml" -Force
        if ($PackagePath) {
            $OnlineOSDDriver | Export-Clixml "$PackagePath\OSDDrivers $DriverGroup.xml" -Force
        }

        $OnlineOSDDriver = $OnlineOSDDriver | Out-GridView -PassThru -Title 'Select Drivers to Download and press OK'
        
        #===================================================================================================
        #   Process Drivers
        #===================================================================================================
        foreach ($OSDDriverItem in $OnlineOSDDriver) {
            $DriverCabFilePath = "$DownloadPath\$($OSDDriverItem.DriverCabFile)"
            $DriverZipFilePath = "$DownloadPath\$($OSDDriverItem.DriverZipFile)"
            $DriverDirectoryPath = "$DownloadPath\$($OSDDriverItem.OSDDriverName)"

            Write-Host "OSDDriverName: $($OSDDriverItem.OSDDriverName)" -ForegroundColor Gray
            #===================================================================================================
            #   Download
            #===================================================================================================
            if (Test-Path "$DriverZipFilePath") {
                #Write-Warning "$DriverZipFilePath has already been downloaded to $DriverZipFilePath"
            } else {
                Write-Host "DriverURL: $($OSDDriverItem.DriverURL)" -ForegroundColor DarkGray
                Write-Host "DriverZipFile: $DriverZipFilePath" -ForegroundColor DarkGray
                Start-BitsTransfer -Source "$($OSDDriverItem.DriverURL)" -Destination "$DriverZipFilePath"
            }
            #===================================================================================================
            #   Expand Zip
            #===================================================================================================
            if (Test-Path "$DriverZipFilePath") {
                if (Test-Path "$DriverDirectoryPath") {
                   # Write-Warning "Driver has already been expanded to $DriverDirectoryPath"
                } else {
                    Write-Host "Expanding Driver to $DriverDirectoryPath" -ForegroundColor DarkGray
                    Expand-Archive -Path "$DriverZipFilePath" -DestinationPath "$DriverDirectoryPath" -Force
                }
            }
            #===================================================================================================
            #   Set DriverDirectory
            #===================================================================================================
            $DriverDirectory = Get-Item $DriverDirectoryPath
            $DriverDirectoryParent = (Get-Item "$DriverDirectory").parent.FullName
            $DriverDirectoryName = (Get-Item "$DriverDirectory").Name
            #===================================================================================================
            #   OSDDriverCabPnp
            #===================================================================================================
            if (Test-Path "$DriverDirectoryPath") {
                if (-not (Test-Path "$DriverDirectoryPath\OSDDriver.pnp")) {
                    $OSDDriverCabPnp = (New-OSDDriverCabPnp -DriverDirectoryPath "$DriverDirectoryPath" -DriverClass $DriverClass)
                }
            }
            if ($PackagePath) {
                #===================================================================================================
                #   Create CAB
                #===================================================================================================
                if (!(Test-Path "$DriverCabFilePath")) {
                    Write-Warning "Generating $DriverCabFilePath ... This may take a while"
                    New-OSDDriverCab -SourceDirectory "$DriverDirectoryPath"
                }
                #===================================================================================================
                #   Copy CAB to Package
                #===================================================================================================
                $DriverCabFilePackagePath = "$PackagePath\$($OSDDriverItem.DriverCabFile)"
                if (!(Test-Path "$DriverCabFilePackagePath")) {
                    Write-Host "Copying $DriverCabFilePath to $DriverCabFilePackagePath ..." -ForegroundColor DarkGray
                    Copy-Item -Path "$DriverCabFilePath" -Destination "$PackagePath" -Force | Out-Null
                }
                #===================================================================================================
                #   Copy PnpXml to Package
                #===================================================================================================
                if (!(Test-Path "$PackagePath\$DriverDirectoryName.cab.pnp")) {
                    Write-Host "Copying $DriverDirectoryParent\$DriverDirectoryName.cab.pnp to $PackagePath\$DriverDirectoryName.cab.pnp ..." -ForegroundColor DarkGray
                    Copy-Item -Path "$DriverDirectoryParent\$DriverDirectoryName.cab.pnp" -Destination "$PackagePath" -Force | Out-Null
                }
                #===================================================================================================
                #   OSDDriverTask
                #===================================================================================================
                $DriverOSArch = $($OSDDriverItem.OSArch)
                $DriverOSVersionMin = $($OSDDriverItem.OSVersionMin)
                $DriverOSVersionMax = $($OSDDriverItem.OSVersionMax)

                if ($DriverGroup -eq 'Display Intel') {
                    Write-Host "Creating OSDDriverTask with parameters -OSArch $DriverOSArch -OSVersionMin $DriverOSVersionMin -OSVersionMax $DriverOSVersionMax -MakeNotLike Microsoft ..." -ForegroundColor Gray
                    New-OSDDriverCabTask -DriverCabPath "$DriverCabFilePackagePath" -OSArch $DriverOSArch -OSVersionMin $DriverOSVersionMin -OSVersionMax $DriverOSVersionMax -MakeNotLike Microsoft
                } else {
                    Write-Host "Creating OSDDriverTask with parameters -OSArch $DriverOSArch -OSVersionMin $DriverOSVersionMin -OSVersionMax $DriverOSVersionMax ..." -ForegroundColor Gray
                    New-OSDDriverCabTask -DriverCabPath "$DriverCabFilePackagePath" -OSArch $DriverOSArch -OSVersionMin $DriverOSVersionMin -OSVersionMax $DriverOSVersionMax
                }
            }
        }
    }

    END {
        #===================================================================================================
        #   Complete
        #===================================================================================================
        Write-Host "Complete!" -ForegroundColor Green
    }
}