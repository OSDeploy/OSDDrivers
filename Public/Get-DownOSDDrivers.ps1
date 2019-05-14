function Get-DownOSDDrivers {
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory)]
        [string]$PathDriverDownloads,

        [string]$PathDriverPackages,

        [Parameter(Mandatory)]
        [ValidateSet('Display Intel','Wireless Intel')]
        [string]$DriverGroup
    )
    #===================================================================================================
    #   Variables
    #===================================================================================================
    $Global:OSDInfoUrl = $null
    $Global:OSDPageUrl = $null
    $Global:OSDDownloadUrl = $null
    $Global:OSDDownloadFileName = $null
    $Global:DriverClass = $null
    $Global:DriverClassGUID = $null
    #===================================================================================================
    #   Create Paths
    #===================================================================================================
    if (!(Test-Path "$PathDriverDownloads")) {New-Item -Path "$PathDriverDownloads" -ItemType Directory -Force | Out-Null}
    if ($PathDriverPackages) {
        if (!(Test-Path "$PathDriverPackages")) {New-Item -Path "$PathDriverPackages" -ItemType Directory -Force | Out-Null}
    }
    #===================================================================================================
    #   DriverGroup
    #===================================================================================================
    if ($DriverGroup -eq 'Display Intel') {Get-DownDisplayIntel}
    if ($DriverGroup -eq 'Wireless Intel') {Get-DownWirelessIntel}
    if ($DriverGroup -eq 'Wireless Networking') {Get-DownWirelessNetworking}
    #===================================================================================================
    #   OSDDownloadUrl
    #===================================================================================================
    Write-Host "Validating $OSDDownloadUrl" -ForegroundColor Cyan
    Write-Host ""
    #===================================================================================================
    #   Return URLLinks
    #===================================================================================================
    $URLLinks = @()
    $URLLinks = (Invoke-WebRequest -Uri "$OSDDownloadUrl").Links

    if ($DriverGroup -eq 'Display Intel') {$URLLinks = Get-DownDisplayIntelLinks}
    if ($DriverGroup -eq 'Wireless Intel') {$URLLinks = Get-DownWirelessIntelLinks}
    if ($DriverGroup -eq 'Wireless Networking') {$URLLinks = Get-DownWirelessNetworkingLinks}

    #===================================================================================================
    #   Return Downloads
    #===================================================================================================
    $UrlDownloads = @()
    $DriverDownloads = @()
    $DriverDownloads = foreach ($URLLink in $URLLinks) {

        if ($DriverGroup -eq 'Display Intel') {
            $DriverName = $($URLLink.innerText)
            Write-Host "$DriverName"
        }
        if ($DriverGroup -eq 'Wireless Intel') {
            $WirelessIntelVersion = $($URLLink.innerText)
        }

        if ($DriverGroup -eq 'Wireless Networking') {
            $WirelessIntelVersion = $($URLLink.innerText)
        }

        $DriverPage = $($URLLink.href)
        Write-Host "$DriverPage" -ForegroundColor DarkGray
        $UrlDownloads = (Invoke-WebRequest -Uri $($URLLink.href)).Links
        $UrlDownloads = $UrlDownloads | Where-Object {($_.'data-direct-path' -like "*.exe") -or ($_.'data-direct-path' -like "*.zip")}

        if ($DriverGroup -eq 'Display Intel') {
            $UrlDownloads = $UrlDownloads | Where-Object {$_.'data-direct-path' -like "*.zip"}
        }
        if ($DriverGroup -eq 'Wireless Intel') {
            $UrlDownloads = $UrlDownloads | Where-Object {$_.'data-direct-path' -like "*.zip"}
            $UrlDownloads = $UrlDownloads | Where-Object {$_.innerText -notlike "*wifi*all*"}
            $UrlDownloads = $UrlDownloads | Where-Object {$_.innerText -notlike "*proset*"}
        }
        if ($DriverGroup -eq 'Wireless Networking') {
            $UrlDownloads = $UrlDownloads | Where-Object {$_.innerText -notlike "*WinXP*"}
            $UrlDownloads = $UrlDownloads | Where-Object {$_.innerText -notlike "*WinVista*"}
            $UrlDownloads = $UrlDownloads | Where-Object {$_.innerText -notlike "*Win8*"}
        }

        foreach ($UrlDownload in $UrlDownloads) {
            $DriverVersion = $null
            $OSVersionMin = $null
            $OSVersionMax = $null
            $OSArch = $null
            $DriverDownload = $UrlDownload.'data-direct-path'

            if ($DriverPage -eq 'https://downloadcenter.intel.com/download/22520/Graphics-Intel-Graphics-Media-Accelerator-Driver-for-Windows-7-Windows-Vista-64-Bit-zip-?product=80939') {
                $DriverVersion = '15.22.58.2993'
                $OSVersionMin = $true
                $OSArch = 'x64'
            }
            if ($DriverPage -eq 'https://downloadcenter.intel.com/download/22518/Intel-Graphics-Media-Accelerator-Driver-Windows-7-and-Windows-Vista-zip-?product=80939') {
                $DriverVersion = '15.22.58.2993'
                $OSVersionMin = $true
                $OSArch = 'x86'
            }

            if ($null -eq $OSArch) {
                if (($DriverDownload -like "*win64*") -or ($DriverDownload -like "*Driver64*")-or ($DriverDownload -like "*64_*")) {
                    $OSArch = 'x64'
                } else {
                    $OSArch = 'x86'
                }
            }

            if ($DriverGroup -eq 'Wireless Intel') {
                $DriverVersion = $WirelessIntelVersion
                if ($DriverDownload -like "*Win7*") {
                    $OSVersionMin = '6.1'
                    $OSVersionMax = '6.1'
                    $DriverName = "$DriverGroup $DriverVersion $OSArch Win7"
                }
                if ($DriverDownload -like "*Win8.1*") {
                    $OSVersionMin = '6.3'
                    $OSVersionMax = '6.3'
                    $DriverName = "$DriverGroup $DriverVersion $OSArch Win8.1"
                }
                if ($DriverDownload -like "*Win10*") {
                    $OSVersionMin = '10.0'
                    $OSVersionMax = '10.0'
                    $DriverName = "$DriverGroup $DriverVersion $OSArch Win10"
                }
                $DriverCab = "$DriverName.cab"
                $DriverZip = "$DriverName.zip"
            }

            if ($DriverGroup -eq 'Wireless Networking') {
                $DriverVersion = $WirelessIntelVersion
                if ($DriverDownload -like "*Win7*") {
                    $OSVersionMin = '6.1'
                    $OSVersionMax = '6.1'
                    $DriverName = "$DriverGroup $DriverVersion $OSArch Win7"
                }
                if ($DriverDownload -like "*Win10*") {
                    $OSVersionMin = '10.0'
                    $OSVersionMax = '10.0'
                    $DriverName = "$DriverGroup $DriverVersion $OSArch Win10"
                }
                $DriverCab = "$DriverName.cab"
                $DriverZip = "$DriverName.zip"
            }

            if ($DriverGroup -eq 'Display Intel') {
                if ($null -eq $DriverVersion) {
                    $DriverVersion = Split-Path $DriverDownload -Leaf
                }
                $DriverVersion = ($DriverVersion).replace('.zip','')
                $DriverVersion = ($DriverVersion).replace('win64_','')
                $DriverVersion = ($DriverVersion).replace('win32_','')
                $DriverVersion = ($DriverVersion).replace('dch_igcc_','')
                if ($DriverVersion -eq '15407.4279') {$DriverVersion = '15.40.7.4279'}
                if ($DriverVersion -eq '154014.4352') {$DriverVersion = '15.40.14.4352'}
                if ($DriverVersion -eq '152824') {$DriverVersion = '15.28.24.4229'}
    
                if ($DriverName -eq 'Intel Graphics MA') {
                    $OSVersionMin = '6.1'
                    $OSVersionMax = '6.1'
                } 
                if ($DriverName -eq 'Intel Graphics HD') {
                    $OSVersionMin = '6.1'
                    $OSVersionMax = '6.3'
                }
                if ($DriverName -eq 'Intel Graphics 15.33') {
                    $OSVersionMin = '6.1'
                    $OSVersionMax = '10.0'
                }
                if ($DriverName -eq 'Intel Graphics 15.36') {
                    $OSVersionMin = '6.1'
                    $OSVersionMax = '6.3'
                }
                if ($DriverName -eq 'Intel Graphics 15.40') {
                    $OSVersionMin = '6.1'
                    $OSVersionMax = '10.0'
                }
                if ($DriverName -eq 'Intel Graphics 15.45') {
                    $OSVersionMin = '6.1'
                    $OSVersionMax = '6.3'
                }
                if ($DriverName -eq 'Intel Graphics DCH') {
                    $OSVersionMin = '10.0'
                    $OSVersionMax = '10.0'
                }
                $DriverCab = "$DriverGroup $DriverVersion $OSArch.cab"
                $DriverZip = "$DriverGroup $DriverVersion $OSArch.zip"
            }



            $DriverStatus = $null
            if (Test-Path "$PathDriverDownloads\$DriverZip") {$DriverStatus = 'Downloaded'}
            if (Test-Path "$PathDriverDownloads\$DriverCab") {$DriverStatus = 'Packaged'}
            if (Test-Path "$PathDriverPackages\$DriverCab") {$DriverStatus = 'Published'}
            #===================================================================================================
            #   Create Object
            #===================================================================================================
            $ObjectProperties = @{
                DriverGroup         = $DriverGroup
                DriverClass         = $DriverClass
                DriverStatus        = $DriverStatus
                DriverName          = $DriverName
                DriverVersion       = $DriverVersion
                OSArch              = $OSArch
                OSVersionMin        = $OSVersionMin
                OSVersionMax        = $OSVersionMax
                DriverClassGUID     = $DriverClassGUID
                DriverPage          = $DriverPage
                DriverDownload      = $DriverDownload
                DriverZip           = $DriverZip
                DriverCab           = $DriverCab
            }
            New-Object -TypeName PSObject -Property $ObjectProperties
        }
    }

    $DriverDownloads | Export-Clixml "$env:Temp\OSDDrivers $DriverGroup.xml" -Force
    $DriverDownloads = $DriverDownloads | Sort-Object -Property DriverVersion -Descending | Select-Object DriverGroup,DriverClass,DriverStatus,DriverName,DriverVersion,OSArch,OSVersionMin,OSVersionMax,DriverDownload,DriverClassGUID,DriverPage,DriverZip,DriverCab

    $DriverDownloads | Export-Clixml "$PathDriverDownloads\OSDDrivers $DriverGroup.xml"
    if ($PathDriverPackages) {
        $DriverDownloads | Export-Clixml "$PathDriverPackages\OSDDrivers $DriverGroup.xml"
    }
    

    $DriverDownloads = $DriverDownloads | Out-GridView -PassThru -Title 'Select Driver Downloads to Package and press OK'

    #===================================================================================================
    #   Download
    #===================================================================================================
    foreach ($SelectedDriverDownload in $DriverDownloads) {
        $DriverStatus = $($SelectedDriverDownload.DriverStatus)
        $DriverGroup = $($SelectedDriverDownload.DriverGroup)
        $DriverClass = $($SelectedDriverDownload.DriverClass)
        $DriverClassGUID = $($SelectedDriverDownload.DriverClassGUID)
        $DriverDownload = $($SelectedDriverDownload.DriverDownload)
        $DriverOSArch = $($SelectedDriverDownload.OSArch)
        $DriverOSVersionMin = $($SelectedDriverDownload.OSVersionMin)
        $DriverOSVersionMax = $($SelectedDriverDownload.OSVersionMax)

        $DriverCab = $($SelectedDriverDownload.DriverCab)
        $DriverZip = $($SelectedDriverDownload.DriverZip)
        $DriverDirectory = ($DriverCab).replace('.cab','')

        Write-Host "DriverDownload: $DriverDownload" -ForegroundColor Cyan
        Write-Host "DriverZip: $PathDriverDownloads\$DriverZip" -ForegroundColor Gray

        if (Test-Path "$PathDriverPackages\$DriverCab") {
            Write-Warning "$PathDriverPackages\$DriverCab ... Exists!"
        } elseif (Test-Path "$PathDriverDownloads\$DriverZip") {
            Write-Warning "$PathDriverDownloads\$DriverZip ... Exists!"
        } else {
            Start-BitsTransfer -Source "$DriverDownload" -Destination "$PathDriverDownloads\$DriverZip"
        }
        if ($PathDriverPackages) {
            #===================================================================================================
            #   Expand Zip
            #   Need to add logic to unzip if necessary
            #===================================================================================================
            if (-not(Test-Path "$PathDriverPackages\$DriverCab")) {
                Write-Host "DriverDirectory: $PathDriverDownloads\$DriverDirectory" -ForegroundColor Gray

                if (Test-Path "$PathDriverDownloads\$DriverDirectory") {
                    Write-Warning "$PathDriverDownloads\$DriverDirectory ... Removing!"
                    Remove-Item -Path "$PathDriverDownloads\$DriverDirectory" -Recurse -Force | Out-Null
                }

                Write-Host "Expanding $PathDriverDownloads\$DriverZip ..." -ForegroundColor Gray
                Expand-Archive -Path "$PathDriverDownloads\$DriverZip" -DestinationPath "$PathDriverDownloads\$DriverDirectory" -Force
            }

            #===================================================================================================
            #   OSDDriverPnp
            #===================================================================================================
            if (Test-Path "$PathDriverDownloads\$DriverDirectory") {
                $OSDDriverPnp = (New-OSDDriverPnp -DriverDirectory "$PathDriverDownloads\$DriverDirectory" -DriverClass $DriverClass)
            }
            #===================================================================================================
            #   Create CAB
            #===================================================================================================
            if ( -not (Test-Path "$PathDriverDownloads\$DriverCab")) {
                Write-Verbose "Creating $PathDriverDownloads\$DriverCab ..." -Verbose
                New-OSDDriverCab -SourceDirectory "$PathDriverDownloads\$DriverDirectory" -ShowOutput
            }
            #===================================================================================================
            #   Copy CAB
            #===================================================================================================
            if ( -not (Test-Path "$PathDriverPackages\$DriverCab")) {
                Write-Verbose "Copying $PathDriverDownloads\$DriverCab to $PathDriverPackages\$DriverCab ..." -Verbose
                Copy-Item -Path "$PathDriverDownloads\$DriverCab" -Destination "$PathDriverPackages" -Force | Out-Null
            }
            #===================================================================================================
            #   OSDDriverTask
            #===================================================================================================
            Write-Host "Creating OSDDriverTask $DriverOSArch $DriverOSVersionMin $DriverOSVersionMax ..." -ForegroundColor Gray
            New-OSDDriverTask -DriverCab "$PathDriverPackages\$DriverCab" -OSArch $DriverOSArch -OSVersionMin $DriverOSVersionMin -OSVersionMax $DriverOSVersionMax
            if (Test-Path "$OSDDriverPnp") {
                Copy-Item "$OSDDriverPnp" "$PathDriverPackages" -Force
            }
            #===================================================================================================
            #   Use-OSDDrivers
            #===================================================================================================
            Copy-Item "$($MyInvocation.MyCommand.Module.ModuleBase)\Scripts\Use-OSDDrivers.ps1" "$PathDriverPackages" -Force | Out-Null
        }
    }
    Write-Host "Complete!" -ForegroundColor Green
}