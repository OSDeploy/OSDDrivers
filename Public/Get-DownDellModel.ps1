<#
.SYNOPSIS
Downloads DellFamily Driver Packs

.DESCRIPTION
Downloads DellFamily Driver Packs
Requires BITS for downloading the Downloads
Requires Internet access

.LINK
https://osddrivers.osdeploy.com/module/functions/get-downdellmodel

.PARAMETER WorkspacePath
Directory to the OSDDrivers Workspace.  This contains the Download, Expand, and Package subdirectories

.PARAMETER DriverFamily
Filters compatibility to Latitude, Optiplex, or Precision.  Venue, Vostro, and XPS are not included

.PARAMETER Pack
Creates a CAB file from the DellFamily DriverPack.  Default removes Audio and Video.  Core removes Default and additional Drivers
#>
function Get-DownDellModel {
    [CmdletBinding(DefaultParameterSetName='Download')]
    Param (
        [Parameter(Mandatory)]
        [string]$WorkspacePath,

        [ValidateSet ('X10','X9','X8','X7','X6','X5','X4','X3','X2','X1')]
        [string]$Generation,

        [ValidateSet ('10.0','6.3','6.1')]
        [string]$OsVersion,

        [ValidateSet ('Latitude','Optiplex','Precision')]
        [string]$SystemFamily,
        #===================================================================================================
        #   Download
        #===================================================================================================
        [Parameter(ParameterSetName = 'Download')]
        [switch]$Expand,
        #===================================================================================================
        #   Pack
        #===================================================================================================
        [Parameter(ParameterSetName = 'Pack', Mandatory = $true)]
        [switch]$Pack,
        #===================================================================================================
        #   MultiPack
        #===================================================================================================
        [Parameter(ParameterSetName = 'MultiPack', Mandatory = $true)]
        [string]$MultiPackName,
        #===================================================================================================
        #   Pack and MultiPack
        #===================================================================================================
        [Parameter(ParameterSetName = 'Pack')]
        [Parameter(ParameterSetName = 'MultiPack')]
        [switch]$RemoveAudio = $false,
        
        [Parameter(ParameterSetName = 'Pack')]
        [Parameter(ParameterSetName = 'MultiPack')]
        [switch]$RemoveVideoAMD = $false,

        [Parameter(ParameterSetName = 'Pack')]
        [Parameter(ParameterSetName = 'MultiPack')]
        [switch]$RemoveVideoNvidia = $false
        #===================================================================================================
        #   Scraps
        #===================================================================================================
        #[Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        #[ValidateSet('DellModel','DellFamily')]
        #[string]$OSDGroup,

        #[Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        #[ValidateSet ('x64','x86')]
        #[string]$OsArch,

        #[switch]$SkipGridView
    )

    Begin {
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
        #Publish-OSDDriverScripts -PublishPath $WorkspaceDownload

        $WorkspaceExpand = Get-PathOSDD -Path (Join-Path $OSDWorkspace 'Expand')
        Write-Verbose "Workspace Expand: $WorkspaceExpand" -Verbose

        $WorkspacePackage = Get-PathOSDD -Path (Join-Path $OSDWorkspace 'Package')
        Write-Verbose "Workspace Package: $WorkspacePackage" -Verbose
        #Publish-OSDDriverScripts -PublishPath $WorkspacePackage
        #===================================================================================================
    }

    Process {
        #===================================================================================================
        #   Defaults
        #===================================================================================================
        if ($MyInvocation.MyCommand.Name -eq 'Get-DownDellFamily') {
            $OSDGroup = 'DellFamily'
            $OsVersion = '10.0'
            $OsArch = 'x64'
            $RemoveAudio = $true
            $RemoveVideoAMD = $true
            $RemoveVideoNvidia = $true
        }
        if ($MyInvocation.MyCommand.Name -eq 'Get-DownDellModel') {
            $OSDGroup = 'DellModel'
            #$OsVersion = '10.0'
            #$OsArch = 'x64'
            #$RemoveAudio = $true
            #$RemoveVideoAMD = $true
            #$RemoveVideoNvidia = $true
            Publish-OSDDriverScripts -PublishPath (Join-Path $WorkspaceDownload 'DellModel')
        }
        if ($PSCmdlet.ParameterSetName -eq 'MultiPack') {
            $Expand = $true
            $OSDGroup = 'DellModel'
            #$OsVersion = '10.0'
            #$OsArch = 'x64'
            #$RemoveAudio = $true
            #$RemoveVideoAMD = $true
            #$RemoveVideoNvidia = $true
            if ($RemoveAudio -eq $true) {Write-Warning "Audio Drivers will be removed from resulting packages"}
            Write-Warning "Intel Video Drivers will be removed from resulting packages by default"
            if ($RemoveVideoAMD -eq $true) {Write-Warning "AMD Video Drivers will be removed from resulting packages"}
            if ($RemoveVideoNvidia -eq $true) {Write-Warning "Nvidia Video Drivers will be removed from resulting packages"}
        }

        if ($PSCmdlet.ParameterSetName -eq 'Pack') {
            $Expand = $true
            if ($RemoveAudio -eq $true) {Write-Warning "Audio Drivers will be removed from resulting packages"}
            Write-Warning "Intel Video Drivers will be removed from resulting packages by default"
            if ($RemoveVideoAMD -eq $true) {Write-Warning "AMD Video Drivers will be removed from resulting packages"}
            if ($RemoveVideoNvidia -eq $true) {Write-Warning "Nvidia Video Drivers will be removed from resulting packages"}
        }
        #===================================================================================================
        #   Get-OSDDrivers
        #===================================================================================================
        $OSDDrivers = @()
        if ($InputObject) {
            $SkipGridView = $true
            $OSDDrivers = $InputObject
        } else {
            if ($MyInvocation.MyCommand.Name -eq 'Get-DownDellFamily') {$OSDDrivers = Get-DriverDellFamily}
            if ($MyInvocation.MyCommand.Name -eq 'Get-DownDellModel') {$OSDDrivers = Get-DriverDellModel}
        }
        #===================================================================================================
        #   Set-OSDStatus
        #===================================================================================================
        foreach ($OSDDriver in $OSDDrivers) {
            Write-Verbose "==================================================================================================="
            $DownloadFile       = $OSDDriver.DownloadFile
            $DriverName         = $OSDDriver.DriverName
            $OSDCabFile         = "$($DriverName).cab"
            $OSDGroup           = $OSDDriver.OSDGroup
            $OSDType            = $OSDDriver.OSDType

            $DownloadedDriverGroup  = (Join-Path $WorkspaceDownload $OSDGroup)
            $DownloadedDriverPath   = (Join-Path $DownloadedDriverGroup $DownloadFile)
            $ExpandedDriverPath     = (Join-Path $WorkspaceExpand (Join-Path $OSDGroup $DriverName))
            $PackagedDriverPath     = (Join-Path $WorkspacePackage (Join-Path $OSDGroup $OSDCabFile))
            Write-Verbose "DownloadedDriverGroup: $DownloadedDriverGroup"
            Write-Verbose "DownloadedDriverPath: $DownloadedDriverPath"
            Write-Verbose "ExpandedDriverPath: $ExpandedDriverPath"
            Write-Verbose "PackagedDriverPath: $PackagedDriverPath"

            if (Test-Path "$DownloadedDriverPath") {$OSDDriver.OSDStatus = 'Downloaded'}
            if (Test-Path "$ExpandedDriverPath") {$OSDDriver.OSDStatus = 'Expanded'}

            if ($PSCmdlet.ParameterSetName -ne 'MultiPack') {
                if (Test-Path "$PackagedDriverPath") {$OSDDriver.OSDStatus = 'Packaged'}
                Write-Verbose "OSDCabFile: $OSDCabFile"
                if (Test-Path "$ExpandedDriverPath\OSDDriver.drvpnp") {$OSDPnpFile = "$($DriverName).drvpnp"}
            }
        }
        #===================================================================================================
        #   OSArch
        #===================================================================================================
        if ($OsArch) {$OSDDrivers = $OSDDrivers | Where-Object {$_.OsArch -match "$OsArch"}}
        #===================================================================================================
        #   OSVersion
        #===================================================================================================
        if ($OsVersion) {$OSDDrivers = $OSDDrivers | Where-Object {$_.OsVersion -match "$OsVersion"}}
        #===================================================================================================
        #   Generation
        #===================================================================================================
        if ($Generation) {$OSDDrivers = $OSDDrivers | Where-Object {$_.Generation -eq "$Generation"}}
        #===================================================================================================
        #   DriverFamily
        #===================================================================================================
        if ($SystemFamily) {$OSDDrivers = $OSDDrivers | Where-Object {$_.SystemFamily -match "$SystemFamily"}}
        #===================================================================================================
        #   Filter
        #===================================================================================================
        #if ($MyInvocation.MyCommand.Name -eq 'New-DellMultiPack') {$OSDDrivers = $OSDDrivers | Where-Object {$_.OSDStatus -ne ''}}
        #$OSDDrivers = $OSDDrivers | Where-Object {$_.DriverFamily -ne 'Venue'}
        #$OSDDrivers = $OSDDrivers | Where-Object {$_.DriverFamily -ne 'Vostro'}
        #$OSDDrivers = $OSDDrivers | Where-Object {$_.DriverFamily -ne 'XPS'}
        #===================================================================================================
        #   GridView
        #===================================================================================================
        $OSDDrivers = $OSDDrivers | Sort-Object LastUpdate -Descending
        if ($SkipGridView.IsPresent) {
            Write-Warning "SkipGridView: Skipping Out-GridView"
        } else {
            if ($PSCmdlet.ParameterSetName -eq 'MultiPack') {$OSDDrivers = $OSDDrivers | Out-GridView -PassThru -Title "Select Drivers to MultiPack and press OK"}
            else {$OSDDrivers = $OSDDrivers | Out-GridView -PassThru -Title "Select Drivers to Download and press OK"}
        }
        #===================================================================================================
        #   Execute
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

                $DownloadedDriverGroup = (Join-Path $WorkspaceDownload $OSDGroup)
                $DownloadedDriverPath =  (Join-Path $DownloadedDriverGroup $DownloadFile)
                $ExpandedDriverPath = (Join-Path $WorkspaceExpand (Join-Path $OSDGroup $DriverName))
                $PackagedDriverPath = (Join-Path $WorkspacePackage (Join-Path $OSDGroup $OSDCabFile))

                if (-not(Test-Path "$DownloadedDriverGroup")) {New-Item $DownloadedDriverGroup -Directory -Force | Out-Null}

                Write-Verbose "DownloadedDriverPath: $DownloadedDriverPath"
                Write-Verbose "ExpandedDriverPath: $ExpandedDriverPath"
                Write-Verbose "PackagedDriverPath: $PackagedDriverPath"

                Write-Host "$DriverName" -ForegroundColor Green
                #===================================================================================================
                #   Driver Download
                #===================================================================================================
                Write-Host "Driver Download: $DownloadedDriverPath " -ForegroundColor Gray -NoNewline


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
                    Continue
                } else {
                    if ($DownloadFile -match '.cab') {
                        $OSDDriver | ConvertTo-Json | Out-File -FilePath "$DownloadedDriverGroup\$((Get-Item $DownloadedDriverPath).BaseName).drvpack" -Force
                    }
                }
                #===================================================================================================
                #   Driver Expand
                #===================================================================================================
                if ($Expand.IsPresent) {
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
                } else {
                    Continue
                }
                #===================================================================================================
                #   Verify Driver Expand
                #===================================================================================================
                if (-not (Test-Path "$ExpandedDriverPath")) {
                    Write-Warning "Driver Expand: Could not expand Driver to $ExpandedDriverPath ... Exiting"
                    Continue
                }
                $OSDDriver.OSDStatus = 'Expanded'
                #===================================================================================================
                #   OSDDriver Objects
                #===================================================================================================
                if ($PSCmdlet.ParameterSetName -eq 'MultiPack') {
                    $PackagedDriverGroup = Get-PathOSDD -Path (Join-Path $WorkspacePackage (Join-Path 'DellMultiPack' $MultiPackName))
                    $OSDDriver | ConvertTo-Json | Out-File -FilePath "$PackagedDriverGroup\$($OSDDriver.DriverName).drvpack" -Force
                }
                else {
                    $PackagedDriverGroup = Get-PathOSDD -Path (Join-Path $WorkspacePackage $OSDGroup)
                    $OSDDriver | Export-Clixml -Path "$ExpandedDriverPath\OSDDriver.clixml" -Force
                    $OSDDriver | ConvertTo-Json | Out-File -FilePath "$ExpandedDriverPath\OSDDriver.drvpack" -Force
                }
                #===================================================================================================
                #   Pack
                #===================================================================================================
                if ($PSCmdlet.ParameterSetName -eq 'Pack') {
                    #===================================================================================================
                    #   Create Package
                    #===================================================================================================
                    Write-Verbose "Verify: $PackagedDriverPath"
                    if (Test-Path "$PackagedDriverPath") {
                        Write-Warning "Driver Pack: $PackagedDriverPath already exists and will not be created"
                    } else {
                        Write-Warning "Driver Pack: Generating $PackagedDriverPath ... This will take a while"
                        New-CabFileDell $ExpandedDriverPath $PackagedDriverGroup $RemoveAudio $RemoveVideoAMD $RemoveVideoNvidia
                    }
                    #===================================================================================================
                    #   Verify Driver Package
                    #===================================================================================================
                    if (-not (Test-Path "$PackagedDriverPath")) {
                        Write-Warning "Driver Package: Could not package Driver to $PackagedDriverPath ..."
                        $OSDDriver | Export-Clixml -Path "$ExpandedDriverPath\OSDDriver.clixml" -Force
                        $OSDDriver | ConvertTo-Json | Out-File -FilePath "$ExpandedDriverPath\OSDDriver.drvpack" -Force
                        $OSDDriver | ConvertTo-Json | Out-File -FilePath "$PackagedDriverGroup\$($DriverName).drvpack" -Force
                        Continue
                    }
                    $OSDDriver.OSDStatus = "Packaged"
                    #===================================================================================================
                    #   Export Results
                    #===================================================================================================
                    $OSDDriver | Export-Clixml -Path "$ExpandedDriverPath\OSDDriver.clixml" -Force
                    $OSDDriver | ConvertTo-Json | Out-File -FilePath "$ExpandedDriverPath\OSDDriver.drvpack" -Force
                    $OSDDriver | ConvertTo-Json | Out-File -FilePath "$PackagedDriverGroup\$($DriverName).drvpack" -Force
                    #===================================================================================================
                    #   Publish-OSDDriverScripts
                    #===================================================================================================
                    Publish-OSDDriverScripts -PublishPath $PackagedDriverGroup
                }
                #===================================================================================================
                #   MultiPack
                #===================================================================================================
                if ($PSCmdlet.ParameterSetName -eq 'MultiPack') {
                    $MultiPackFiles = @()
                    #===================================================================================================
                    #   Get SourceContent
                    #===================================================================================================
                    $SourceContent = @()
                    $SourceContent = Get-ChildItem "$ExpandedDriverPath\*\*\*\*\*" -Directory | Select-Object -Property *
                    #===================================================================================================
                    #   Filter SourceContent
                    #===================================================================================================
                    if ($RemoveAudio.IsPresent) {$SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Audio\\'}}
                    if ($NoVideo.IsPresent) {$SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Video\\'}}
                    foreach ($DriverDir in $SourceContent) {
                        if (($DriverDir.FullName -match '\\Video\\') -and (Get-ChildItem "$($DriverDir.FullName)" igfxEM.exe -File -Recurse)) {
                            Write-Host "IntelDisplay: $($DriverDir.FullName)" -ForegroundColor Gray
                            Continue
                        }
                        if ($RemoveVideoAMD.IsPresent) {
                            if (($DriverDir.FullName -match '\\Video\\') -and (Get-ChildItem "$($DriverDir.FullName)" ati*.dl* -File -Recurse)) {
                                Write-Host "AMDDisplay: $($DriverDir.FullName)" -ForegroundColor Gray
                                Continue
                            }
                        }
                        if ($RemoveVideoNvidia.IsPresent) {
                            if (($DriverDir.FullName -match '\\Video\\') -and (Get-ChildItem "$($DriverDir.FullName)" nv*.dl* -File -Recurse)) {
                                Write-Host "NvidiaDisplay: $($DriverDir.FullName)" -ForegroundColor Gray
                                Continue
                            }
                        }
<#                         if ($DriverDir.FullName -match '\\Video\\') {
                            New-CabDellMultiPack -ExpandedDriverPath "$($DriverDir.FullName)" -PublishPath "$PackagedDriverGroup\$($DriverDir.Parent)" -MakePnp -DriverClass Display
                        } else {
                            New-CabDellMultiPack -ExpandedDriverPath "$($DriverDir.FullName)" -PublishPath "$PackagedDriverGroup\$($DriverDir.Parent)" -MakePnp
                        } #>
                        $MultiPackFiles += $DriverDir
                        New-CabDellMultiPack -ExpandedDriverPath "$($DriverDir.FullName)" -PublishPath "$PackagedDriverGroup\$(($DriverDir.Parent).parent)\$($DriverDir.Parent)"
                    }
                    foreach ($MultiPackFile in $MultiPackFiles) {
                        $MultiPackFile.Name = "$(($MultiPackFile.Parent).Parent)\$($MultiPackFile.Parent)\$($MultiPackFile.Name).cab"
                    }
                    $MultiPackFiles = $MultiPackFiles | Select-Object -ExpandProperty Name
                    if (!(Test-Path "$PackagedDriverGroup\$($DriverName).multipack")) {
                        $MultiPackFiles | ConvertTo-Json | Out-File -FilePath "$PackagedDriverGroup\$($DriverName).multipack" -Force
                    }
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