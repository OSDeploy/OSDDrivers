<#
.SYNOPSIS
Downloads and creates Amd and Nvidia Video Drivers

.DESCRIPTION
Downloads and creates Amd and Nvidia Video Drivers
Requires 7-Zip for EXE extraction
Requires BITS for downloading the Downloads
Requires Internet access

.LINK
https://osddrivers.osdeploy.com/module/functions/save-osddriverpack

.PARAMETER WorkspacePath
Directory to the OSDDrivers Workspace.  This contains the Download, Expand, and Package subdirectories

.PARAMETER DriverPack
Select AmdPack or NvidiaPack

.PARAMETER AppendName
Appends the string to the Driver Pack Name

.PARAMETER Pack
Creates a CAB file from the downloaded drivers

.PARAMETER SkipGridView
Skips GridView for Automation

.PARAMETER OsArch
Supported Operating System Architecture of the Driver

.PARAMETER OsVersion
Supported Operating Systems Version of the Driver.  This includes both Client and Server Operating Systems
#>
function Save-OSDDriverPack {
    [CmdletBinding()]
    Param (
        #====================================================================
        #   Mandatory
        #====================================================================
        [Parameter(Mandatory)]
        [string]$WorkspacePath,

        [Parameter(Mandatory)]
        [ValidateSet ('AmdPack','NvidiaPack')]
        [string]$DriverPack,
        #====================================================================
        #   Options
        #====================================================================
        [string]$AppendName = 'None',
        [switch]$Pack,
        [switch]$SkipGridView,
        #====================================================================
        #   Filter
        #====================================================================
        [ValidateSet ('x64','x86')]
        [string]$OsArch = 'x64',

        [ValidateSet ('10.0','6.1')]
        [string]$OsVersion = '10.0'
        #====================================================================
    )

    Begin {
        #===================================================================================================
        #   Validate Admin Rights
        #===================================================================================================
        if ($Pack.IsPresent) {
            $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            If (!( $IsAdmin )) {
                Write-Warning "Pack: Elevation is required to generate Driver PNP files"
                Break
            }
        }
        #===================================================================================================
        #   Defaults
        #===================================================================================================
        $OSDWorkspace = Get-PathOSDD -Path $WorkspacePath
        Write-Verbose "Workspace Path: $OSDWorkspace" -Verbose

        $WorkspaceDownload = Get-PathOSDD -Path (Join-Path $OSDWorkspace 'Download')
        Write-Verbose "Workspace Download: $WorkspaceDownload" -Verbose

        $WorkspaceExpand = Get-PathOSDD -Path (Join-Path $OSDWorkspace 'Expand')
        Write-Verbose "Workspace Expand: $WorkspaceExpand" -Verbose

        $WorkspacePackages = Get-PathOSDD -Path (Join-Path $OSDWorkspace 'Packages')
        Write-Verbose "Workspace Packages: $WorkspacePackages" -Verbose
        Publish-OSDDriverScripts -PublishPath $WorkspacePackages
        #===================================================================================================
    }

    Process {
        #===================================================================================================
        #   Defaults
        #===================================================================================================
        $OSDDrivers = @()
        Write-Warning "Save-OSDDriverPack requires 7-Zip at $env:ProgramFiles\7-Zip\7z.exe"

        if ($DriverPack -eq 'AmdPack') {
            $OSDGroup = 'AmdPack'
            $OsArch = 'x64'
            $OsVersion = '10.0'
            $OSDDrivers = Get-AmdPack
            Write-Warning "AmdPack is compatible with 10.0 x64 only"
        }
        if ($DriverPack -eq 'Intel') {
            $OSDGroup = 'IntelPack'
            $OSDDrivers = Get-IntelPack
        }
        if ($DriverPack -eq 'NvidiaPack') {
            $OSDGroup = 'NvidiaPack'
            $OSDDrivers = Get-NvidiaPack
        }
        #===================================================================================================
        #   PackageName
        #===================================================================================================
        if ($AppendName -eq 'None') {
            $PackageName = "$OSDGroup $OsVersion $OsArch"
        } else {
            $PackageName = "$OSDGroup $OsVersion $OsArch $AppendName"
        }

        $PackagePath = Get-PathOSDD -Path (Join-Path $WorkspacePackages "$PackageName")
        Write-Verbose "Package Path: $PackagePath" -Verbose
        Publish-OSDDriverScripts -PublishPath $PackagePath
        #===================================================================================================
        #   Set-OSDStatus
        #===================================================================================================
        foreach ($OSDDriver in $OSDDrivers) {
            $DriverName = $OSDDriver.DriverName
            $OSDCabFile = "$($DriverName).cab"
            $DownloadFile = $OSDDriver.DownloadFile
            $OSDGroup = $OSDDriver.OSDGroup
            $OSDType = $OSDDriver.OSDType

            $DriverGrouping = $OSDDriver.DriverGrouping
            #Write-Verbose "DriverGrouping: $DriverGrouping"

            $DownloadedDriverGroup  = (Join-Path $WorkspaceDownload $OSDGroup)
            Write-Verbose "DownloadedDriverGroup: $DownloadedDriverGroup"

            $DownloadedDriverPath = (Join-Path $WorkspaceDownload (Join-Path $OSDGroup $DownloadFile))
            if (Test-Path "$DownloadedDriverPath") {$OSDDriver.OSDStatus = 'Downloaded'}

            $ExpandedDriverPath = (Join-Path $WorkspaceExpand (Join-Path $OSDGroup $DriverName))
            if (Test-Path "$ExpandedDriverPath") {$OSDDriver.OSDStatus = 'Expanded'}

            $PackagedDriverPath = (Join-Path $PackagePath (Join-Path $DriverGrouping $OSDCabFile))
            #$PackagedDriverPath = (Join-Path $PackagePath (Join-Path $OSDGroup $OSDCabFile))
            if (Test-Path "$PackagedDriverPath") {$OSDDriver.OSDStatus = 'Packaged'}
        }
        #===================================================================================================
        #   OsArch
        #===================================================================================================
        if ($OsArch) {$OSDDrivers = $OSDDrivers | Where-Object {$_.OsArch -match "$OsArch"}}
        #===================================================================================================
        #   OsVersion
        #===================================================================================================
        if ($OsVersion) {$OSDDrivers = $OSDDrivers | Where-Object {$_.OsVersion -match "$OsVersion"}}
        #===================================================================================================
        #   GridView
        #===================================================================================================
        $OSDDrivers = $OSDDrivers | Sort-Object LastUpdate -Descending
        if ($SkipGridView.IsPresent) {
            Write-Warning "SkipGridView: Skipping Out-GridView"
        } else {
            $OSDDrivers = $OSDDrivers | Out-GridView -PassThru -Title "Select Drivers to Download and press OK"
        }
        #===================================================================================================
        #   Download
        #===================================================================================================
        if ($WorkspacePath) {
            Write-Verbose "==================================================================================================="
            foreach ($OSDDriver in $OSDDrivers) {
                $OSDType = $OSDDriver.OSDType
                Write-Verbose "OSDType: $OSDType"

                $DriverInfo = $OSDDriver.DriverInfo
                Write-Verbose "DriverInfo: $DriverInfo"

                $DriverUrl = $OSDDriver.DriverUrl
                Write-Verbose "DriverUrl: $DriverUrl"

                $DriverName = $OSDDriver.DriverName
                Write-Verbose "DriverName: $DriverName"

                $DriverGrouping = $OSDDriver.DriverGrouping
                Write-Verbose "DriverGrouping: $DriverGrouping"

                $DownloadFile = $OSDDriver.DownloadFile
                Write-Verbose "DownloadFile: $DownloadFile"

                $OSDGroup = $OSDDriver.OSDGroup
                Write-Verbose "OSDGroup: $OSDGroup"

                $OSDCabFile = "$($DriverName).cab"
                Write-Verbose "OSDCabFile: $OSDCabFile"

                $DownloadedDriverPath = (Join-Path $WorkspaceDownload (Join-Path $OSDGroup $DownloadFile))
                Write-Verbose "DownloadedDriverPath: $DownloadedDriverPath"

                $ExpandedDriverPath = (Join-Path $WorkspaceExpand (Join-Path $OSDGroup $DriverName))
                Write-Verbose "ExpandedDriverPath: $ExpandedDriverPath"

                $PackagedDriverPath = (Join-Path $PackagePath (Join-Path $DriverGrouping $OSDCabFile))
                Write-Verbose "PackagedDriverPath: $PackagedDriverPath"

                Write-Host "$DriverName" -ForegroundColor Green
                #===================================================================================================
                #   Driver Download
                #===================================================================================================
                Write-Host "Driver Download: $DownloadedDriverPath " -ForegroundColor Gray -NoNewline

                $DownloadedDriverGroup = Get-PathOSDD -Path (Join-Path $WorkspaceDownload $OSDGroup)

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
                if (-not (test-path "$env:ProgramFiles\7-Zip\7z.exe")) {
                    Write-Warning "Could not find $env:ProgramFiles\7-Zip\7z.exe"
                    Write-Warning "7-zip is required to expand this Downloaded Driver"
                    Write-Warning "You can download it from https://www.7-zip.org/"
                    Continue
                } 
                #===================================================================================================
                #   Driver Expand
                #===================================================================================================
                Write-Host "Driver Expand: $ExpandedDriverPath " -ForegroundColor Gray -NoNewline
                if (Test-Path "$ExpandedDriverPath") {
                    Write-Host 'Complete!' -ForegroundColor Cyan
                } else {
                    Write-Host 'Expanding ...' -ForegroundColor Cyan
                    & "$env:ProgramFiles\7-Zip\7z.exe" x -o"$ExpandedDriverPath" "$DownloadedDriverPath" -r ;
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
                if ($Pack.IsPresent) {
                    #===================================================================================================
                    #   Save-OSDDriverPnp
                    #===================================================================================================
                    $OSDPnpClass = $OSDDriver.OSDPnpClass
                    $OSDPnpFile = "$($DriverName).drvpnp"
    
                    Write-Host "Save-OSDDriverPnp: Generating OSDDriverPNP (OSDPnpClass: $OSDPnpClass) ..." -ForegroundColor Gray
                    Save-OSDDriverPnp -ExpandedDriverPath "$ExpandedDriverPath" $OSDPnpClass
                    #===================================================================================================
                    #   ExpandedDriverPath OSDDriver Objects
                    #===================================================================================================
                    $OSDDriver | Export-Clixml -Path "$ExpandedDriverPath\OSDDriver.clixml" -Force
                    $OSDDriver | ConvertTo-Json | Out-File -FilePath "$ExpandedDriverPath\OSDDriver.drvpack" -Force
    
                    Publish-OSDDriverScripts -PublishPath "$PackagePath Test"
                    New-Item "$PackagePath Test\$DriverGrouping" -ItemType Directory -Force | Out-Null
                    Copy-Item "$ExpandedDriverPath\OSDDriver.drvpack" "$PackagePath Test\$DriverGrouping\$DriverName.drvpack" -Force
                    Copy-Item "$ExpandedDriverPath\OSDDriver.drvpnp" "$PackagePath Test\$DriverGrouping\$DriverName.drvpnp" -Force
                    Copy-Item "$ExpandedDriverPath\OSDDriver-Devices.csv" "$PackagePath Test\$DriverGrouping\$DriverName.csv" -Force
                    Copy-Item "$ExpandedDriverPath\OSDDriver-Devices.txt" "$PackagePath Test\$DriverGrouping\$DriverName.txt" -Force
                    #===================================================================================================
                    #   Create Package
                    #===================================================================================================
                    $PackagedDriverGroup = Get-PathOSDD -Path (Join-Path $PackagePath $DriverGrouping)
                    Write-Verbose "PackagedDriverGroup: $PackagedDriverGroup" -Verbose
                    Write-Verbose "PackagedDriverPath: $PackagedDriverPath" -Verbose
                    if (Test-Path "$PackagedDriverPath") {
                        #Write-Warning "Compress-OSDDriver: $PackagedDriverPath already exists"
                    } else {
                        New-CabFileOSDDriver -ExpandedDriverPath $ExpandedDriverPath -PublishPath $PackagedDriverGroup
                    }
                    #===================================================================================================
                    #   Verify Driver Package
                    #===================================================================================================
                    if (-not (Test-Path "$PackagedDriverPath")) {
                        Write-Warning "Driver Package: Could not package Driver to $PackagedDriverPath ... Exiting"
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
                    Publish-OSDDriverScripts -PublishPath $PackagedDriverGroup
                }
            }
        } else {
            Return $OSDDrivers
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