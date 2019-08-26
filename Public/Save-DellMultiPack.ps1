<#
.SYNOPSIS
Downloads Dell Model Packs and creates a MultiPack

.DESCRIPTION
Downloads Dell Model Packs to $WorkspacePath\Download\DellModel
Creates a Dell MultiPack in $WorkspacePath\Packages\DellMultiPack
Requires BITS for downloading the Downloads
Requires Internet access

.LINK
https://osddrivers.osdeploy.com/module/functions/save-dellmultipack

.PARAMETER WorkspacePath
Directory to the OSDDrivers Workspace.  This contains the Download, Expand, and Package subdirectories

.PARAMETER AppendName
Appends the string to the DellMultiPack Name

.PARAMETER Generation
Generation of the Dell Model

.PARAMETER OsArch
Operating System Architecture of the Model Pack to be extracted

.PARAMETER OsVersion
Operating System Version of the Model Pack to be extracted

.PARAMETER SystemFamily
Filters compatibility to Latitude, Optiplex, or Precision.  Venue, Vostro, and XPS are not included

.PARAMETER Expand
Expands the downloaded Dell Model Packs

.PARAMETER RemoveAudio
Removes drivers in the Audio Directory from being added to the CAB or MultiPack

.PARAMETER RemoveAmdVideo
Removes AMD Video Drivers from being added to the CAB or MultiPack

.PARAMETER RemoveIntelVideo
Removes Intel Video Drivers from being added to a MultiPack

