<#
.SYNOPSIS
Downloads IntelDisplay and IntelWireless Drivers

.DESCRIPTION
Downloads IntelDisplay and IntelWireless Drivers
Requires BITS for downloading the Downloads
Requires Internet access

.LINK
https://osddrivers.osdeploy.com/module/functions/save-osdintelpack

.PARAMETER WorkspacePath
Directory to the OSDDrivers Workspace.  This contains the Download, Expand, and Package subdirectories

.PARAMETER AppendName
Appends the string to the Driver Pack Name

.PARAMETER OSDGroup
Driver Group.  This will be expanded in the future to contain more groups

.PARAMETER OsArch
Supported Operating System Architecture of the Driver

.PARAMETER OsVersion
Supported Operating Systems Version of the Driver.  This includes both Client and Server Operating Systems

.PARAMETER Pack
Creates a CAB file from the downloaded Intel Driver

.PARAMETER SkipGridView
Skips GridView for Automation
#>
function Save-OSDIntelPack {
    [CmdletBinding()]
    Param (
        #====================================================================
        #   InputObject
        #====================================================================
        #[Parameter(ValueFromPipeline = $true)]
        #[Object[]]$InputObject,
        #====================================================================
        #   Basic
        #====================================================================
        [Parameter(Mandatory)]
        [string]$WorkspacePath,

        [Parameter(Mandatory)]
        [string]$AppendName = 'None',
        #====================================================================
        #   Filters
        #====================================================================
        [ValidateSet('IntelDisplay','IntelWireless')]
        [string]$OSDGroup,

        [ValidateSet ('x64','x86')]
        [string]$OsArch,

        [ValidateSet ('10.0','6.3','6.1')]
        [string]$OsVersion,
        #====================================================================
        #   Options
        #====================================================================
        [switch]$Pack,
        [switch]$SkipGridView
        #====================================================================
    )

    Begin {
        #===================================================================================================
        #   CustomName
        #===================================================================================================
        if ($AppendName -eq 'None') {
            $CustomName = "IntelPack"
        } else {
            $CustomName = "IntelPack $AppendName"
        }
        #===================================================================================================
        #   Get-OSDWorkspace Home
        #===================================================================================================
        $OSDWorkspace = Get-PathOSDD -Path $WorkspacePath
        Write-Verbose "Workspace Path: $OSDWorkspace" -Verbose
        #===================================================================================================
        #   Get-OSDWorkspace Children
        #===================================================================================================
        $WorkspaceDownload = Get-PathOSDD -Path (Join-Path $OSDWorkspace 'Download')
        Write-Verbose "Workspace Download: $WorkspaceDownload" -Verbose

        $WorkspaceExpand = Get-PathOSDD -Path (Join-Path $OSDWorkspace 'Expand')
        Write-Verbose "Workspace Expand: $WorkspaceExpand" -Verbose

        $WorkspacePackages = Get-PathOSDD -Path (Join-Path $OSDWorkspace 'Packages')
        Write-Verbose "Workspace Packages: $WorkspacePackages" -Verbose
        Publish-OSDDriverScripts -PublishPath $WorkspacePackages

        $PackagePath = Get-PathOSDD -Path (Join-Path $WorkspacePackages "$CustomName")
        Write-Verbose "Package Path: $PackagePath" -Verbose
        Publish-OSDDriverScripts -PublishPath $PackagePath
        #===================================================================================================
    }

    Process {
        #===================================================================================================
        #   Get-OSDDrivers
        #===================================================================================================
        $OSDDrivers = @()
        if ($InputObject) {
            $SkipGridView = $true
            $OSDDrivers = $InputObject
        } else {
            if ($OSDGroup -eq 'IntelDisplay') {$OSDDrivers = Get-DriverIntelDisplay}
            elseif ($OSDGroup -eq 'IntelWireless') {$OSDDrivers = Get-DriverIntelWireless}
            else {
                $OSDDrivers += Get-DriverIntelDisplay
                $OSDDrivers += Get-DriverIntelWireless
            }
        }
        #===================================================================================================
        #   Set-OSDStatus
        #===================================================================================================
        foreach ($OSDDriver in $OSDDrivers) {
            $DriverName = $OSDDriver.DriverName
            $OSDCabFile = "$($DriverName).cab"
            $DownloadFile = $OSDDriver.DownloadFile
            $OSDGroup = $OSDDriver.OSDGroup
            $OSDType = $OSDDriver.OSDType

            $DownloadedDriverGroup  = (Join-Path $WorkspaceDownload $OSDGroup)
            Write-Verbose "DownloadedDriverGroup: $DownloadedDriverGroup"

            $DownloadedDriverPath = (Join-Path $WorkspaceDownload (Join-Path $OSDGroup $DownloadFile))
            if (Test-Path "$DownloadedDriverPath") {$OSDDriver.OSDStatus = 'Downloaded'}

            $ExpandedDriverPath = (Join-Path $WorkspaceExpand (Join-Path $OSDGroup $DriverName))
            if (Test-Path "$ExpandedDriverPath") {$OSDDriver.OSDStatus = 'Expanded'}

            $PackagedDriverPath = (Join-Path $PackagePath (Join-Path $OSDGroup $OSDCabFile))
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

                $DriverUrl = $OSDDriver.DriverUrl
                Write-Verbose "DriverUrl: $DriverUrl"

                $DriverName = $OSDDriver.DriverName
                Write-Verbose "DriverName: $DriverName"

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

                $PackagedDriverPath = (Join-Path $PackagePath (Join-Path $OSDGroup $OSDCabFile))
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
                    Start-BitsTransfer -Source $DriverUrl -Destination "$DownloadedDriverPath" -ErrorAction Stop
                }
                #===================================================================================================
                #   Validate Driver Download
                #===================================================================================================
                if (-not (Test-Path "$DownloadedDriverPath")) {
                    Write-Warning "Driver Download: Could not download Driver to $DownloadedDriverPath ... Exiting"
                    Break
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
                    }
                    if ($DownloadFile -match '.cab') {
                        if (-not (Test-Path "$ExpandedDriverPath")) {
                            New-Item "$ExpandedDriverPath" -ItemType Directory -Force -ErrorAction Stop | Out-Null
                        }
                        Expand -R "$DownloadedDriverPath" -F:* "$ExpandedDriverPath" | Out-Null
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

                if ($Pack.IsPresent) {
                    #===================================================================================================
                    #   Create Package
                    #===================================================================================================
                    $PackagedDriverGroup = Get-PathOSDD -Path (Join-Path $PackagePath $OSDGroup)
                    Write-Verbose "Verify: $PackagedDriverPath"
                    if (Test-Path "$PackagedDriverPath") {
                        #Write-Warning "Compress-OSDDriver: $PackagedDriverPath already exists"
                    } else {
                        New-CabFileOSDDriver -ExpandedDriverPath $ExpandedDriverPath -PublishPath $PackagedDriverGroup
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
                    #Publish-OSDDriverScripts -PublishPath $PackagedDriverGroup
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