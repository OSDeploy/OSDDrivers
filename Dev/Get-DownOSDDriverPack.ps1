<#
.SYNOPSIS
Downloads Drivers

.DESCRIPTION
Downloads Drivers
Requires BITS for downloading the Downloads
Requires Internet access

.LINK
https://osddrivers.osdeploy.com/functions/get-osddriverpacks

.PARAMETER InputObject

.PARAMETER OSDGroup
Driver Type

.PARAMETER WorkspacePath
Directory to save the downloaded Drivers

.PARAMETER OSArch
Supported Architecture of the Driver

.PARAMETER OSName
Supported Operating Systems of the Driver
#>
function Get-DownOSDDriverPack {
    [CmdletBinding()]
    Param (
        #[Parameter(ValueFromPipeline = $true)]
        #[Object[]]$InputObject,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateSet('DellFamily')]
        [string]$OSDGroup,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$WorkspacePath,

        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$PublishPath,

        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateSet ('x64','x86')]
        [string]$OSArch,

        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateSet ('Win7','Win8.1','Win10')]
        [string]$OSName
    )

    Begin {
        #===================================================================================================
        #   Test-WorkspacePath
        #===================================================================================================
        Test-WorkspacePath $WorkspacePath $OSDGroup
        $WorkspaceDownload = "$WorkspacePath\$OSDGroup\Download"
        $WorkspaceExpand = "$WorkspacePath\$OSDGroup\Expand"
        $WorkspacePack = "$WorkspacePath\$OSDGroup\Pack"
        #===================================================================================================
        #   Test-PublishPath
        #===================================================================================================
        if ($PublishPath) {Test-PublishPath $PublishPath}
        #===================================================================================================
    }

    Process {
        #===================================================================================================
        #   Get-OSDDrivers
        #===================================================================================================
        $OSDDrivers = @()
        if ($InputObject) {
            $GridView = $false
            $OSDDrivers = $InputObject
        } else {
            $GridView = $true
            if ($OSDGroup -eq 'DellFamily') {$OSDDrivers = Get-DriverDellFamily}
            if ($OSDGroup -eq 'IntelDisplay') {$OSDDrivers = Get-DriverIntelDisplay}
            if ($OSDGroup -eq 'IntelWireless') {$OSDDrivers = Get-DriverIntelWireless}
        }
        #===================================================================================================
        #   Set-OSDStatus
        #===================================================================================================
        foreach ($OSDDriver in $OSDDrivers) {
            Write-Verbose "==================================================================================================="
            $DriverName = $OSDDriver.DriverName
            Write-Verbose "DriverName: $DriverName"

            $DownloadFile = $OSDDriver.DownloadFile
            Write-Verbose "DownloadFile: $DownloadFile"

            $OSDType = $OSDDriver.OSDType
            Write-Verbose "OSDType: $OSDType"

            $DownloadFullName = "$WorkspaceDownload\$DownloadFile"
            Write-Verbose "DownloadFullName: $DownloadFullName"
            if (Test-Path "$DownloadFullName") {$OSDDriver.OSDStatus = 'Downloaded'}

            $ExpandFullName = "$WorkspaceExpand\$DriverName"
            Write-Verbose "ExpandFullName: $ExpandFullName"
            if (Test-Path "$ExpandFullName") {$OSDDriver.OSDStatus = 'Expanded'}

            if ($OSDType -eq 'Driver') {
                $OSDDriver.OSDPackageFile = "$($DriverName).zip"
                $OSDPackageFile = $OSDDriver.OSDPackageFile
                $PackFullName = "$WorkspacePack\$OSDPackageFile"
                if (Test-Path "$PackFullName") {$OSDDriver.OSDStatus = 'Packed'}
                if ($PublishPath -and (Test-Path "$PublishPath\$($DriverName).zip")) {$OSDDriver.OSDStatus = 'Published'}
            } else {
                $OSDDriver.OSDPackageFile = "$($DriverName).cab"
                $OSDPackageFile = $OSDDriver.OSDPackageFile
                $PackFullName = "$WorkspacePack\$OSDPackageFile"
                if (Test-Path "$PackFullName") {$OSDDriver.OSDStatus = 'Packed'}
                if ($PublishPath -and (Test-Path "$PublishPath\$($DriverName).cab")) {$OSDDriver.OSDStatus = 'Published'}
            }
            Write-Verbose "OSDPackageFile: $OSDPackageFile"
            Write-Verbose "PackFullName: $PackFullName"

            if (Test-Path "$ExpandFullName\OSDDriver.cabpnp") {$OSDDriver.OSDPnpFile = "$($DriverName).cabpnp"}
        }
        #===================================================================================================
        #   OSArch
        #===================================================================================================
        if ($OSArch) {$OSDDrivers = $OSDDrivers | Where-Object {$_.OSArchMatch -match "$OSArch"}}
        #===================================================================================================
        #   OSName
        #===================================================================================================
        if ($OSName) {$OSDDrivers = $OSDDrivers | Where-Object {$_.OSNameMatch -match "$OSName"}}
        #===================================================================================================
        #   GridView
        #===================================================================================================
        $OSDDrivers = $OSDDrivers | Sort-Object LastUpdate -Descending
        if ($GridView) {$OSDDrivers = $OSDDrivers | Out-GridView -PassThru -Title "Select Drivers to Download and press OK"}
        #===================================================================================================
        #   Download
        #===================================================================================================
        if ($WorkspacePath) {
            Write-Verbose "==================================================================================================="
            #$OSDDrivers = $OSDDrivers | Where-Object {$_.OSDStatus -ne 'Downloaded'}

            foreach ($OSDDriver in $OSDDrivers) {
                $OSDType = $OSDDriver.OSDType
                Write-Verbose "OSDType: $OSDType"

                $DriverUrl = $OSDDriver.DriverUrl
                Write-Verbose "DriverUrl: $DriverUrl"

                $DriverName = $OSDDriver.DriverName
                Write-Verbose "DriverName: $DriverName"

                $FileType = $OSDDriver.FileType
                Write-Verbose "FileType: $FileType"

                $DownloadFile = $OSDDriver.DownloadFile
                Write-Verbose "DownloadFile: $DownloadFile"

                $DownloadFullName = "$WorkspaceDownload\$DownloadFile"
                Write-Verbose "DownloadFullName: $DownloadFullName"

                $ExpandFullName = "$WorkspaceExpand\$DriverName"
                Write-Verbose "ExpandFullName: $ExpandFullName"

                if ($OSDType -eq 'Driver') {
                    $OSDPackageFile = $OSDDriver.OSDPackageFile
                    $PackFullName = "$WorkspacePack\$OSDPackageFile"
                } else {
                    $OSDPackageFile = $OSDDriver.OSDPackageFile
                    $PackFullName = "$WorkspacePack\$OSDPackageFile"
                }
                Write-Verbose "OSDPackageFile: $OSDPackageFile"
                Write-Verbose "PackFullName: $PackFullName"

                Write-Host "$DriverName" -ForegroundColor Green
                #===================================================================================================
                #   Driver Download
                #===================================================================================================
                Write-Host "Driver Download: $DownloadFullName " -ForegroundColor Gray -NoNewline

                if (Test-Path "$DownloadFullName") {
                    Write-Host 'Complete!' -ForegroundColor Cyan
                } else {
                    Write-Host "Downloading ..." -ForegroundColor Cyan
                    Write-Host "$DriverUrl" -ForegroundColor Gray
                    Start-BitsTransfer -Source $DriverUrl -Destination "$DownloadFullName" -ErrorAction Stop
                }
                #===================================================================================================
                #   Validate Driver Download
                #===================================================================================================
                if (-not (Test-Path "$DownloadFullName")) {
                    Write-Warning "Driver Download: Could not download Driver to $DownloadFullName ... Exiting"
                    Break
                }
                #===================================================================================================
                #   Driver Expand
                #===================================================================================================
                Write-Host "Driver Expand: $ExpandFullName " -ForegroundColor Gray -NoNewline
                if (Test-Path "$ExpandFullName") {
                    Write-Host 'Complete!' -ForegroundColor Cyan
                } else {
                    Write-Host 'Expanding ...' -ForegroundColor Cyan
                    if ($FileType -match 'zip') {
                        Expand-Archive -Path "$DownloadFullName" -DestinationPath "$ExpandFullName" -Force -ErrorAction Stop
                    }
                    if ($FileType -match 'cab') {
                        if (-not (Test-Path "$ExpandFullName")) {
                            New-Item "$ExpandFullName" -ItemType Directory -Force -ErrorAction Stop | Out-Null
                        }
                        Expand -R "$DownloadFullName" -F:* "$ExpandFullName" | Out-Null
                    }
                }
                #===================================================================================================
                #   Verify Driver Expand
                #===================================================================================================
                if (-not (Test-Path "$ExpandFullName")) {
                    Write-Warning "Driver Expand: Could not expand Driver to $ExpandFullName ... Exiting"
                    Break
                }
                $OSDDriver.OSDStatus = 'Expanded'
                #===================================================================================================
                #   Generate Source Content
                #===================================================================================================
                if ($OSDGroup -eq 'DellFamily') {
                    Write-Host "Generating Content Directives: $ExpandFullName\OSDDriver-Content.clixml" -ForegroundColor Gray
                    $SourceContent = Get-ChildItem -Recurse $ExpandFullName | Where-Object { -Not($_.PsIsContainer)}
                    $SourceContent | Select-Object -ExpandProperty Fullname | Export-Clixml "$ExpandFullName\OSDDriver-Content.clixml" -Force

                    $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Audio\\'} #Remove Audio
                    $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Video\\'} #Remove Video
                    $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch 'release.dat'}
                    $SourceContent | Select-Object -ExpandProperty Fullname | Export-Clixml "$ExpandFullName\OSDDriver-ContentBasic.clixml" -Force

                    $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*\win10\*\*\*\Windows7*"}
                    $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*\win10\*\*\*\Windows8*"}
                    $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*\win10\*\*\*\Windows9*"}
                    $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*\win10\*\*\*\Windows10-x86*"}

                    $SupportedSystems = $null
                    $SupportedSystems = ($SourceContent | Where-Object {$_.FullName -match 'SupportedSystems.txt'}).Directory.FullName
                    if ($SupportedSystems) {
                        $ExcludeDir = @()
                        foreach ($item in $SupportedSystems) {
                            $DriverBundles = @()
                            $DriverBundles = Get-ChildItem "$item\*\*" -Directory | Select-Object -Property FullName
                        
                            foreach ($DriverDir in $DriverBundles) {
                                Write-Host "$($DriverDir.FullName)" -ForegroundColor DarkGray
                                $ExcludeFiles = @()
                                $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'BraswellSystem.inf'
                                $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'e1*.inf'
                                $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'iaStorAC.inf'
                                $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'ibt*.inf'
                                $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'iWiGiG.inf'
                                $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'tbt*.inf'
                                $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'Netwtw*.inf'
                                if ($ExcludeFiles) {
                                    $ExcludeDir += $DriverDir.FullName
                                }
                            }
                        }
                        foreach ($item in $ExcludeDir) {
                            $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*$($item)*"}
                        }
                    }
                    $SourceContent | Select-Object -ExpandProperty Fullname | Export-Clixml "$ExpandFullName\OSDDriver-ContentOSD.clixml" -Force
                }
                #===================================================================================================
                #   Save-OSDDriverPnp
                #===================================================================================================
                $OSDPnpClass = $OSDDriver.OSDPnpClass
                $OSDPnpFile = "$($DriverName).cabpnp"
                #$OSDPnpFileFullName = "$WorkspacePath\$($DriverName).cabpnp"

                if ($OSDGroup -eq 'IntelDisplay') {
                    Write-Host "Save-OSDDriverPnp: Generating OSDDriverPNP with OSDPnpClass $OSDPnpClass ..." -ForegroundColor Gray
                    Save-OSDDriverPnp -DriverPath "$ExpandFullName" -OSDPnpClass $OSDPnpClass
<#                     $OSDDriverPnp = @()
                    $OSDDriverPnp = Get-OSDDriverPnp -DriverPath "$ExpandFullName" | Where-Object {$_.ClassName -eq 'Display'} | Sort-Object HardwareID -Unique | Select-Object -Property HardwareID, HardwareDescription
                    $OSDDriver.HardwareID = $($OSDDriverPnp) #>
                }
                if (Test-Path "$ExpandFullName\OSDDriver.cabpnp") {$OSDDriver.OSDPnpFile = "$OSDPnpFile"}
                #===================================================================================================
                #   ExpandFullName OSDDriver Objects
                #===================================================================================================
                $OSDDriver | Export-Clixml -Path "$ExpandFullName\OSDDriver.clixml" -Force
                $OSDDriver | ConvertTo-Json | Out-File -FilePath "$ExpandFullName\OSDDriver.cabtask" -Force
                #===================================================================================================
                #   Publish OSDDriver
                #===================================================================================================
                if ($PublishPath -and ($OSDGroup -eq 'DellFamily')) {
                    Write-Warning "DellFamily does not support creating OSDDriver Packs at this time"
                }
                if ($PublishPath) {
                    #===================================================================================================
                    #   Create Package
                    #===================================================================================================
                    Write-Verbose "Verify: $PackFullName"
                    if (Test-Path "$PackFullName") {
                        Write-Warning "Compress-OSDDriver: $PackFullName already exists"
                    } else {
                        if ($OSDPackageFile -match '.zip') {
                            Write-Warning "Compress-OSDDriver: Generating $PackFullName ... This will take a while"
                            Compress-Archive -Path "$ExpandFullName" -DestinationPath "$PackFullName" -ErrorAction Stop
                        }
                        elseif ($OSDPackageFile -match '.cab') {
                            Write-Warning "New-DriverCabDellFamily: Generating $PackFullName ... This will take a while"
                            New-DriverCabDellFamily -DriverExpandPath $ExpandFullName -DestinationDirectory $WorkspacePack $OSDDriver.DriverCleanup
                        }
                        else {
                            Write-Warning 'Unable to determine the OSDDriver File Type'
                            Break
                        }
                    }
                    #===================================================================================================
                    #   Publish OSDDriver
                    #===================================================================================================
                    Write-Verbose "Verify: $PublishPath\$OSDPackageFile"
                    if (Test-Path "$PublishPath\$OSDPackageFile"){
                        Write-Warning "Publish-OSDDriver: $PublishPath\$OSDPackageFile already exists"
                    } else {
                        Write-Host "Publish-OSDDriver: Copying $PackFullName to $PublishPath ..." -ForegroundColor Gray
                        Copy-Item -Path "$PackFullName" -Destination "$PublishPath" -Force | Out-Null
                    }
                    $OSDDriver.OSDStatus = 'Published'
                    #===================================================================================================
                    #   Export Files
                    #===================================================================================================
                    Write-Verbose "Verify: $ExpandFullName\OSDDriver.cabpnp"
                    if (Test-Path "$ExpandFullName\OSDDriver.cabpnp") {
                        #Write-Verbose "Copy-Item: $ExpandFullName\OSDDriver.cabpnp to $WorkspacePack\$OSDPnpFile"
                        #Copy-Item -Path "$ExpandFullName\OSDDriver.cabpnp" -Destination "$WorkspacePack\$OSDPnpFile" -Force | Out-Null

                        Write-Verbose "Copy-Item: $ExpandFullName\OSDDriver.cabpnp to $PublishPath\$OSDPnpFile"
                        Copy-Item -Path "$ExpandFullName\OSDDriver.cabpnp" -Destination "$PublishPath\$OSDPnpFile" -Force | Out-Null
                    }
                    $OSDDriver | Export-Clixml -Path "$ExpandFullName\OSDDriver.clixml" -Force
                    $OSDDriver | ConvertTo-Json | Out-File -FilePath "$ExpandFullName\OSDDriver.cabtask" -Force
                    $OSDDriver | ConvertTo-Json | Out-File -FilePath "$PublishPath\$($DriverName).cabtask" -Force
                }
            }
        } else {
            Return $OSDDrivers
        }
    }

    End {
        #===================================================================================================
        #   Export Module
        #===================================================================================================
        if ($PublishPath) {Publish-OSDDriverScripts $PublishPath}
        Write-Host "Complete!" -ForegroundColor Green
    }
}