<#
.SYNOPSIS
Downloads and creates Amd, Intel, and Nvidia Driver Packs

.DESCRIPTION
Downloads and creates Amd, Intel, and Nvidia Driver Packs
Requires 7-Zip for EXE extraction
Requires BITS for downloading the Downloads
Requires Internet access

.LINK
https://osddrivers.osdeploy.com/module/functions/save-osddriverspack
#>
function Save-OSDDriversPack {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    Param (
        #Fully automatic Pack creation
        [Parameter(ParameterSetName = 'QuickPack', Mandatory = $true)]
        [ValidateSet(
            'AmdPack 6.1 x64',
            'AmdPack 10.0 x64',
            'IntelPack 6.1 x64',
            'IntelPack 6.1 x86',
            'IntelPack 10.0 x64',
            'IntelPack 10.0 x86',
            'NvidiaPack 6.1 x64',
            'NvidiaPack 6.1 x86',
            'NvidiaPack 10.0 x64',
            'NvidiaPack 10.0 x64 DCH',
            'NvidiaPack 10.0 x86'
        )]
        [string]$QuickPack,

        #Appends the value to the Driver Pack Name
        [Parameter(ParameterSetName = 'Default', Mandatory = $true)]
        [ValidateSet(
            'AmdPack',
            'IntelPack',
            'NvidiaPack'
        )]
        [string]$PackType,

        #Appends the value to the Driver Pack Name
        [Parameter(ParameterSetName = 'Default')]
        [string]$AppendName = 'None',

        #Driver Pack supported Operating System Architecture
        [Parameter(ParameterSetName = 'Default')]
        [ValidateSet ('x64','x86')]
        [string]$OsArch,

        #Driver Pack supported Operating System Version
        [Parameter(ParameterSetName = 'Default')]
        [ValidateSet ('6.1','6.3','10.0')]
        [string]$OsVersion,

        #Creates a CAB file from the downloaded Intel Driver
        [Parameter(ParameterSetName = 'Default')]
        [switch]$Pack,

        #Skips GridView for Automation
        [Parameter(ParameterSetName = 'Default')]
        [switch]$SkipGridView
    )

    Begin {
        #===================================================================================================
        #   Get-OSDDrivers
        #===================================================================================================
        Get-OSDDrivers -CreatePaths -HideDetails
    }

    Process {
        Write-Host '========================================================================================' -ForegroundColor Green
        Write-Host "$($MyInvocation.MyCommand.Name)" -ForegroundColor Green
        #===================================================================================================
        #   ParameterSet
        #===================================================================================================
        if ($PSCmdlet.ParameterSetName -eq 'QuickPack') {
            $CustomName = $QuickPack
            $Pack = $true
            $SkipGridView = $true

            Write-Host "QuickPack: $QuickPack" -ForegroundColor Gray

            if ($QuickPack -match 'AmdPack') {$PackType = 'AmdPack'}
            if ($QuickPack -match 'IntelPack') {$PackType = 'IntelPack'}
            if ($QuickPack -match 'NvidiaPack') {$PackType = 'NvidiaPack'}

            if ($QuickPack -match 'x64') {$OsArch = 'x64'}
            if ($QuickPack -match 'x86') {$OsArch = 'x86'}

            if ($QuickPack -match '6.1') {$OsVersion = '6.1'}
            if ($QuickPack -match '6.3') {$OsVersion = '6.3'}
            if ($QuickPack -match '10.0') {$OsVersion = '10.0'}
        } else {
            if ($AppendName -eq 'None') {
                $CustomName = $PackType
            } else {
                $CustomName = "$PackType $AppendName"
            }
        }
        Write-Host "CustomName: $CustomName" -ForegroundColor Gray
        #===================================================================================================
        #   Require 7-Zip
        #===================================================================================================
        if (($Pack -eq $true) -and ($PackType -ne 'IntelPack')) {
            if (! (Test-Path "$env:ProgramFiles\7-Zip\7z.exe")) {
                Write-Warning "OSDDrivers: Missing 7-Zip at $env:ProgramFiles\7-Zip\7z.exe"
                Write-Warning "OSDDrivers: AmdPack and Nvidia Pack downloads require 7-Zip for extraction"
                Write-Warning "OSDDrivers: Pack creation will be disabled"
                $Pack = $false
            }
        }
        #===================================================================================================
        #   Get-OSDGather -Property IsAdmin
        #===================================================================================================
        if ($Pack -eq $true) {
            if ((Get-OSDGather -Property IsAdmin) -eq $false) {
                Write-Warning 'OSDDrivers: This function needs to be run as Administrator'
                Write-Warning 'OSDDrivers: This is to generate PNP information'
                Write-Warning "OSDDrivers: Pack creation will be disabled"
                $Pack = $false
            }
        }
        #===================================================================================================
        #   Display Paths
        #===================================================================================================
        Write-Host "Home: $GetOSDDriversHome" -ForegroundColor Gray
        Write-Host "Download: $SetOSDDriversPathDownload" -ForegroundColor Gray
        Write-Host "Expand: $SetOSDDriversPathExpand" -ForegroundColor Gray
        Write-Host "Packages: $SetOSDDriversPathPackages" -ForegroundColor Gray
        #===================================================================================================
        #   Publish Paths
        #===================================================================================================
        Publish-OSDDriverScripts -PublishPath $SetOSDDriversPathPackages
        $PackagePath = Get-PathOSDD -Path (Join-Path $SetOSDDriversPathPackages "$CustomName")
        Write-Host "Package Path: $PackagePath" -ForegroundColor Gray
        Publish-OSDDriverScripts -PublishPath $PackagePath
        #===================================================================================================
        #===================================================================================================
        #   Get-OSDDriver
        #===================================================================================================
        $OSDDrivers = @()
        if ($InputObject) {
            $SkipGridView = $true
            $OSDDrivers = $InputObject
        } else {
            if ($PackType -eq 'IntelPack') {
                $OSDDrivers += Get-OSDDriver IntelDisplay
                $OSDDrivers += Get-OSDDriver IntelWireless
            } elseif ($PackType -eq 'AmdPack') {
                $OSDDrivers = Get-OSDDriver AmdDisplay
            } elseif ($PackType -eq 'NvidiaPack') {
                $OSDDrivers = Get-OSDDriver NvidiaDisplay
                if ($PSCmdlet.ParameterSetName -eq 'QuickPack') {
                    if ($QuickPack -match 'DCH') {
                        $OSDDrivers = $OSDDrivers | Where-Object {$_.DriverName -match 'DCH'}
                    }
                    if ($QuickPack -notmatch 'DCH') {
                        $OSDDrivers = $OSDDrivers | Where-Object {$_.DriverName -notmatch 'DCH'}
                    }
                }
            } else {
                Write-Warning "Unable to determine PackType"
                Break
            }
        }
        #===================================================================================================
        #   Set-OSDDriver
        #===================================================================================================
        foreach ($item in $OSDDrivers) {
            $DriverName = $item.DriverName
            $OSDCabFile = "$($DriverName).cab"
            $DownloadFile = $item.DownloadFile
            $OSDGroup = $item.OSDGroup
            $OSDType = $item.OSDType

            $DownloadedDriverGroup  = (Join-Path $global:SetOSDDriversPathDownload $OSDGroup)

            $DownloadedDriverPath = (Join-Path $SetOSDDriversPathDownload (Join-Path $OSDGroup $DownloadFile))
            if (Test-Path "$DownloadedDriverPath") {$item.OSDStatus = 'Downloaded'}

            $ExpandedDriverPath = (Join-Path $SetOSDDriversPathExpand (Join-Path $OSDGroup $DriverName))
            if (Test-Path "$ExpandedDriverPath") {$item.OSDStatus = 'Expanded'}

            $PackagedDriverPath = (Join-Path $PackagePath (Join-Path $OSDGroup $OSDCabFile))
            if (Test-Path "$PackagedDriverPath") {$item.OSDStatus = 'Packaged'}
        }
        #===================================================================================================
        #   Filters
        #===================================================================================================
        if ($OsArch) {$OSDDrivers = $OSDDrivers | Where-Object {$_.OsArch -match "$OsArch"}}
        if ($OsVersion) {$OSDDrivers = $OSDDrivers | Where-Object {$_.OsVersion -match "$OsVersion"}}
        #===================================================================================================
        #   GridView
        #===================================================================================================
        $OSDDrivers = $OSDDrivers | Sort-Object LastUpdate -Descending
        if ($SkipGridView.IsPresent) {
            Write-Warning "OSDDrivers: Skipping Out-GridView Selection"
        } else {
            $OSDDrivers = $OSDDrivers | Out-GridView -PassThru -Title "Select Drivers to Download and press OK"
        }
        #===================================================================================================
        #   Download
        #===================================================================================================
        Write-Verbose "==================================================================================================="
        foreach ($OSDDriver in $OSDDrivers) {
            $OSDType = $OSDDriver.OSDType
            Write-Verbose "OSDType: $OSDType"

            $DriverInfo = $OSDDriver.DriverInfo
            Write-Verbose "DriverInfo: $DriverInfo"

            $DriverUrl = $OSDDriver.DriverUrl
            Write-Verbose "DriverUrl: $DriverUrl"

            $DriverName = $OSDDriver.DriverName
            Write-Host "Driver Name: $DriverName" -ForegroundColor Green

            $DriverGrouping = $OSDDriver.DriverGrouping
            #Write-Host "DriverGrouping: $DriverGrouping" -ForegroundColor Gray

            $DownloadFile = $OSDDriver.DownloadFile
            #Write-Host "DownloadFile: $DownloadFile" -ForegroundColor Gray

            $OSDGroup = $OSDDriver.OSDGroup
            #Write-Host "OSDGroup: $OSDGroup" -ForegroundColor Gray

            $OSDCabFile = "$($DriverName).cab"
            #Write-Host "OSDCabFile: $OSDCabFile" -ForegroundColor Gray

            $DownloadedDriverPath = (Join-Path $SetOSDDriversPathDownload (Join-Path $OSDGroup $DownloadFile))
            #Write-Host "Driver Download Path: $DownloadedDriverPath" -ForegroundColor Gray

            $ExpandedDriverPath = (Join-Path $SetOSDDriversPathExpand (Join-Path $OSDGroup $DriverName))
            #Write-Host "Driver Expand Path: $ExpandedDriverPath" -ForegroundColor Gray

			if ($PackType -eq 'IntelPack'){
				$PackagedDriverPath = (Join-Path $PackagePath (Join-Path $OSDGroup $OSDCabFile))
			} else {
				$PackagedDriverPath = (Join-Path $PackagePath (Join-Path $DriverGrouping $OSDCabFile))
			}
            #===================================================================================================
            #   Driver Download
            #===================================================================================================
            Write-Host "Driver Download: $DownloadedDriverPath " -ForegroundColor Gray -NoNewline

            $DownloadedDriverGroup = Get-PathOSDD -Path (Join-Path $SetOSDDriversPathDownload $OSDGroup)

            if (Test-Path "$DownloadedDriverPath") {
                Write-Host 'Complete!' -ForegroundColor Cyan
            } else {
                Write-Host "Downloading ..." -ForegroundColor Cyan
                Write-Host "$DriverUrl" -ForegroundColor Gray
                if ($OSDGroup -eq 'AmdPack') {
                    #Thanks @manelrodero
                    $AmdAsk = Invoke-WebRequest -Uri "$DriverInfo" -Method Get
                    $Headers = @{ Referer = "$DriverInfo" ; Cookie = $AmdAsk.BaseResponse.Cookies }
                    Invoke-WebRequest -Uri "$DriverUrl" -Method Get -Headers $Headers -OutFile "$DownloadedDriverPath"
                } else {
                    Start-BitsTransfer -Source $DriverUrl -Destination "$DownloadedDriverPath" -ErrorAction Stop
                }
            }
            #===================================================================================================
            #   AmdPack Manual Download
            #===================================================================================================
            if (-not (Test-Path "$DownloadedDriverPath")) {
                if ($OSDGroup -eq 'AmdPack') {
                    Write-Host ""
                    Write-Warning "AMD has blocked direct Driver downloads so use this workaround"
                    Write-Host "1) Open the following URL: " -NoNewline -ForegroundColor Cyan
                    Write-Host "$DriverInfo"
                    Write-Host "2) Find the Driver link to " -NoNewline -ForegroundColor Cyan
                    Write-Host "$DownloadFile"
                    Write-Host "3) Save the download as " -NoNewline -ForegroundColor Cyan
                    Write-Host "$DownloadedDriverPath"
                    Write-Host ""
                    Pause
                }
            }
            #===================================================================================================
            #   Validate Driver Download
            #===================================================================================================
            if (-not (Test-Path "$DownloadedDriverPath")) {
                Write-Warning "Driver Download: Could not download Driver to $DownloadedDriverPath ... Exiting"
                Break
            }
            #===================================================================================================
            #   Verify 7zip
            #===================================================================================================
            if (($Pack -eq $true) -and ($PackType -ne 'IntelPack')) {
                if (-not (test-path "$env:ProgramFiles\7-Zip\7z.exe")) {
                    Write-Warning "Could not find $env:ProgramFiles\7-Zip\7z.exe"
                    Write-Warning "7-zip is required to expand this Downloaded Driver"
                    Write-Warning "You can download it from https://www.7-zip.org/"
                    Continue
                }
            }
            #===================================================================================================
            #   Driver Expand
            #===================================================================================================
            Write-Host "Driver Expand: $ExpandedDriverPath " -ForegroundColor Gray -NoNewline
            if (Test-Path "$ExpandedDriverPath") {
                Write-Host 'Complete!' -ForegroundColor Cyan
            } else {
                Write-Host 'Expanding ...' -ForegroundColor Cyan
                if ($DownloadFile -match '.zip') {
                    Expand-Archive -Path "$DownloadedDriverPath" -DestinationPath "$ExpandedDriverPath" -Force -ErrorAction Stop
                } elseif ($DownloadFile -match '.cab') {
                    if (-not (Test-Path "$ExpandedDriverPath")) {
                        New-Item "$ExpandedDriverPath" -ItemType Directory -Force -ErrorAction Stop | Out-Null
                    }
                    Expand -R "$DownloadedDriverPath" -F:* "$ExpandedDriverPath" | Out-Null
                } else {
					& "$env:ProgramFiles\7-Zip\7z.exe" x -o"$ExpandedDriverPath" "$DownloadedDriverPath" -r ;
				}
            }
            #===================================================================================================
            #   Verify Driver Expand
            #===================================================================================================
            if (-not (Test-Path "$ExpandedDriverPath")) {
                Write-Warning "Driver Expand: Could not expand Driver to $ExpandedDriverPath ... Exiting"
                Break
            }
            $OSDDriver.OSDStatus = 'Expanded'
            #===================================================================================================
            #   PACK
            #===================================================================================================
            if ($Pack -eq $true) {
                Write-Host "Driver Package: $PackagedDriverPath " -ForegroundColor Gray -NoNewline
        
                if (Test-Path "$PackagedDriverPath") {
                    Write-Host 'Complete!' -ForegroundColor Cyan
                    Continue
                } else {
                    Write-Host "Building ..." -ForegroundColor Cyan
                }
                #===================================================================================================
                #   Save-PnpOSDDriverPack or Save-PnpOSDIntelPack
                #===================================================================================================
                $OSDPnpClass = $OSDDriver.OSDPnpClass
                $OSDPnpFile = "$($DriverName).drvpnp"

				if ($PackType -eq 'IntelPack') {
					Write-Host "Save-PnpOSDIntelPack: Generating OSDDriverPNP (OSDPnpClass: $OSDPnpClass) ..." -ForegroundColor Gray
					Save-PnpOSDIntelPack -ExpandedDriverPath "$ExpandedDriverPath" $OSDPnpClass
				} else {
					Write-Host "Save-PnpOSDDriverPack: Generating OSDDriverPNP (OSDPnpClass: $OSDPnpClass) ..." -ForegroundColor Gray
					Save-PnpOSDDriverPack -ExpandedDriverPath "$ExpandedDriverPath" $OSDPnpClass
                }
                #===================================================================================================
                #   ExpandedDriverPath OSDDriver Objects
                #===================================================================================================
                $OSDDriver | Export-Clixml -Path "$ExpandedDriverPath\OSDDriver.clixml" -Force
                $OSDDriver | ConvertTo-Json | Out-File -FilePath "$ExpandedDriverPath\OSDDriver.drvpack" -Force
                #===================================================================================================
                #   Create Test Group
                #===================================================================================================
                if (($PackType -eq 'AmdPack') -or ($PackType -eq 'NvidiaPack')) {
                    Write-Host "Publishing Scripts to $PackagePath Test" -ForegroundColor Gray

                    Publish-OSDDriverScripts -PublishPath "$PackagePath Test"
                    New-Item "$PackagePath Test\$DriverGrouping" -ItemType Directory -Force | Out-Null

                    Write-Host "Publishing Test Driver Metadata to $PackagePath Test\$DriverGrouping" -ForegroundColor Gray
                    Copy-Item "$ExpandedDriverPath\OSDDriver.drvpack" "$PackagePath Test\$DriverGrouping\$DriverName.drvpack" -Force
                    Copy-Item "$ExpandedDriverPath\OSDDriver.drvpnp" "$PackagePath Test\$DriverGrouping\$DriverName.drvpnp" -Force
                    Copy-Item "$ExpandedDriverPath\OSDDriver-Devices.csv" "$PackagePath Test\$DriverGrouping\$DriverName.csv" -Force
                    Copy-Item "$ExpandedDriverPath\OSDDriver-Devices.txt" "$PackagePath Test\$DriverGrouping\$DriverName.txt" -Force
                }
                #===================================================================================================
                #   Create Package
                #===================================================================================================
                if ($PackType -eq 'IntelPack') {
                    $PackagedDriverGroup = Get-PathOSDD -Path (Join-Path $PackagePath $OSDGroup)
                } else {
                    $PackagedDriverGroup = Get-PathOSDD -Path (Join-Path $PackagePath $DriverGrouping)
                }

                Write-Host "PackagedDriverGroup: $PackagedDriverGroup" -ForegroundColor Green
                Write-Host "PackagedDriverPath: $PackagedDriverPath" -ForegroundColor Green

                if (Test-Path "$PackagedDriverPath") {
                    #Write-Warning "Compress-OSDDriver: $PackagedDriverPath already exists"
                } else {
                    New-CabFileOSDDriver -ExpandedDriverPath $ExpandedDriverPath -PublishPath $PackagedDriverGroup
                }
                if ($PackType -ne 'IntelPack') {
                    Copy-Item "$ExpandedDriverPath\OSDDriver-Devices.csv" "$PackagePath\$DriverGrouping\$DriverName.csv" -Force
                    Copy-Item "$ExpandedDriverPath\OSDDriver-Devices.txt" "$PackagePath\$DriverGrouping\$DriverName.txt" -Force
                }
                #===================================================================================================
                #   Verify Driver Package
                #===================================================================================================
                if (-not (Test-Path "$PackagedDriverPath")) {
                    Write-Warning "Driver Expand: Could not package Driver to $PackagedDriverPath ... Exiting"
                    Continue
                }
                $OSDDriver.OSDStatus = 'Package'
                #===================================================================================================
                #   Export Results
                #===================================================================================================
                $OSDDriver | Export-Clixml -Path "$ExpandedDriverPath\OSDDriver.clixml" -Force
                $OSDDriver | ConvertTo-Json | Out-File -FilePath "$ExpandedDriverPath\OSDDriver.drvpack" -Force
                $OSDDriver | ConvertTo-Json | Out-File -FilePath "$PackagedDriverGroup\$($DriverName).drvpack" -Force
                #===================================================================================================
                #   Export Files
                #===================================================================================================
                #Write-Verbose "Verify: $ExpandedDriverPath\OSDDriver.drvpnp"
                if (Test-Path "$ExpandedDriverPath\OSDDriver.drvpnp") {
                    Write-Verbose "Copy-Item: $ExpandedDriverPath\OSDDriver.drvpnp to $PackagedDriverGroup\$OSDPnpFile"
                    Copy-Item -Path "$ExpandedDriverPath\OSDDriver.drvpnp" -Destination "$PackagedDriverGroup\$OSDPnpFile" -Force | Out-Null
                }
                $OSDDriver | Export-Clixml -Path "$ExpandedDriverPath\OSDDriver.clixml" -Force
                $OSDDriver | ConvertTo-Json | Out-File -FilePath "$ExpandedDriverPath\OSDDriver.drvpack" -Force
                $OSDDriver | ConvertTo-Json | Out-File -FilePath "$PackagedDriverGroup\$($DriverName).drvpack" -Force
                #===================================================================================================
                #   Publish-OSDDriverScripts
                #===================================================================================================
                if ($PackType -ne 'IntelPack') {
                    Publish-OSDDriverScripts -PublishPath $PackagedDriverGroup
                }
            }
        }
    }

    End {
        #===================================================================================================
        #   Publish-OSDDriverScripts
        #===================================================================================================
        Write-Host "Complete!" -ForegroundColor Green
        #===================================================================================================
    }
}