.PARAMETER RemoveNvidiaVideo
Removes Nvidia Video Drivers from being added to the CAB or MultiPack
#>
function Save-DellMultiPack {
    [CmdletBinding()]
    Param (
        #====================================================================
        #   InputObject
        #====================================================================
        [Parameter(ValueFromPipeline = $true)]
        [Object[]]$InputObject,
        #====================================================================
        #   Basic
        #====================================================================
        [Parameter(Mandatory)]
        [string]$WorkspacePath,

        #[Parameter(Mandatory)]
        [string]$AppendName = 'None',
        #====================================================================
        #   Filters
        #====================================================================
        [ValidateSet ('X10','X9','X8','X7','X6','X5','X4','X3','X2','X1')]
        [string]$Generation,

        [ValidateSet ('x64','x86')]
        [string]$OsArch = 'x64',

        [ValidateSet ('10.0','6.3','6.1')]
        [string]$OsVersion = '10.0',

        [ValidateSet ('Latitude','Optiplex','Precision')]
        [string]$SystemFamily,
        #====================================================================
        #   Options
        #====================================================================
        [switch]$RemoveAmdVideo = $false,
        [switch]$RemoveAudio = $false,
        [switch]$RemoveIntelVideo = $false,
        [switch]$RemoveNvidiaVideo = $false
        #[switch]$RemoveX86 = $false
        #[switch]$SplitGeneration,
        #[Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        #[ValidateSet('DellModel','DellFamily')]
        #[string]$OSDGroup,
        #[Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        #[ValidateSet ('x64','x86')]
        #[string]$OsArch,
        #[switch]$SkipGridView
        #====================================================================
    )

    Begin {
        #===================================================================================================
        #   CustomName
        #===================================================================================================
        if ($AppendName -eq 'None') {
            $CustomName = "DellMultiPack $OsVersion $OsArch"
        } else {
            $CustomName = "DellMultiPack $OsVersion $OsArch $AppendName"
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
        $OSDGroup = 'DellModel'
        if ($RemoveAudio -eq $true) {Write-Warning "Audio Drivers will be removed from resulting packages"}
        if ($RemoveAmdVideo -eq $true) {Write-Warning "AMD Video Drivers will be removed from resulting packages"}
        if ($RemoveIntelVideo -eq $true) {Write-Warning "Intel Video Drivers will be removed from resulting packages"}
        if ($RemoveNvidiaVideo -eq $true) {Write-Warning "Nvidia Video Drivers will be removed from resulting packages"}
        Publish-OSDDriverScripts -PublishPath (Join-Path $WorkspaceDownload 'DellModel')
        #===================================================================================================
        #   Get-OSDDrivers
        #===================================================================================================
        $OSDDrivers = @()
        if ($InputObject) {
            $SkipGridView = $true
            $OSDDrivers = $InputObject
        } else {
            $OSDDrivers = Get-DellModelPack -DownloadPath (Join-Path $WorkspaceDownload 'DellModel')
            $OSDDrivers | Export-Clixml "$(Join-Path $WorkspaceDownload $(Join-Path 'DellModel' 'DellModelPack.clixml'))"
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
            $OSDDrivers = $OSDDrivers | Out-GridView -PassThru -Title "Select Drivers to MultiPack and press OK"
        }
        #===================================================================================================
        #   Export MultiPack Object
        #===================================================================================================
        $OSDDrivers | Export-Clixml "$PackagePath\$CustomName $(Get-Date -Format yyMMddHHmmssfff).clixml" -Force
        $WmiQueryDellModel = @()
        Get-ChildItem $PackagePath *.clixml | foreach {$WmiQueryDellModel += Import-Clixml $_.FullName}
        if ($WmiQueryDellModel) {
            $WmiQueryDellModel | Show-WmiQueryDellModel | Out-File "$PackagePath\WmiQuery.txt" -Force
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
                    }
                } else {
                    Continue
                }
                #===================================================================================================
                #   Verify Driver Expand
                #===================================================================================================
                if (Test-Path "$ExpandedDriverPath") {
                    $NormalizeContent = Get-ChildItem "$ExpandedDriverPath\*\*\*\*\*" -Directory | Where-Object {($_.Name -match '_A') -and ($_.Name -notmatch '_A00-00')}
                    foreach ($FunkyNameDriver in $NormalizeContent) {
                        $NewBaseName = ($FunkyNameDriver.Name -split '_')[0]
                        Write-Verbose "Renaming '$($FunkyNameDriver.FullName)' to '$($NewBaseName)_A00-00'" -Verbose
                        Rename-Item "$($FunkyNameDriver.FullName)" -NewName "$($NewBaseName)_A00-00" -Force | Out-Null
                    }
                } else {
                    Write-Warning "Driver Expand: Could not expand Driver to $ExpandedDriverPath ... Exiting"
                    Continue
                }
                $OSDDriver.OSDStatus = 'Expanded'
                #===================================================================================================
                #   OSDDriver Objects
                #===================================================================================================
                #$PackagedDriverGroup = Get-PathOSDD -Path (Join-Path $WorkspaceProject (Join-Path 'DellMultiPack' $CustomName = 'DellMultiPack'))

                <# if ($SplitGeneration.IsPresent) {
                    $WmiQueryDellModel = @()
                    Get-ChildItem $PackagedDriverGroup *.clixml | foreach {$WmiQueryDellModel += Import-Clixml $_.FullName}
                    $WmiQueryDellModel = $WmiQueryDellModel | Where-Object {$_.Generation -match $OSDDriver.Generation}

                    $PackagedDriverGroup = Get-PathOSDD -Path (Join-Path $WorkspaceProject (Join-Path 'DellMultiPack' (Join-Path $CustomName = 'DellMultiPack' "Dell $($OSDDriver.Generation)")))

                    if ($WmiQueryDellModel) {
                        $WmiQueryDellModel | Show-WmiQueryDellModel | Out-File "$PackagedDriverGroup\WmiQuery.txt" -Force
                    }
                } #>
                $OSDDriver | ConvertTo-Json | Out-File -FilePath "$PackagePath\$($OSDDriver.DriverName).drvpack" -Force
                #===================================================================================================
                #   MultiPack
                #===================================================================================================
                $MultiPackFiles = @()
                #===================================================================================================
                #   Get SourceContent
                #===================================================================================================
                $SourceContent = @()
                if ($OsArch -eq 'x86') {
                    $SourceContent = Get-ChildItem "$ExpandedDriverPath\*\*\x86\*\*" -Directory | Select-Object -Property *
                } else {
                    $SourceContent = Get-ChildItem "$ExpandedDriverPath\*\*\x64\*\*" -Directory | Select-Object -Property *
                }
                #===================================================================================================
                #   Filter SourceContent
                #===================================================================================================
                if ($RemoveAudio.IsPresent) {$SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Audio\\'}}
                if ($RemoveVideo.IsPresent) {$SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Video\\'}}
                foreach ($DriverDir in $SourceContent) {
                    if ($RemoveIntelVideo.IsPresent) {
                        if (($DriverDir.FullName -match '\\Video\\') -and (Get-ChildItem "$($DriverDir.FullName)" igfx*.* -File -Recurse)) {
                            Write-Host "IntelDisplay: $($DriverDir.FullName)" -ForegroundColor Gray
                            Continue
                        }
                    }
                    if ($RemoveAmdVideo.IsPresent) {
                        if (($DriverDir.FullName -match '\\Video\\') -and (Get-ChildItem "$($DriverDir.FullName)" ati*.dl* -File -Recurse)) {
                            Write-Host "AMDDisplay: $($DriverDir.FullName)" -ForegroundColor Gray
                            Continue
                        }
                    }
                    if ($RemoveNvidiaVideo.IsPresent) {
                        if (($DriverDir.FullName -match '\\Video\\') -and (Get-ChildItem "$($DriverDir.FullName)" nv*.dl* -File -Recurse)) {
                            Write-Host "NvidiaDisplay: $($DriverDir.FullName)" -ForegroundColor Gray
                            Continue
                        }
                    }
                    $MultiPackFiles += $DriverDir
                    New-CabFileDellMultiPack "$($DriverDir.FullName)" "$PackagePath\$(($DriverDir.Parent).parent)\$($DriverDir.Parent)" $RemoveIntelVideo
                }
                foreach ($MultiPackFile in $MultiPackFiles) {
                    $MultiPackFile.Name = "$(($MultiPackFile.Parent).Parent)\$($MultiPackFile.Parent)\$($MultiPackFile.Name).cab"
                }
                $MultiPackFiles = $MultiPackFiles | Select-Object -ExpandProperty Name
                $MultiPackFiles | ConvertTo-Json | Out-File -FilePath "$PackagePath\$($DriverName).multipack" -Force
                #===================================================================================================
                #   Publish-OSDDriverScripts
                #===================================================================================================
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