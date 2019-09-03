<#
.SYNOPSIS
Downloads Hp Model Packs and creates a MultiPack

.DESCRIPTION
Downloads Hp Model Packs to $WorkspacePath\Download\HpModel
Creates a Hp MultiPack in $WorkspacePath\Packages\HpMultiPack
Requires BITS for downloading the Downloads
Requires Internet access

.LINK
https://osddrivers.osdeploy.com/module/functions/save-HpMultiPack

.PARAMETER WorkspacePath
Directory to the OSDDrivers Workspace.  This contains the Download, Expand, and Package subdirectories

.PARAMETER AppendName
Appends the string to the HpMultiPack Name

.PARAMETER Generation
Generation of the Hp Model

.PARAMETER OsArch
Operating System Architecture of the Model Pack to be extracted

.PARAMETER OsVersion
Operating System Version of the Model Pack to be extracted

.PARAMETER SystemFamily
Filters compatibility to Latitude, Optiplex, or Precision.  Venue, Vostro, and XPS are not included

.PARAMETER Expand
Expands the downloaded Hp Model Packs

.PARAMETER RemoveAudio
Removes drivers in the Audio Directory from being added to the CAB or MultiPack

.PARAMETER RemoveAmdVideo
Removes AMD Video Drivers from being added to the CAB or MultiPack

.PARAMETER RemoveIntelVideo
Removes Intel Video Drivers from being added to a MultiPack

