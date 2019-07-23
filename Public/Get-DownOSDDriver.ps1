<#
.SYNOPSIS
Downloads Drivers

.DESCRIPTION
Downloads Drivers
Requires BITS for downloading the Downloads
Requires Internet access

.LINK
https://osddrivers.osdeploy.com/functions/get-osddriverpacks

.PARAMETER WorkspacePath
Directory to the OSDDrivers Workspace.  This contains the Download, Expand, and Package subdirectories

.PARAMETER OSDGroup
Driver Group.  This will be expanded in the future to contain more groups

.PARAMETER OSArch
Supported Architecture of the Driver

.PARAMETER OSVersion
Supported Operating Systems Version of the Driver.  This includes both Client and Server Operating Systems
#>
function Get-DownOSDDriver {
    [CmdletBinding()]
    Param (
        #[Parameter(ValueFromPipeline = $true)]
        #[Object[]]$InputObject,
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$WorkspacePath,

        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateSet('IntelDisplay','IntelWireless')]
        [string]$OSDGroup,

        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateSet ('x64','x86')]
        [string]$OSArch,

        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateSet ('10.0','6.3','6.1')]
        [string]$OSVersion
    )

    Begin {
        #===================================================================================================
        #   Get-OSDWorkspace
        #===================================================================================================
        $OSDWorkspace = Get-PathOSDD -Path $WorkspacePath
        Write-Verbose "Workspace Path: $OSDWorkspace" -Verbose
        #===================================================================================================
        #   Get-OSDWorkspace
        #===================================================================================================
        $WorkspaceDownload = Get-PathOSDD -Path "$OSDWorkspace\Download"
        Write-Verbose "Workspace Download: $WorkspaceDownload" -Verbose

        $WorkspaceExpand = Get-PathOSDD -Path "$OSDWorkspace\Expand"
        Write-Verbose "Workspace Expand: $WorkspaceExpand" -Verbose

        $WorkspacePackage = Get-PathOSDD -Path "$OSDWorkspace\Package"
        Write-Verbose "Workspace Package: $WorkspacePackage" -Verbose
    }

    Process {
        #===================================================================================================
        #   Get-OSDDrivers
        #===================================================================================================
        $OSDDrivers = @()
        if ($InputObject) {
            $GridView = $false
            $OSDDrivers = $InputObject
        } else {
            $GridView = $true
            #if ($OSDGroup -eq 'DellFamily') {$OSDDrivers = Get-DriverDellFamily}
            if ($OSDGroup -eq 'IntelDisplay') {
                $OSDDrivers = Get-DriverIntelDisplay
            } elseif ($OSDGroup -eq 'IntelWireless') {
                $OSDDrivers = Get-DriverIntelWireless
            } else {
                $OSDDrivers += Get-DriverIntelWireless
                $OSDDrivers += Get-DriverIntelDisplay
            }
        }
        #===================================================================================================
        #   Set-OSDStatus
        #===================================================================================================
        foreach ($OSDDriver in $OSDDrivers) {
            Write-Verbose "==================================================================================================="
            $DriverName = $OSDDriver.DriverName
            $OSDDriver.OSDPackageFile = "$($DriverName).cab"
            $DownloadFile = $OSDDriver.DownloadFile
            $OSDGroup = $OSDDriver.OSDGroup
            $OSDType = $OSDDriver.OSDType
            $DownloadedDriverPath = (Join-Path $WorkspaceDownload (Join-Path $OSDGroup $DownloadFile))
            $ExpandedDriverPath = (Join-Path $WorkspaceExpand (Join-Path $OSDGroup $DriverName))
            $PackagedDriverPath = (Join-Path $WorkspacePackage (Join-Path $OSDGroup $OSDDriver.OSDPackageFile))

            if (Test-Path "$DownloadedDriverPath") {$OSDDriver.OSDStatus = 'Downloaded'}
            if (Test-Path "$ExpandedDriverPath") {$OSDDriver.OSDStatus = 'Expanded'}
            if (Test-Path "$PackagedDriverPath") {$OSDDriver.OSDStatus = 'Packaged'}

            $OSDPackageFile = $OSDDriver.OSDPackageFile
            Write-Verbose "OSDPackageFile: $OSDPackageFile"

            if (Test-Path "$ExpandedDriverPath\OSDDriver.drvpnp") {$OSDDriver.OSDPnpFile = "$($DriverName).drvpnp"}
        }
        #===================================================================================================
        #   OSArch
        #===================================================================================================
        if ($OSArch) {$OSDDrivers = $OSDDrivers | Where-Object {$_.OSArchMatch -match "$OSArch"}}
        #===================================================================================================
        #   OSVersion
        #===================================================================================================
        if ($OSVersion) {$OSDDrivers = $OSDDrivers | Where-Object {$_.OSVersionMatch -match "$OSVersion"}}
        #===================================================================================================
        #   GridView
        #===================================================================================================
        $OSDDrivers = $OSDDrivers | Sort-Object LastUpdate -Descending
        if ($GridView) {$OSDDrivers = $OSDDrivers | Out-GridView -PassThru -Title "Select Drivers to Download and press OK"}
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

                $FileType = $OSDDriver.FileType
                Write-Verbose "FileType: $FileType"

                $DownloadFile = $OSDDriver.DownloadFile
                Write-Verbose "DownloadFile: $DownloadFile"

                $OSDGroup = $OSDDriver.OSDGroup
                Write-Verbose "OSDGroup: $OSDGroup"

                $OSDPackageFile = $OSDDriver.OSDPackageFile
                Write-Verbose "OSDPackageFile: $OSDPackageFile"

                $DownloadedDriverPath = (Join-Path $WorkspaceDownload (Join-Path $OSDGroup $DownloadFile))
                Write-Verbose "DownloadedDriverPath: $DownloadedDriverPath"

                $ExpandedDriverPath = (Join-Path $WorkspaceExpand (Join-Path $OSDGroup $DriverName))
                Write-Verbose "ExpandedDriverPath: $ExpandedDriverPath"

                $PackagedDriverPath = (Join-Path $WorkspacePackage (Join-Path $OSDGroup $OSDDriver.OSDPackageFile))
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
                    if ($FileType -match 'zip') {
                        Expand-Archive -Path "$DownloadedDriverPath" -DestinationPath "$ExpandedDriverPath" -Force -ErrorAction Stop
                    }
                    if ($FileType -match 'cab') {
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

                if (Test-Path "$ExpandedDriverPath\OSDDriver.drvpnp") {$OSDDriver.OSDPnpFile = "$OSDPnpFile"}
                #===================================================================================================
                #   ExpandedDriverPath OSDDriver Objects
                #===================================================================================================
                $OSDDriver | Export-Clixml -Path "$ExpandedDriverPath\OSDDriver.clixml" -Force
                $OSDDriver | ConvertTo-Json | Out-File -FilePath "$ExpandedDriverPath\OSDDriver.drvtask" -Force
                #===================================================================================================
                #   Create Package
                #===================================================================================================
                $PackagedDriverGroup = Get-PathOSDD -Path (Join-Path $WorkspacePackage $OSDGroup)
                Write-Verbose "Verify: $PackagedDriverPath"
                if (Test-Path "$PackagedDriverPath") {
                    Write-Warning "Compress-OSDDriver: $PackagedDriverPath already exists"
                } else {
                    if ($OSDPackageFile -match '.zip') {
                        Write-Warning "Compress-OSDDriver: Generating $PackagedDriverPath ... This will take a while"
                        Compress-Archive -Path "$ExpandedDriverPath" -DestinationPath "$PackagedDriverPath" -ErrorAction Stop
                    }
                    elseif ($OSDPackageFile -match '.cab') {
                        Write-Warning "New-OSDDriverCabFile: Generating $PackagedDriverPath ... This will take a while"
                        New-OSDDriverCabFile -ExpandedDriverPath $ExpandedDriverPath -PackagePath $PackagedDriverGroup
                    }
                    else {
                        Write-Warning 'Unable to determine the OSDDriver File Type'
                        Break
                    }
                }
                $OSDDriver | Export-Clixml -Path "$ExpandedDriverPath\OSDDriver.clixml" -Force
                $OSDDriver | ConvertTo-Json | Out-File -FilePath "$ExpandedDriverPath\OSDDriver.drvtask" -Force
                $OSDDriver | ConvertTo-Json | Out-File -FilePath "$PackagedDriverGroup\$($DriverName).drvtask" -Force
                #===================================================================================================
                #   Export Files
                #===================================================================================================
                Write-Verbose "Verify: $ExpandedDriverPath\OSDDriver.drvpnp"
                if (Test-Path "$ExpandedDriverPath\OSDDriver.drvpnp") {
                    Write-Verbose "Copy-Item: $ExpandedDriverPath\OSDDriver.drvpnp to $PackagedDriverGroup\$OSDPnpFile"
                    Copy-Item -Path "$ExpandedDriverPath\OSDDriver.drvpnp" -Destination "$PackagedDriverGroup\$OSDPnpFile" -Force | Out-Null
                }
                $OSDDriver | Export-Clixml -Path "$ExpandedDriverPath\OSDDriver.clixml" -Force
                $OSDDriver | ConvertTo-Json | Out-File -FilePath "$ExpandedDriverPath\OSDDriver.drvtask" -Force
                $OSDDriver | ConvertTo-Json | Out-File -FilePath "$PackagedDriverGroup\$($DriverName).drvtask" -Force
                #===================================================================================================
                #   Publish-OSDDriverScripts
                #===================================================================================================
                Publish-OSDDriverScripts -PublishPath $PackagedDriverGroup
            }
        } else {
            Return $OSDDrivers
        }
    }

    End {
        #===================================================================================================
        #   Publish-OSDDriverScripts
        #===================================================================================================
        Publish-OSDDriverScripts -PublishPath $WorkspacePackage
        Write-Host "Complete!" -ForegroundColor Green
    }
}