<#
.SYNOPSIS
Updates MultiPacks

.DESCRIPTION
Updates MultiPacks
Requires BITS for downloading the Downloads
Requires Internet access

.LINK
https://osddrivers.osdeploy.com/module/functions/update-osddrivermultipack

.PARAMETER SaveAudio


.PARAMETER SaveAmdVideo


.PARAMETER SaveIntelVideo


.PARAMETER SaveNvidiaVideo

#>
function Update-OSDDriversMultiPack {
    [CmdletBinding()]
    Param (
        #Manufacturer of the Computer Model
        [Parameter (ValueFromPipelineByPropertyName = $true)]
        [ValidateSet ('Dell','HP')]
        [string]$Make,

        #Removes Superseded Drivers from the MultiPack
        [switch]$RemoveSuperseded,

        #Doesn't remove the Audio Drivers from the MultiPack
        [switch]$SaveAudio = $false,

        #Doesn't remove the AMD Video Drivers from the DMultiPack
        [switch]$SaveAmdVideo = $false,
        
        #Doesn't remove the Intel Video Drivers from the MultiPack
        [switch]$SaveIntelVideo = $false,
        
        #Doesn't remove the Nvidia Video Drivers from the MultiPack
        [switch]$SaveNvidiaVideo = $false,

        #Automatically updates all MultiPacks
        [switch]$UpdateAll = $false
    )
    Begin {
        #===================================================================================================
        #   Get-OSDDrivers
        #===================================================================================================
        Get-OSDDrivers -CreatePaths -HideDetails
        #===================================================================================================
        #   Display Paths
        #===================================================================================================
        Write-Host "Home: $GetOSDDriversHome" -ForegroundColor Gray
        Write-Host "Download: $SetOSDDriversPathDownload" -ForegroundColor Gray
        Write-Host "Expand: $SetOSDDriversPathExpand" -ForegroundColor Gray
        Write-Host "Packages: $SetOSDDriversPathPackages" -ForegroundColor Gray
        Publish-OSDDriverScripts -PublishPath $SetOSDDriversPathPackages
        #===================================================================================================
        #   Defaults
        #===================================================================================================
        $Expand = $true

        if ($SaveAudio -eq $false) {Write-Warning "Audio Drivers will be removed from resulting packages"}
        if ($SaveAmdVideo -eq $false) {Write-Warning "AMD Video Drivers will be removed from resulting packages"}
        if ($SaveIntelVideo -eq $false) {Write-Warning "Intel Video Drivers will be removed from resulting packages"}
        if ($SaveNvidiaVideo -eq $false) {Write-Warning "Nvidia Video Drivers will be removed from resulting packages"}

        $AllOSDDrivers = @()
        if ($Make -eq 'Dell') {
            $OSDGroup = 'DellModel'
            $MultiPack = 'DellMultiPack'
            $AllOSDDrivers = Get-OSDDriver DellModel
        } elseif ($Make -eq 'HP') {
            $OSDGroup = 'HpModel'
            $MultiPack = 'HpMultiPack'
            $AllOSDDrivers = Get-OSDDriver HpModel
        } else {
            $OSDGroup = ''
            $MultiPack = 'Multi'
            $AllOSDDrivers = Get-OSDDriver DellModel
            $AllOSDDrivers += Get-OSDDriver HpModel
        }
        #===================================================================================================
        #   MultiPacksToUpdate
        #===================================================================================================
        $MultiPacksToUpdate = @()
        $MultiPacksToUpdate = Get-ChildItem $SetOSDDriversPathPackages -Directory
        if ($MultiPack -eq 'DellMultiPack') {$MultiPacksToUpdate = $MultiPacksToUpdate | Where-Object {$_.Name -match 'DellMultiPack'} | Select-Object Name, FullName}
        if ($MultiPack -eq 'HpMultiPack') {$MultiPacksToUpdate = $MultiPacksToUpdate | Where-Object {$_.Name -match 'HpMultiPack'} | Select-Object Name, FullName}
        if ($MultiPack -eq 'Multi') {$MultiPacksToUpdate = $MultiPacksToUpdate | Where-Object {$_.Name -match 'DellMultiPack' -or $_.Name -match 'HpMultiPack'} | Select-Object Name, FullName}
        if ($UpdateAll -eq $false) {
            $MultiPacksToUpdate = $MultiPacksToUpdate | Out-GridView -PassThru -Title 'Select MultiPacks to Update and press OK'
        }
        #===================================================================================================
    }
    Process {
        Write-Verbose '========================================================================================' -Verbose
        Write-Verbose $MyInvocation.MyCommand.Name -Verbose

        #===================================================================================================
        if ($AllOSDDrivers -and $MultiPacksToUpdate) {
            foreach ($UpdateMultiPack in $MultiPacksToUpdate) {
                #===================================================================================================
                #   Get DRVPACKS
                #===================================================================================================
                $PackagePath = $UpdateMultiPack.FullName
                Write-Host "MultiPack: $PackagePath" -ForegroundColor Green
                Publish-OSDDriverScripts -PublishPath $PackagePath

                $DrvPacks = Get-ChildItem $PackagePath *.drvpack | Select-Object FullName
                $DriverPacks = @()
                $DriverPacks = foreach ($item in $DrvPacks) {
                    Get-Content $item.FullName | ConvertFrom-Json
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

                    $DownloadedDriverGroup  = (Join-Path $SetOSDDriversPathDownload $OSDGroup)

                    $DownloadedDriverPath = (Join-Path $SetOSDDriversPathDownload (Join-Path $OSDGroup $DownloadFile))
                    if (Test-Path "$DownloadedDriverPath") {$OSDDriver.OSDStatus = 'Downloaded'}

                    $ExpandedDriverPath = (Join-Path $SetOSDDriversPathExpand (Join-Path $OSDGroup $DriverName))
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
                $OSDDriverWmiQ = @()
                Get-ChildItem $PackagePath *.clixml | foreach {$OSDDriverWmiQ += Import-Clixml $_.FullName}
                if ($OSDDriverWmiQ) {
                    if ($OSDGroup -match 'DellModel') {
                        $OSDDriverWmiQ | Get-OSDDriverWmiQ -OSDGroup DellModel -Result Model | Out-File "$PackagePath\WmiQuery.txt" -Force
                        $OSDDriverWmiQ | Get-OSDDriverWmiQ -OSDGroup DellModel -Result SystemId | Out-File "$PackagePath\WmiQuerySystemId.txt" -Force
                    }
                    if ($OSDGroup -match 'HpModel') {
                        $OSDDriverWmiQ | Get-OSDDriverWmiQ -OSDGroup HpModel -Result Model | Out-File "$PackagePath\WmiQuery.txt" -Force
                        $OSDDriverWmiQ | Get-OSDDriverWmiQ -OSDGroup HpModel -Result SystemId | Out-File "$PackagePath\WmiQuerySystemId.txt" -Force
                    }
                }
                #===================================================================================================
                #   Execute
                #===================================================================================================
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

                    $DownloadedDriverGroup = (Join-Path $SetOSDDriversPathDownload $OSDGroup)
                    $DownloadedDriverPath =  (Join-Path $DownloadedDriverGroup $DownloadFile)
                    $ExpandedDriverPath = (Join-Path $SetOSDDriversPathExpand (Join-Path $OSDGroup $DriverName))
                    #$PackagedDriverPath = (Join-Path $SetOSDDriversPathPackages (Join-Path $OSDGroup $OSDCabFile))

                    if (-not(Test-Path "$DownloadedDriverGroup")) {New-Item $DownloadedDriverGroup -Directory -Force | Out-Null}

                    Write-Verbose "DownloadedDriverPath: $DownloadedDriverPath"
                    Write-Verbose "ExpandedDriverPath: $ExpandedDriverPath"
                    #Write-Verbose "PackagedDriverPath: $PackagedDriverPath"

                    Write-Host "$DriverName" -ForegroundColor Cyan
                    #===================================================================================================
                    #   Driver Download
                    #===================================================================================================
                    Write-Host "Driver Download: $DownloadedDriverPath " -ForegroundColor Gray -NoNewline
                    if (Test-Path "$DownloadedDriverPath") {
                        Write-Host 'Complete!' -ForegroundColor Cyan
                    } else {
                        Write-Host "Downloading ..." -ForegroundColor Cyan
                        Write-Host "$DriverUrl" -ForegroundColor Gray
                        Start-BitsTransfer -Source $DriverUrl -Destination "$DownloadedDriverPath"
                    }
                    #===================================================================================================
                    #   Validate Driver Download
                    #===================================================================================================
                    if (-not (Test-Path "$DownloadedDriverPath")) {
                        Write-Warning "Could not download Driver from $DriverUrl"
                        Write-Warning "Setting RemoveSuperseded to False"
                        $RemoveSuperseded = $false
                        Continue
                    } else {
                        $OSDDriver | ConvertTo-Json | Out-File -FilePath "$DownloadedDriverGroup\$((Get-Item $DownloadedDriverPath).BaseName).drvpack" -Force
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
                                #Start-Process -FilePath "$DownloadedDriverPath" -ArgumentList $HPSoftPaqSilentSwitches -Verb RunAs -Wait
                                Start-Process -FilePath "$DownloadedDriverPath" -ArgumentList "/s /e /f `"$ExpandedDriverPath`"" -Verb RunAs -Wait
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
                    $OSDDriver | ConvertTo-Json | Out-File -FilePath "$ExpandedDriverPath\$($OSDDriver.DriverName).drvpack" -Force
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
                        if ($SaveAudio -eq $false) {$SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Audio\\'}}
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
                        if ($SaveAudio -eq $false) {$SourceContent = $SourceContent | Where-Object {"$($_.Parent.Parent)" -ne 'audio'}}
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
                #===================================================================================================
                #   Get ALL DRVPACK Files
                #===================================================================================================
                $AllDrvPack = Get-ChildItem $PackagePath *.drvpack | Select-Object FullName
                #===================================================================================================
                #   Remove Superseded MultiPacks
                #===================================================================================================
                $AllDriverPacks = @()
                $AllDriverPacks = foreach ($Item in $AllDrvPack) {
                    Get-Content $Item.FullName | ConvertFrom-Json
                }
                $AllDriverPacks = $AllDriverPacks | Sort-Object DriverName -Descending

                $CurrentDriverPacks = @()
                $CurrentDriverPacks = $AllDriverPacks | Sort-Object DriverGrouping -Descending -Unique

                foreach ($Item in $AllDriverPacks | Where-Object {$_.DriverName -NotIn $CurrentDriverPacks.DriverName}) {
                    Write-Warning "Superseded Driver Pack: $($Item.DriverName)"
                    if ($RemoveSuperseded.IsPresent) {
                        if (Test-Path "$PackagePath\$($Item.DriverName).*pack") {
                            Remove-Item -Path "$PackagePath\$($Item.DriverName).*pack" -Force | Out-Null
                        }
                    }
                }
                #===================================================================================================
                #   Get ALL MULTIPACK Files
                #===================================================================================================
                $AllMultiPacks = Get-ChildItem $PackagePath *.multipack | Select-Object FullName
                $CurrentMPCabs = @()
                foreach ($Item in $AllMultiPacks) {
                    $CurrentMPCabs += Get-Content $Item.FullName | ConvertFrom-Json -ErrorAction SilentlyContinue
                }
                $CurrentMPCabs = $CurrentMPCabs | Sort-Object -Unique
                $CurrentMPCabsFN = @()
                foreach ($Item in $CurrentMPCabs) {
                    $CurrentMPCabsFN += "$PackagePath\$Item"
                }
                #===================================================================================================
                #   Get ALL $PackagePath CAB Files
                #===================================================================================================
                $AllMPCabs = Get-ChildItem $PackagePath *.cab -Recurse | Select-Object FullName
                #===================================================================================================
                #   Remove Superseded CAB Files
                #===================================================================================================
                foreach ($Item in $AllMPCabs | Where-Object {$_.FullName -NotIn $CurrentMPCabsFN}) {
                    Write-Warning "Superseded Driver CAB: $($Item.FullName)"
                    if ($RemoveSuperseded.IsPresent) {
                        if (Test-Path "$($Item.FullName)") {
                            $RemoveCab = Get-Item $Item.FullName | Select-Object -Property *
                            Remove-Item $RemoveCab.FullName -Force -ErrorAction SilentlyContinue | Out-Null
                        }
                        if (Test-Path "$($RemoveCab.Directory)\$($RemoveCab.BaseName).ddf") {
                            Write-Warning "Superseded Driver Directive: $($RemoveCab.Directory)\$($RemoveCab.BaseName).ddf"
                            Remove-Item -Path "$($RemoveCab.Directory)\$($RemoveCab.BaseName).ddf" -Force -ErrorAction SilentlyContinue | Out-Null
                        }
                    }
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