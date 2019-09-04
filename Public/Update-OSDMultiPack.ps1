<#
.SYNOPSIS
Downloads Dell Model Packs and updates an existing DellMultiPack

.DESCRIPTION
Downloads Dell Model Packs to $WorkspacePath\Download\DellModel
Creates a Dell MultiPack in $WorkspacePath\Packages\DellMultiPack
Requires BITS for downloading the Downloads
Requires Internet access

.LINK
https://osddrivers.osdeploy.com/module/functions/update-dellmultipack

.PARAMETER WorkspacePath
Directory to the OSDDrivers Workspace.  This contains the Download, Expand, and Package subdirectories

.PARAMETER Force
Bypass the Remove Driver Parameter check

.PARAMETER SaveAudioDrivers
Removes drivers in the Audio Directory from being added to the CAB or MultiPack

.PARAMETER RemoveAmdVideo
Removes AMD Video Drivers from being added to the CAB or MultiPack

.PARAMETER RemoveIntelVideo
Removes Intel Video Drivers from being added to a MultiPack

.PARAMETER RemoveNvidiaVideo
Removes Nvidia Video Drivers from being added to the CAB or MultiPack
#>
function Update-OSDMultiPack {
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
        #====================================================================
        #   Switches
        #====================================================================
        [switch]$SaveAudioDrivers = $false,
        [switch]$SaveAmdVideo = $false,
        [switch]$SaveIntelVideo = $false,
        [switch]$SaveNvidiaVideo = $false
        #====================================================================
    )
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
    #===================================================================================================
    #   Defaults
    #===================================================================================================
    $Expand = $true
    if ($SaveAudioDrivers -eq $false) {Write-Warning "Audio Drivers will be removed from resulting packages"}
    if ($SaveAmdVideo -eq $false) {Write-Warning "AMD Video Drivers will be removed from resulting packages"}
    if ($SaveIntelVideo -eq $false) {Write-Warning "Intel Video Drivers will be removed from resulting packages"}
    if ($SaveNvidiaVideo -eq $false) {Write-Warning "Nvidia Video Drivers will be removed from resulting packages"}
    #===================================================================================================
    #   OSDDrivers
    #===================================================================================================
    $AllOSDDrivers = @()
    $AllOSDDrivers = Get-DellModelPack -DownloadPath (Join-Path $WorkspaceDownload 'DellModel')
    $AllOSDDrivers += Get-HpModelPack -DownloadPath (Join-Path $WorkspaceDownload 'HpModel')
    #===================================================================================================
    #   UpdateMultiPacks
    #===================================================================================================
    $UpdateMultiPacks = @()
    $UpdateMultiPacks = Get-ChildItem $WorkspacePackages -Directory | Where-Object {$_.Name -match 'DellMultiPack' -or $_.Name -match 'HpMultiPack'} | Select-Object Name, FullName
    $UpdateMultiPacks = $UpdateMultiPacks | Out-GridView -PassThru -Title 'Select MultiPacks to Update and press OK'
    #===================================================================================================
    if ($AllOSDDrivers -and $UpdateMultiPacks) {
        foreach ($UpdateMultiPack in $UpdateMultiPacks) {
            #===================================================================================================
            #   Get DRVPACKS
            #===================================================================================================
            $PackagePath = $UpdateMultiPack.FullName
            Write-Host "MultiPack: $PackagePath" -ForegroundColor Green
            Publish-OSDDriverScripts -PublishPath $PackagePath

            $DrvPacks = Get-ChildItem $PackagePath *.drvpack | Select-Object FullName
            $DriverPacks = @()
            $DriverPacks = foreach ($DrvPack in $DrvPacks) {
                Get-Content $DrvPack.FullName | ConvertFrom-Json
            }
            $DriverPacks = $DriverPacks | Sort-Object DriverGrouping -Descending -Unique
            #===================================================================================================
            #   Get OSDDrivers
            #===================================================================================================
            $OSDDrivers = @()
            $OSDDrivers = $AllOSDDrivers
            $OSDDrivers = $OSDDrivers.Where({$_.DriverGrouping -in $DriverPacks.DriverGrouping})
            Get-ChildItem $PackagePath *.clixml | foreach {Remove-Item -Path $_.FullName -Force | Out-Null}
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
            if ($UpdateMultiPack.Name -match 'x86') {$OsArch = 'x86'}
            else {$OsArch = 'x64'}
            #===================================================================================================
            #   Generate WMI
            #===================================================================================================
            $OSDDrivers | Export-Clixml "$(Join-Path $PackagePath 'OSDMultiPack.clixml')"
            $OSDWmiQuery = @()
            Get-ChildItem $PackagePath *.clixml | foreach {$OSDWmiQuery += Import-Clixml $_.FullName}
            if ($OSDWmiQuery) {
                if ($OSDGroup -match 'DellModel') {
                    $OSDWmiQuery | Show-OSDWmiQuery -Make Dell -Result Model | Out-File "$PackagePath\WmiQuery.txt" -Force
                    $OSDWmiQuery | Show-OSDWmiQuery -Make Dell -Result SystemId | Out-File "$PackagePath\WmiQuerySystemId.txt" -Force
                }
                if ($OSDGroup -match 'HpModel') {
                    $OSDWmiQuery | Show-OSDWmiQuery -Make HP -Result Model | Out-File "$PackagePath\WmiQuery.txt" -Force
                    $OSDWmiQuery | Show-OSDWmiQuery -Make HP -Result SystemId | Out-File "$PackagePath\WmiQuerySystemId.txt" -Force
                }
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
                    #$PackagedDriverPath = (Join-Path $WorkspacePackages (Join-Path $OSDGroup $OSDCabFile))

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
                    #   Generate DRVPACK
                    #===================================================================================================
                    $OSDDriver | ConvertTo-Json | Out-File -FilePath "$PackagePath\$($OSDDriver.DriverName).drvpack" -Force
                    #===================================================================================================
                    #   MultiPack
                    #===================================================================================================
                    $MultiPackFiles = @()
                    $SourceContent = @()
                    if ($OSDGroup -eq 'DellModel') {
                        if ($OsArch -eq 'x86') {
                            $SourceContent = Get-ChildItem "$ExpandedDriverPath\*\*\x86\*\*" -Directory | Select-Object -Property *
                        } else {
                            $SourceContent = Get-ChildItem "$ExpandedDriverPath\*\*\x64\*\*" -Directory | Select-Object -Property *
                        }
                    }
                    if ($OSDGroup -eq 'HpModel') {
                        $SourceContent = Get-ChildItem "$ExpandedDriverPath\*\*\*\*\*" -Directory | Select-Object -Property *
                    }
                    #===================================================================================================
                    #   Dell
                    #===================================================================================================
                    if ($OSDGroup -eq 'DellModel') {
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
                    if ($OSDGroup -eq 'HpModel') {
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
            }
        
        
        Write-Host ""
        }
    }
    #===================================================================================================
    #   Publish-OSDDriverScripts
    #===================================================================================================
    Write-Host "Complete!" -ForegroundColor Green
    #===================================================================================================
}