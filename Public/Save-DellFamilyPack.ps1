<#
.SYNOPSIS
Downloads Dell Family Packs

.DESCRIPTION
Downloads Dell Family Packs to $WorkspacePath\Download\DellFamily
Requires BITS for downloading the Downloads
Requires Internet access

.LINK
https://osddrivers.osdeploy.com/module/functions/save-dellfamilypack

.PARAMETER WorkspacePath
Directory to the OSDDrivers Workspace.  This contains the Download, Expand, and Package subdirectories
Downloaded Dell Family Packs will be saved to $WorkspacePath\Download\DellFamily

.PARAMETER Expand
Expands the Dell Family Pack after Download
#>
function Save-DellFamilyPack {
    [CmdletBinding()]
    Param (
        #[Parameter(ValueFromPipeline = $true)]
        #[Object[]]$InputObject,

        [Parameter(Mandatory)]
        [string]$WorkspacePath,

        [switch]$Expand
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

        if ($MyInvocation.MyCommand.Name -eq 'Save-DellModelPack') {
            $WorkspacePackage = Get-PathOSDD -Path (Join-Path $OSDWorkspace 'Package')
            Write-Verbose "Workspace Package: $WorkspacePackage" -Verbose
            #Publish-OSDDriverScripts -PublishPath $WorkspacePackage
        }
        #===================================================================================================
    }

    Process {
        #===================================================================================================
        #   Defaults
        #===================================================================================================
        if ($MyInvocation.MyCommand.Name -eq 'Save-DellFamilyPack') {
            $OSDGroup = 'DellFamily'
            $OsVersion = '10.0'
            $OsArch = 'x64'
            $RemoveAudio = $true
            $RemoveAmdVideo = $true
            $RemoveNvidiaVideo = $true
        }
        if ($MyInvocation.MyCommand.Name -eq 'Save-DellModelPack') {
            $OSDGroup = 'DellModel'
            #$OsVersion = '10.0'
            #$OsArch = 'x64'
            #$RemoveAudio = $true
            #$RemoveAmdVideo = $true
            #$RemoveNvidiaVideo = $true
            Publish-OSDDriverScripts -PublishPath (Join-Path $WorkspaceDownload 'DellModel')
        }
        if ($PSCmdlet.ParameterSetName -eq 'MultiPack') {
            $Expand = $true
            $OSDGroup = 'DellModel'
            #$OsVersion = '10.0'
            #$OsArch = 'x64'
            #$RemoveAudio = $true
            #$RemoveAmdVideo = $true
            #$RemoveNvidiaVideo = $true
            if ($RemoveAudio -eq $true) {Write-Warning "Audio Drivers will be removed from resulting packages"}
            if ($RemoveAmdVideo -eq $true) {Write-Warning "AMD Video Drivers will be removed from resulting packages"}
            if ($RemoveIntelVideo -eq $true) {Write-Warning "Intel Video Drivers will be removed from resulting packages"}
            if ($RemoveNvidiaVideo -eq $true) {Write-Warning "Nvidia Video Drivers will be removed from resulting packages"}
        } else {
            $RemoveIntelVideo = $true
        }

        if ($PSCmdlet.ParameterSetName -eq 'Pack') {
            $Expand = $true
            if ($RemoveAudio -eq $true) {Write-Warning "Audio Drivers will be removed from resulting packages"}
            Write-Warning "Intel Video Drivers will be removed from resulting packages by default"
            if ($RemoveAmdVideo -eq $true) {Write-Warning "AMD Video Drivers will be removed from resulting packages"}
            if ($RemoveNvidiaVideo -eq $true) {Write-Warning "Nvidia Video Drivers will be removed from resulting packages"}
        }
        #===================================================================================================
        #   Get-OSDDrivers
        #===================================================================================================
        $OSDDrivers = @()
        if ($InputObject) {
            $SkipGridView = $true
            $OSDDrivers = $InputObject
        } else {
            if ($MyInvocation.MyCommand.Name -eq 'Save-DellFamilyPack') {$OSDDrivers = Get-DellFamilyPack}
            if ($MyInvocation.MyCommand.Name -eq 'Save-DellModelPack') {$OSDDrivers = Get-DellModelPack -DownloadPath (Join-Path $WorkspaceDownload 'DellModel')}
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
            #$PackagedDriverPath     = (Join-Path $WorkspacePackage (Join-Path $OSDGroup $OSDCabFile))
            Write-Verbose "DownloadedDriverGroup: $DownloadedDriverGroup"
            Write-Verbose "DownloadedDriverPath: $DownloadedDriverPath"
            Write-Verbose "ExpandedDriverPath: $ExpandedDriverPath"
            #Write-Verbose "PackagedDriverPath: $PackagedDriverPath"

            if (Test-Path "$DownloadedDriverPath") {$OSDDriver.OSDStatus = 'Downloaded'}
            if (Test-Path "$ExpandedDriverPath") {$OSDDriver.OSDStatus = 'Expanded'}
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
                #$PackagedDriverPath = (Join-Path $WorkspacePackage (Join-Path $OSDGroup $OSDCabFile))

                if (-not(Test-Path "$DownloadedDriverGroup")) {New-Item $DownloadedDriverGroup -Directory -Force | Out-Null}

                Write-Verbose "DownloadedDriverPath: $DownloadedDriverPath"
                Write-Verbose "ExpandedDriverPath: $ExpandedDriverPath"
                #Write-Verbose "PackagedDriverPath: $PackagedDriverPath"

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
                if (Test-Path "$ExpandedDriverPath") {
                    $OSDDriver | Export-Clixml -Path "$ExpandedDriverPath\OSDDriver.clixml" -Force
                } else {
                    Write-Warning "Driver Expand: Could not expand Driver to $ExpandedDriverPath ... Exiting"
                    Continue
                }
                $OSDDriver.OSDStatus = 'Expanded'
            }
        } else {
            Return $OSDDrivers
        }
    }

    End {
        #===================================================================================================
        #   Complete
        #===================================================================================================
        Write-Host "Complete!" -ForegroundColor Green
        #===================================================================================================
    }
}