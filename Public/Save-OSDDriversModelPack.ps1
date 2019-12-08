<#
.SYNOPSIS
Downloads Dell and HP Model Packs

.DESCRIPTION
Downloads Dell and HP Model Packs
Requires BITS for downloading the Downloads
Requires Internet access

.LINK
https://osddrivers.osdeploy.com/module/functions/save-osddrivermodelpack
#>
function Save-OSDDriverModelPack {
    [CmdletBinding()]
    Param (
        #Manufacturer of the Computer Model
        [Parameter(Mandatory)]
        [ValidateSet ('Dell','HP')]
        [string]$Make,
        
        #Generation of the Computer Model
        #Hp G0 - G6
        #Dell X1 - X10
        [ValidateSet ('G0','G1','G2','G3','G4','G5','G6','X1','X2','X3','X4','X5','X6','X7','X8','X9','X10')]
        [string]$Generation,

        #Driver Pack supported Operating System
        [ValidateSet ('10.0','6.3','6.1')]
        [string]$OsVersion = '10.0',
        
        #Expand the Driver Pack after Download
        [switch]$Expand,
        
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
        #   Display Paths
        #===================================================================================================
        Write-Verbose "Home: $global:GetOSDDriversHome" -Verbose
        Write-Verbose "Download: $global:SetOSDDriversPathDownload" -Verbose
        Write-Verbose "Expand: $global:SetOSDDriversPathExpand" -Verbose
        Write-Verbose "Packages: $global:SetOSDDriversPathPackages" -Verbose
        #===================================================================================================
    }

    Process {
        Write-Verbose '========================================================================================' -Verbose
        Write-Verbose $MyInvocation.MyCommand.Name -Verbose
        #===================================================================================================
        #   Defaults
        #===================================================================================================
        if ($RemoveAudio -eq $true) {Write-Warning "Audio Drivers will be removed from resulting packages"}
        if ($RemoveAmdVideo -eq $true) {Write-Warning "AMD Video Drivers will be removed from resulting packages"}
        if ($RemoveIntelVideo -eq $true) {Write-Warning "Intel Video Drivers will be removed from resulting packages"}
        if ($RemoveNvidiaVideo -eq $true) {Write-Warning "Nvidia Video Drivers will be removed from resulting packages"}
        Publish-OSDDriverScripts -PublishPath (Join-Path $global:SetOSDDriversPathDownload $OSDGroup)
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
            $OSDDrivers = $OSDDrivers | Out-GridView -PassThru -Title "Select Driver Packs to Download and press OK"
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

            $DownloadedDriverGroup = (Join-Path $global:SetOSDDriversPathDownload $OSDGroup)
            $DownloadedDriverPath =  (Join-Path $DownloadedDriverGroup $DownloadFile)
            $ExpandedDriverPath = (Join-Path $global:SetOSDDriversPathExpand (Join-Path $OSDGroup $DriverName))
            #$PackagedDriverPath = (Join-Path $global:SetOSDDriversPathPackages (Join-Path $OSDGroup $OSDCabFile))

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
            #$PackagedDriverGroup = Get-PathOSDD -Path (Join-Path $global:SetOSDDriversPathPackages $OSDGroup)
            $OSDDriver | Export-Clixml -Path "$ExpandedDriverPath\OSDDriver.clixml" -Force
            $OSDDriver | ConvertTo-Json | Out-File -FilePath "$ExpandedDriverPath\OSDDriver.drvpack" -Force
            Continue
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