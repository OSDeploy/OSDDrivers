<#
.SYNOPSIS
Downloads Dell or Hp Model Packs and creates a MultiPack

.DESCRIPTION
Downloads Dell or Hp Model Packs and creates a MultiPack
Requires BITS for downloading the Downloads
Requires Internet access

.LINK
https://osddrivers.osdeploy.com/module/functions/save-osddrivermultipack
#>
function Save-OSDDriversMultiPack {
    [CmdletBinding()]
    Param (
        #Manufacturer of the Computer Model
        [Parameter(Mandatory)]
        [ValidateSet ('Dell','HP')]
        [string]$Make,

        #Appends the string to the MultiPack Name
        [string]$AppendName = 'None',

        #Generation of the Computer Model
        #Hp G0 - G6
        #Dell X1 - X11
        [ValidateSet ('G0','G1','G2','G3','G4','G5','G6','G7','G8','X1','X2','X3','X4','X5','X6','X7','X8','X9','X10','X11','X12','X13')]
        [string]$Generation,

        #Driver Pack supported Operating System Architecture
        [ValidateSet ('x64','x86')]
        [string]$OsArch = 'x64',

        #Driver Pack supported Operating System Version
        [ValidateSet ('10.0','6.3','6.1')]
        [string]$OsVersion = '10.0',

        #Doesn't remove the Audio Drivers from the MultiPack
        [switch]$SaveAudio = $false,

        #Doesn't remove the AMD Video Drivers from the DMultiPack
        [switch]$SaveAmdVideo = $false,
        
        #Doesn't remove the Intel Video Drivers from the MultiPack
        [switch]$SaveIntelVideo = $false,
        
        #Doesn't remove the Nvidia Video Drivers from the MultiPack
        [switch]$SaveNvidiaVideo = $false,

        #InputObject
        [Parameter(ValueFromPipeline = $true)]
        [Object[]]$InputObject
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
        #===================================================================================================
    }

    Process {
        Write-Verbose '========================================================================================' -Verbose
        Write-Verbose $MyInvocation.MyCommand.Name -Verbose
        #===================================================================================================
        #   Defaults
        #===================================================================================================
        $Expand = $true

        if ($SaveAudio -eq $false) {Write-Warning "Audio Drivers will be removed from resulting Packages"}
        if ($SaveAmdVideo -eq $false) {Write-Warning "AMD Video Drivers will be removed from resulting Packages"}
        if ($SaveIntelVideo -eq $false) {Write-Warning "Intel Video Drivers will be removed from resulting Packages"}
        if ($SaveNvidiaVideo -eq $false) {Write-Warning "Nvidia Video Drivers will be removed from resulting Packages"}

        if ($Make -eq 'Dell') {
            $OSDGroup = 'DellModel'
            $MultiPack = 'DellMultiPack'
        } elseif ($Make -eq 'HP') {
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
        #   Publish Paths
        #===================================================================================================
        $PackagePath = Get-PathOSDD -Path (Join-Path $SetOSDDriversPathPackages "$CustomName")
        Write-Verbose "MultiPack Path: $PackagePath" -Verbose
        Publish-OSDDriverScripts -PublishPath $PackagePath
        Publish-OSDDriverScripts -PublishPath (Join-Path $SetOSDDriversPathDownload $OSDGroup)
        #===================================================================================================
        #   Get-OSDDrivers
        #===================================================================================================
        $OSDDrivers = @()
        if ($InputObject) {
            $SkipGridView = $true
            $OSDDrivers = $InputObject
        } else {
            if ($OSDGroup -eq 'DellModel') {
                $OSDDrivers = Get-OSDDriver DellModel
                $OSDDrivers | Export-Clixml "$(Join-Path $global:SetOSDDriversPathDownload $(Join-Path 'DellModel' 'DellModelPack.clixml'))"
            }
            if ($OSDGroup -eq 'HpModel') {
                $OSDDrivers = Get-OSDDriver HpModel
                $OSDDrivers | Export-Clixml "$(Join-Path $global:SetOSDDriversPathDownload $(Join-Path 'HpModel' 'HpModelPack.clixml'))"
            }
        }
        #===================================================================================================
        #   Set-OSDDrivers
        #===================================================================================================
        foreach ($item in $OSDDrivers) {
            $DriverName = $item.DriverName
            $OSDCabFile = "$($DriverName).cab"
            $DownloadFile = $item.DownloadFile
            $OSDGroup = $item.OSDGroup
            $OSDType = $item.OSDType

            $DownloadedDriverGroup  = (Join-Path $global:SetOSDDriversPathDownload $OSDGroup)
        }
        #===================================================================================================
        #   Get-Existing Downloads
        #===================================================================================================
        $DrvPacks = Get-ChildItem $DownloadedDriverGroup *.drvpack | Select-Object FullName
        $DriverPacks = @()
        $DriverPacks = foreach ($item in $DrvPacks) {
            Get-Content $item.FullName | ConvertFrom-Json
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

            $DownloadedDriverGroup  = (Join-Path $global:SetOSDDriversPathDownload $OSDGroup)
            Write-Verbose "DownloadedDriverGroup: $DownloadedDriverGroup"

            if ($OSDDriver.DriverGrouping -in $DriverPacks.DriverGrouping) {
                $OSDDriver.OSDStatus = 'Update'
            }

            $DownloadedDriverPath = (Join-Path $global:SetOSDDriversPathDownload (Join-Path $OSDGroup $DownloadFile))
            if (Test-Path "$DownloadedDriverPath") {$OSDDriver.OSDStatus = 'Downloaded'}

            $ExpandedDriverPath = (Join-Path $global:SetOSDDriversPathExpand (Join-Path $OSDGroup $DriverName))
            if (Test-Path "$ExpandedDriverPath") {$OSDDriver.OSDStatus = 'Expanded'}
        }
        #$DriverPacks = $DriverPacks | Sort-Object DriverGrouping -Descending -Unique
        #===================================================================================================
        #   Filters
        #===================================================================================================
        if ($OsArch) {$OSDDrivers = $OSDDrivers | Where-Object {$_.OsArch -match "$OsArch"}}
        if ($OsVersion) {$OSDDrivers = $OSDDrivers | Where-Object {$_.OsVersion -match "$OsVersion"}}
        if ($Generation) {$OSDDrivers = $OSDDrivers | Where-Object {$_.Generation -eq "$Generation"}}
        #===================================================================================================
        #   GridView
        #===================================================================================================
        $OSDDrivers = $OSDDrivers | Sort-Object LastUpdate -Descending
        if ($SkipGridView) {
            #Write-Warning "SkipGridView: Skipping Out-GridView"
        } else {
            $OSDDrivers = $OSDDrivers | Out-GridView -PassThru -Title "Select Driver Packs to add to a MultiPack and press OK"
        }
        #===================================================================================================
        #   Export MultiPack Object
        #===================================================================================================
        $OSDDrivers | Export-Clixml "$PackagePath\$CustomName $(Get-Date -Format yyMMddHHmmssfff).clixml" -Force
        $OSDDriverWmiQ = @()
        Get-ChildItem $PackagePath *.clixml | foreach {$OSDDriverWmiQ += Import-Clixml $_.FullName}
        if ($OSDDriverWmiQ) {
            $OSDDriverWmiQ | Get-OSDDriverWmiQ -OSDGroup HpModel -Result Model | Out-File "$PackagePath\WmiQuery.txt" -Force
            $OSDDriverWmiQ | Get-OSDDriverWmiQ -OSDGroup HpModel -Result SystemId | Out-File "$PackagePath\WmiQuerySystemId.txt" -Force
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
            Write-Verbose "DriverName: $DriverName" -Verbose

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
            #   OSDDriver Object
            #===================================================================================================
            $OSDDriver | Export-Clixml -Path "$ExpandedDriverPath\OSDDriver.clixml" -Force
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
    }

    End {
        #===================================================================================================
        #   Complete
        #===================================================================================================
        Write-Host "Complete!" -ForegroundColor Green
        #===================================================================================================
    }
}