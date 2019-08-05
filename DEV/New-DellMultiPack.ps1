<#
.SYNOPSIS
Downloads DellFamily Driver Packs

.DESCRIPTION
Downloads DellFamily Driver Packs
Requires BITS for downloading the Downloads
Requires Internet access

.LINK
https://osddrivers.osdeploy.com/module/functions/new-dellmultipack

.PARAMETER WorkspacePath
Directory to the OSDDrivers Workspace.  This contains the Download, Expand, and Package subdirectories

.PARAMETER DriverFamily
Filters compatibility to Latitude, OptiPlex, or Precision.  Venue, Vostro, and XPS are not included
#>
function New-DellMultiPack {
    [CmdletBinding()]
    Param (
        #[Parameter(ValueFromPipeline = $true)]
        #[Object[]]$InputObject,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$MultiPackName,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$WorkspacePath,

        [ValidateSet ('Latitude','OptiPlex','Precision')]
        [string]$Family,

        [ValidateSet ('X10','X9','X8','X7','X6','X5','X4','X3')]
        [string]$Generation,

        [switch]$NoAudio,
        [switch]$NoVideoAMD,
        [switch]$NoVideoNvidia
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

        $WorkspaceExpand = Get-PathOSDD -Path (Join-Path $OSDWorkspace 'Expand')
        Write-Verbose "Workspace Expand: $WorkspaceExpand" -Verbose

        $WorkspacePackage = Get-PathOSDD -Path (Join-Path $OSDWorkspace 'Package')
        Write-Verbose "Workspace Package: $WorkspacePackage" -Verbose

        #$WorkspaceMultiPack = Get-PathOSDD -Path (Join-Path $OSDWorkspace 'MultiPack')
        #Write-Verbose "Workspace MultiPack: $WorkspaceMultiPack" -Verbose

        #$PubishPackage = Get-PathOSDD -Path (Join-Path $OSDWorkspace (Join-Path 'Publish' $Name))
        #Write-Verbose "Publish Package: $PubishPackage" -Verbose
        #===================================================================================================
    }

    Process {
        #===================================================================================================
        #   Defaults
        #===================================================================================================
        if ($MyInvocation.MyCommand.Name -eq 'Get-DownDellFamily') {
            $OSDGroup = 'DellFamily'
            $OSArch = 'x64'
            $OSVersion = '10.0'
            $NoAudio = $true
            $NoVideoAMD = $true
            $NoVideoNvidia = $true
        }
        if ($MyInvocation.MyCommand.Name -eq 'Get-DownDellModel') {
            $OSDGroup = 'DellModel'
            $OSArch = 'x64'
            $OSVersion = '10.0'
            #$NoAudio = $true
            #$NoVideoAMD = $true
            #$NoVideoNvidia = $true
        }
        if ($MyInvocation.MyCommand.Name -eq 'New-DellMultiPack') {
            $OSDGroup = 'DellModel'
            $OSArch = 'x64'
            $OSVersion = '10.0'
            $NoAudio = $true
            #$NoVideoAMD = $true
            #$NoVideoNvidia = $true
        }

        if ($MyInvocation.MyCommand.Name -eq 'New-DellMultiPack') {
            Write-Warning "Intel Video Drivers will be removed"
            if ($NoVideoAMD -eq $true) {Write-Warning "AMD Video Drivers will be removed from resulting packages"}
            if ($NoVideoNvidia -eq $true) {Write-Warning "Nvidia Video Drivers will be removed from resulting packages"}
            if ($NoAudio -eq $true) {Write-Warning "Audio Drivers will be removed from resulting packages"}
        }

        if ($MakeCab.IsPresent) {
            Write-Warning "Intel Video Drivers will be removed"
            if ($NoVideoAMD -eq $true) {Write-Warning "AMD Video Drivers will be removed from resulting packages"}
            if ($NoVideoNvidia -eq $true) {Write-Warning "Nvidia Video Drivers will be removed from resulting packages"}
            if ($NoAudio -eq $true) {Write-Warning "Audio Drivers will be removed from resulting packages"}
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
            if ($MyInvocation.MyCommand.Name -eq 'New-DellMultiPack') {$OSDDrivers = Get-DriverDellModel}
        }
        #===================================================================================================
        #   Set-OSDStatus
        #===================================================================================================
        foreach ($OSDDriver in $OSDDrivers) {
            Write-Verbose "==================================================================================================="
            $DriverName = $OSDDriver.DriverName
            $OSDCabFile = "$($DriverName).cab"
            $DownloadFile = $OSDDriver.DownloadFile
            $OSDGroup = $OSDDriver.OSDGroup
            $OSDType = $OSDDriver.OSDType
            $DownloadedDriverPath = (Join-Path $WorkspaceDownload (Join-Path $OSDGroup $DownloadFile))
            $ExpandedDriverPath = (Join-Path $WorkspaceExpand (Join-Path $OSDGroup $DriverName))
            $PackagedDriverPath = (Join-Path $WorkspacePackage (Join-Path $OSDGroup $OSDCabFile))

            if (Test-Path "$DownloadedDriverPath") {$OSDDriver.OSDStatus = 'Downloaded'}
            if (Test-Path "$ExpandedDriverPath") {$OSDDriver.OSDStatus = 'Expanded'}
            if ($MyInvocation.MyCommand.Name -eq 'Get-DownDellFamily' -or $MyInvocation.MyCommand.Name -eq 'Get-DownDellModel') {
                if (Test-Path "$PackagedDriverPath") {$OSDDriver.OSDStatus = 'Packaged'}
                Write-Verbose "OSDCabFile: $OSDCabFile"
                if (Test-Path "$ExpandedDriverPath\OSDDriver.drvpnp") {$OSDPnpFile = "$($DriverName).drvpnp"}
            }
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
        #   Generation
        #===================================================================================================
        if ($Generation) {$OSDDrivers = $OSDDrivers | Where-Object {$_.DriverChild -match "$Generation"}}
        #===================================================================================================
        #   DriverFamily
        #===================================================================================================
        if ($Family) {$OSDDrivers = $OSDDrivers | Where-Object {$_.DriverFamily -match "$Family"}}
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
            if ($MyInvocation.MyCommand.Name -eq 'New-DellMultiPack') {$OSDDrivers = $OSDDrivers | Out-GridView -PassThru -Title "Select Drivers to MultiPack and press OK"}
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

                $DownloadedDriverPath = (Join-Path $WorkspaceDownload (Join-Path $OSDGroup $DownloadFile))
                Write-Verbose "DownloadedDriverPath: $DownloadedDriverPath"

                $ExpandedDriverPath = (Join-Path $WorkspaceExpand (Join-Path $OSDGroup $DriverName))
                Write-Verbose "ExpandedDriverPath: $ExpandedDriverPath"

                $PackagedDriverPath = (Join-Path $WorkspacePackage (Join-Path $OSDGroup $OSDCabFile))
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
                    Continue
                }
                #===================================================================================================
                #   Driver Expand
                #===================================================================================================
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
                if ($MyInvocation.MyCommand.Name -eq 'New-DellMultiPack') {
                    $PackagedDriverGroup = Get-PathOSDD -Path (Join-Path $WorkspacePackage (Join-Path 'MultiPack' $MultiPackName))
                    $OSDDriver | ConvertTo-Json | Out-File -FilePath "$PackagedDriverGroup\$($OSDDriver.DriverName).multitask" -Force
                }
                else {
                    $PackagedDriverGroup = Get-PathOSDD -Path (Join-Path $WorkspacePackage $OSDGroup)
                    $OSDDriver | Export-Clixml -Path "$ExpandedDriverPath\OSDDriver.clixml" -Force
                    $OSDDriver | ConvertTo-Json | Out-File -FilePath "$ExpandedDriverPath\OSDDriver.drvpack" -Force
                }
                #===================================================================================================
                #   MakeCab
                #===================================================================================================


                #===================================================================================================
                #   Get SourceContent
                #===================================================================================================
                $SourceContent = @()
                $SourceContent = Get-ChildItem "$ExpandedDriverPath\*\*\x64\*\*" -Directory | Select-Object -Property *

                #===================================================================================================
                #   Filter SourceContent
                #===================================================================================================
                if ($NoAudio.IsPresent) {$SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Audio\\'}}
                if ($NoVideo.IsPresent) {$SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Video\\'}}
                foreach ($DriverDir in $SourceContent) {
                    
                    if (($DriverDir.FullName -match '\\Video\\') -and (Get-ChildItem "$($DriverDir.FullName)" igfxEM.exe -File -Recurse)) {
                        Write-Host "IntelDisplay: $($DriverDir.FullName)" -ForegroundColor Gray
                        Continue
                    }
                    if ($NoVideoAMD.IsPresent) {
                        if (($DriverDir.FullName -match '\\Video\\') -and (Get-ChildItem "$($DriverDir.FullName)" ati*.dll -File -Recurse)) {
                            Write-Host "AMDDisplay: $($DriverDir.FullName)" -ForegroundColor Gray
                            Continue
                        }
                    }
                    if ($NoVideoNvidia.IsPresent) {
                        if (($DriverDir.FullName -match '\\Video\\') -and (Get-ChildItem "$($DriverDir.FullName)" nvapi*.dl* -File -Recurse)) {
                            Write-Host "NvidiaDisplay: $($DriverDir.FullName)" -ForegroundColor Gray
                            Continue
                        }
                    }
                    if ($DriverDir.FullName -match '\\Video\\') {Write-Host "$($DriverDir.FullName)"}
                    New-DellMultiPackCab -ExpandedDriverPath "$($DriverDir.FullName)" -PublishPath "$PubishPackage\$($DriverDir.Parent)" -MakePnp
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
        Publish-OSDDriverScripts -PublishPath $PubishPackage
        Write-Host "Complete!" -ForegroundColor Green
        #===================================================================================================
    }
}