.PARAMETER RemoveNvidiaVideo
Removes Nvidia Video Drivers from being added to the CAB or MultiPack
#>
function Save-OSDMultiPack {
    [CmdletBinding()]
    Param (
        #====================================================================
        #   InputObject
        #====================================================================
        [Parameter(ValueFromPipeline = $true)]
        [Object[]]$InputObject,
        #====================================================================
        #   Mandatory
        #====================================================================
        [Parameter(Mandatory)]
        [string]$WorkspacePath,

        [Parameter(Mandatory)]
        [ValidateSet ('Dell','HP')]
        [string]$Make,

        #[Parameter(Mandatory)]
        [string]$AppendName = 'None',
        #====================================================================
        #   Filters
        #====================================================================
        [ValidateSet ('G0','G1','G2','G3','G4','G5','G6','X1','X2','X3','X4','X5','X6','X7','X8','X9','X10')]
        [string]$Generation,

        [ValidateSet ('x64','x86')]
        [string]$OsArch = 'x64',

        [ValidateSet ('10.0','6.3','6.1')]
        [string]$OsVersion = '10.0',

        #[ValidateSet ('Latitude','Optiplex','Precision')]
        #[string]$SystemFamily,
        #====================================================================
        #   Switches
        #====================================================================
        #[switch]$Expand,
        [switch]$SaveAudioDrivers = $false,
        [switch]$SaveAmdVideo = $false,
        [switch]$SaveIntelVideo = $false,
        [switch]$SaveNvidiaVideo = $false
        #====================================================================
    )

    Begin {
        #===================================================================================================
        #   Defaults
        #===================================================================================================
        if ($Make -eq 'Dell') {
            $OSDGroup = 'DellModel'
            $MultiPack = 'DellMultiPack'
        }
        if ($Make -eq 'HP') {
            $OSDGroup = 'HpModel'
            $MultiPack = 'HpMultiPack'
        }
        #===================================================================================================
        #   CustomName
        #===================================================================================================
        if ($AppendName -eq 'None') {
            $CustomName = "$MultiPack $OsVersion $OsArch"
        } else {
            $CustomName = "$MultiPack $OsVersion $OsArch $AppendName"
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
        Write-Verbose "MultiPack Path: $PackagePath" -Verbose
        Publish-OSDDriverScripts -PublishPath $PackagePath
        #===================================================================================================
    }

    Process {
        #===================================================================================================
        #   Defaults
        #===================================================================================================
        $Expand = $true
        if ($SaveAudioDrivers -eq $false) {Write-Warning "Audio Drivers will be removed from resulting packages"}
        if ($SaveAmdVideo -eq $false) {Write-Warning "AMD Video Drivers will be removed from resulting packages"}
        if ($SaveIntelVideo -eq $false) {Write-Warning "Intel Video Drivers will be removed from resulting packages"}
        if ($SaveNvidiaVideo -eq $false) {Write-Warning "Nvidia Video Drivers will be removed from resulting packages"}
        Publish-OSDDriverScripts -PublishPath (Join-Path $WorkspaceDownload $OSDGroup)
        #===================================================================================================
        #   Get-OSDDrivers
        #===================================================================================================
        $OSDDrivers = @()
        if ($InputObject) {
            $SkipGridView = $true
            $OSDDrivers = $InputObject
        } else {
            if ($OSDGroup -eq 'DellModel') {
                $OSDDrivers = Get-DellModelPack -DownloadPath (Join-Path $WorkspaceDownload $OSDGroup)
                $OSDDrivers | Export-Clixml "$(Join-Path $WorkspaceDownload $(Join-Path 'DellModel' 'DellModelPack.clixml'))"
            }
            if ($OSDGroup -eq 'HpModel') {
                $OSDDrivers = Get-HpModelPack -DownloadPath (Join-Path $WorkspaceDownload $OSDGroup)
                $OSDDrivers | Export-Clixml "$(Join-Path $WorkspaceDownload $(Join-Path 'HpModel' 'HpModelPack.clixml'))"
            }
            if ($OSDGroup -eq 'DellFamily') {
                $OSDDrivers = Get-DellFamilyPack
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
        }
        #===================================================================================================
        #   Filters
        #===================================================================================================
        if ($OsArch) {$OSDDrivers = $OSDDrivers | Where-Object {$_.OsArch -match "$OsArch"}}
        if ($OsVersion) {$OSDDrivers = $OSDDrivers | Where-Object {$_.OsVersion -match "$OsVersion"}}
        if ($Generation) {$OSDDrivers = $OSDDrivers | Where-Object {$_.Generation -eq "$Generation"}}
        if ($SystemFamily) {$OSDDrivers = $OSDDrivers | Where-Object {$_.SystemFamily -match "$SystemFamily"}}
        #===================================================================================================
        #   GridView
        #===================================================================================================
        $OSDDrivers = $OSDDrivers | Sort-Object LastUpdate -Descending
        if ($SkipGridView) {
            #Write-Warning "SkipGridView: Skipping Out-GridView"
        } else {
            $OSDDrivers = $OSDDrivers | Out-GridView -PassThru -Title "Select Driver Packs to MultiPack and press OK"
        }
        #===================================================================================================
        #   Export MultiPack Object
        #===================================================================================================
        $OSDDrivers | Export-Clixml "$PackagePath\$CustomName $(Get-Date -Format yyMMddHHmmssfff).clixml" -Force
        $OSDWmiQuery = @()
        Get-ChildItem $PackagePath *.clixml | foreach {$OSDWmiQuery += Import-Clixml $_.FullName}
        if ($OSDWmiQuery) {
            $OSDWmiQuery | Show-OSDWmiQuery -Make HP -Result Model | Out-File "$PackagePath\WmiQuery.txt" -Force
            $OSDWmiQuery | Show-OSDWmiQuery -Make HP -Result SystemId | Out-File "$PackagePath\WmiQuerySystemId.txt" -Force
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
                Write-Verbose "DriverName: $DriverName" -Verbose

                $DownloadFile = $OSDDriver.DownloadFile
                Write-Verbose "DownloadFile: $DownloadFile"

                $OSDGroup = $OSDDriver.OSDGroup
                Write-Verbose "OSDGroup: $OSDGroup"

                $OSDCabFile = "$($DriverName).cab"
                Write-Verbose "OSDCabFile: $OSDCabFile"

                $DownloadedDriverGroup = (Join-Path $WorkspaceDownload $OSDGroup)
                $DownloadedDriverPath =  (Join-Path $DownloadedDriverGroup $DownloadFile)
                $ExpandedDriverPath = (Join-Path $WorkspaceExpand (Join-Path $OSDGroup $DriverName))
                #$PackagedDriverPath = (Join-Path $WorkspacePackages (Join-Path $OSDGroup $OSDCabFile))

                if (-not(Test-Path "$DownloadedDriverGroup")) {New-Item $DownloadedDriverGroup -Directory -Force | Out-Null}

                Write-Verbose "DownloadedDriverPath: $DownloadedDriverPath"
                Write-Verbose "ExpandedDriverPath: $ExpandedDriverPath"
                #Write-Verbose "PackagedDriverPath: $PackagedDriverPath"

                Write-Host "$DriverName" -ForegroundColor Green
                $DownloadModels = $OSDDriver.Model | Sort-Object
                foreach ($Model in $DownloadModels) {Write-Host "$($Model)"}
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
                if ($Expand) {
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
                        if ($DownloadFile -match '.exe') {
                            #Thanks Maurice @ Driver Automation Tool
                            $HPSoftPaqSilentSwitches = "-PDF -F" + "$ExpandedDriverPath" + " -S -E"
                            Start-Process -FilePath "$DownloadedDriverPath" -ArgumentList $HPSoftPaqSilentSwitches -Verb RunAs -Wait
                        }
                    }
                } else {
                    Continue
                }
                #===================================================================================================
                #   Verify Driver Expand
                #===================================================================================================
                if (Test-Path "$ExpandedDriverPath") {
                    if ($OSDGroup -eq 'DellModel') {
                        $NormalizeContent = Get-ChildItem "$ExpandedDriverPath\*\*\*\*\*" -Directory | Where-Object {($_.Name -match '_A') -and ($_.Name -notmatch '_A00-00')}
                        foreach ($FunkyNameDriver in $NormalizeContent) {
                            $NewBaseName = ($FunkyNameDriver.Name -split '_')[0]
                            Write-Verbose "Renaming '$($FunkyNameDriver.FullName)' to '$($NewBaseName)_A00-00'" -Verbose
                            Rename-Item "$($FunkyNameDriver.FullName)" -NewName "$($NewBaseName)_A00-00" -Force | Out-Null
                        }
                    }
                } else {
                    Write-Warning "Driver Expand: Could not expand Driver to $ExpandedDriverPath ... Exiting"
                    Continue
                }
                $OSDDriver.OSDStatus = 'Expanded'
                #===================================================================================================
                #   OSDDriver Objects
                #===================================================================================================
                #$PackagedDriverGroup = Get-PathOSDD -Path (Join-Path $WorkspaceProject (Join-Path 'HpMultiPack' $CustomName = 'HpMultiPack'))
<#                 if ($SplitGeneration.IsPresent) {
                    $OSDWmiQuery = @()
                    Get-ChildItem $PackagedDriverGroup *.clixml | foreach {$OSDWmiQuery += Import-Clixml $_.FullName}
                    $OSDWmiQuery = $OSDWmiQuery | Where-Object {$_.Generation -match $OSDDriver.Generation}

                    $PackagedDriverGroup = Get-PathOSDD -Path (Join-Path $WorkspaceProject (Join-Path 'HpMultiPack' (Join-Path $CustomName = 'HpMultiPack' "Hp $($OSDDriver.Generation)")))

                    if ($OSDWmiQuery) {
                        $OSDWmiQuery | Show-OSDWmiQuery | Out-File "$PackagedDriverGroup\WmiQuery.txt" -Force
                    }
                } #>
                $OSDDriver | ConvertTo-Json | Out-File -FilePath "$PackagePath\$($OSDDriver.DriverName).drvpack" -Force
                #===================================================================================================
                #   MultiPack
                #===================================================================================================
                $MultiPackFiles = @()
                $SourceContent = @()
                if ($Make -eq 'Dell') {
                    if ($OsArch -eq 'x86') {
                        $SourceContent = Get-ChildItem "$ExpandedDriverPath\*\*\x86\*\*" -Directory | Select-Object -Property *
                    } else {
                        $SourceContent = Get-ChildItem "$ExpandedDriverPath\*\*\x64\*\*" -Directory | Select-Object -Property *
                    }
                }
                if ($Make -eq 'Hp') {
                    $SourceContent = Get-ChildItem "$ExpandedDriverPath\*\*\*\*\*" -Directory | Select-Object -Property *
                }
                #===================================================================================================
                #   Dell
                #===================================================================================================
                if ($Make -eq 'Dell') {
                    if ($SaveAudioDrivers -eq $false) {$SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Audio\\'}}
                    #if ($RemoveVideo.IsPresent) {$SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Video\\'}}
                    foreach ($DriverDir in $SourceContent) {
                        if ($SaveAmdVideo -eq $false) {
                            if (($DriverDir.FullName -match '\\Video\\') -and (Get-ChildItem "$($DriverDir.FullName)" ati*.dl* -File -Recurse)) {
                                Write-Host "AMDDisplay: $($DriverDir.FullName)" -ForegroundColor Gray
                                Continue
                            }
                        }
                        if ($SaveNvidiaVideo -eq $false) {
                            if (($DriverDir.FullName -match '\\Video\\') -and (Get-ChildItem "$($DriverDir.FullName)" nv*.dl* -File -Recurse)) {
                                Write-Host "NvidiaDisplay: $($DriverDir.FullName)" -ForegroundColor Gray
                                Continue
                            }
                        }
                        if ($SaveIntelVideo -eq $false) {
                            if (($DriverDir.FullName -match '\\Video\\') -and (Get-ChildItem "$($DriverDir.FullName)" igfx*.* -File -Recurse)) {
                                Write-Host "IntelDisplay: $($DriverDir.FullName)" -ForegroundColor Gray
                                Continue
                            }
                        }
                        $MultiPackFiles += $DriverDir
                        if ($SaveIntelVideo -eq $true) {
                            New-MultiPackCabFile "$($DriverDir.FullName)" "$PackagePath\$(($DriverDir.Parent).parent)\$($DriverDir.Parent)"
                        } else {
                            New-MultiPackCabFile "$($DriverDir.FullName)" "$PackagePath\$(($DriverDir.Parent).parent)\$($DriverDir.Parent)" $true
                        }
                    }
                }
                #===================================================================================================
                #   HP
                #===================================================================================================
                if ($Make -eq 'Hp') {
                    if ($SaveAudioDrivers -eq $false) {$SourceContent = $SourceContent | Where-Object {"$($_.Parent.Parent)" -ne 'audio'}}
                    #if ($RemoveVideo.IsPresent) {$SourceContent = $SourceContent | Where-Object {"$($_.Parent.Parent)" -ne 'graphics'}}
                    if ($SaveAmdVideo -eq $false) {$SourceContent = $SourceContent | Where-Object {"$($_.FullName)" -notmatch '\\graphics\\amd\\'}}
                    if ($SaveIntelVideo -eq $false) {$SourceContent = $SourceContent | Where-Object {"$($_.FullName)" -notmatch '\\graphics\\intel\\'}}
                    if ($SaveNvidiaVideo -eq $false) {$SourceContent = $SourceContent | Where-Object {"$($_.FullName)" -notmatch '\\graphics\\nvidia\\'}}
                    foreach ($DriverDir in $SourceContent) {
                        $MultiPackFiles += $DriverDir
                        New-MultiPackCabFile "$($DriverDir.FullName)" "$PackagePath\$(($DriverDir.Parent).parent)\$($DriverDir.Parent)"
                    }
                }
                #===================================================================================================
                #   Publish Objects
                #===================================================================================================
                foreach ($MultiPackFile in $MultiPackFiles) {
                    $MultiPackFile.Name = "$(($MultiPackFile.Parent).Parent)\$($MultiPackFile.Parent)\$($MultiPackFile.Name).cab"
                }
                $MultiPackFiles = $MultiPackFiles | Select-Object -ExpandProperty Name
                $MultiPackFiles | ConvertTo-Json | Out-File -FilePath "$PackagePath\$($DriverName).multipack" -Force
                #Publish-OSDDriverScripts -PublishPath $PackagePath
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