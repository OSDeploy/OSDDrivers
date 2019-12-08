<#
.SYNOPSIS
Downloads Dell Model Packs

.DESCRIPTION
Downloads Dell Model Packs
Requires BITS Transfer and Interactive Login
Requires Internet access

.LINK
https://osddrivers.osdeploy.com/module/functions/save-osddriverdellmodel
#>
function Save-OSDDriverDellModel {
    [CmdletBinding()]
    Param (
        #====================================================================
        #   Mandatory
        #====================================================================
        #Directory of the OSDDrivers Workspace
        #Contains the Download, Expand, and Package subdirectories
        [Parameter(Mandatory)]
        [string]$WorkspacePath,
        #====================================================================
        #   Filters
        #====================================================================
        #Generation of the Driver Pack
        [ValidateSet ('X1','X2','X3','X4','X5','X6','X7','X8','X9','X10')]
        [string]$Generation,

        #Operating System Version of the Driver Pack
        [ValidateSet ('10.0','6.3','6.1')]
        [string]$OsVersion,
        #====================================================================
        #   Switches
        #====================================================================
        #Automatically downloads Driver Packs that have been Superseded
        #Does not remove Superseded Driver Packs
        [Alias('Auto')]
        [switch]$AutoUpdate,

        #Expands the downloaded Driver Packs
        [Alias('Expand')]
        [switch]$ExpandDriver
        #====================================================================
        #   InputObject
        #====================================================================
        #[Parameter(ValueFromPipeline = $true)]
        #[Object[]]$InputObject,
        #====================================================================
    )

    Begin {
        #===================================================================================================
        #   Defaults
        #===================================================================================================
        $global:OSDGroup = 'DellModel'
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
    }

    Process {
        #===================================================================================================
        #   Defaults
        #===================================================================================================
        if ($RemoveAudio -eq $true) {Write-Warning "Audio Drivers will be removed from resulting packages"}
        if ($RemoveAmdVideo -eq $true) {Write-Warning "AMD Video Drivers will be removed from resulting packages"}
        if ($RemoveIntelVideo -eq $true) {Write-Warning "Intel Video Drivers will be removed from resulting packages"}
        if ($RemoveNvidiaVideo -eq $true) {Write-Warning "Nvidia Video Drivers will be removed from resulting packages"}
        Publish-OSDDriverScripts -PublishPath (Join-Path $WorkspaceDownload $OSDGroup)
        #===================================================================================================
        #   Get-OSDDrivers
        #===================================================================================================
        $OSDDrivers = @()
        if ($InputObject) {
            $SkipGridView = $true
            $OSDDrivers = $InputObject
        } else {
            $OSDDrivers = Get-DellModelPack -DownloadPath (Join-Path $WorkspaceDownload $OSDGroup)
            $OSDDrivers | Export-Clixml "$(Join-Path $WorkspaceDownload $(Join-Path 'DellModel' 'DellModelPack.clixml'))"
        }
        #===================================================================================================
        #   Set-OSDDrivers
        #===================================================================================================
        foreach ($OSDDriver in $OSDDrivers) {
            $DriverName = $OSDDriver.DriverName
            $OSDCabFile = "$($DriverName).cab"
            $DownloadFile = $OSDDriver.DownloadFile
            $OSDGroup = $OSDDriver.OSDGroup
            $OSDType = $OSDDriver.OSDType

            $DownloadedDriverGroup  = (Join-Path $WorkspaceDownload $OSDGroup)
            Write-Verbose "DownloadedDriverGroup: $DownloadedDriverGroup"
        }
        #===================================================================================================
        #   Get-Existing Downloads
        #===================================================================================================
        $DownloadedDrvPacks = Get-ChildItem $DownloadedDriverGroup *.drvpack | Select-Object FullName
        $DownloadedDriverPacks = @()
        $DownloadedDriverPacks = foreach ($item in $DownloadedDrvPacks) {
            Get-Content $item.FullName | ConvertFrom-Json
        }
        #foreach ($item in $DownloadedDriverPacks) {
        #    $item.OSDStatus = 'Superseded'
        #}
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

            if ($OSDDriver.DriverGrouping -in $DownloadedDriverPacks.DriverGrouping) {
                $OSDDriver.OSDStatus = 'Update'
            }

            $DownloadedDriverPath = (Join-Path $WorkspaceDownload (Join-Path $OSDGroup $DownloadFile))
            if (Test-Path "$DownloadedDriverPath") {$OSDDriver.OSDStatus = 'Downloaded'}

            $ExpandedDriverPath = (Join-Path $WorkspaceExpand (Join-Path $OSDGroup $DriverName))
            if (Test-Path "$ExpandedDriverPath") {$OSDDriver.OSDStatus = 'Expanded'}
        }
        #$DownloadedDriverPacks = $DownloadedDriverPacks | Sort-Object DriverGrouping -Descending -Unique
        #===================================================================================================
        #   Filters
        #===================================================================================================
        if ($AutoUpdate.IsPresent) {$OSDDrivers = $OSDDrivers | Where-Object {$_.OSDStatus -eq 'Update'}}
        if ($OsVersion) {$OSDDrivers = $OSDDrivers | Where-Object {$_.OsVersion -match "$OsVersion"}}
        if ($Generation) {$OSDDrivers = $OSDDrivers | Where-Object {$_.Generation -eq "$Generation"}}
        #===================================================================================================
        #   GridView
        #===================================================================================================
        $OSDDrivers = $OSDDrivers | Sort-Object LastUpdate -Descending
        if (($SkipGridView) -or ($AutoUpdate.IsPresent)) {
            #Write-Warning "SkipGridView: Skipping Out-GridView"
        } else {
            $OSDDrivers = $OSDDrivers | Out-GridView -PassThru -Title "Select Driver Packs to Download and press OK"
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
                #$PackagedDriverGroup = Get-PathOSDD -Path (Join-Path $WorkspacePackages $OSDGroup)
                $OSDDriver | Export-Clixml -Path "$ExpandedDriverPath\OSDDriver.clixml" -Force
                $OSDDriver | ConvertTo-Json | Out-File -FilePath "$ExpandedDriverPath\OSDDriver.drvpack" -Force
                Continue
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