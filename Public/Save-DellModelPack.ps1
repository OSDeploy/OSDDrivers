<#
.SYNOPSIS
Downloads Dell Model Packs

.DESCRIPTION
Downloads Dell Model Packs to $WorkspacePath\Download\DellModel
Requires BITS for downloading the Downloads
Requires Internet access

.LINK
https://osddrivers.osdeploy.com/module/functions/save-dellmodelpack

.PARAMETER WorkspacePath
Directory to the OSDDrivers Workspace.  This contains the Download, Expand, and Package subdirectories

.PARAMETER Generation
Generation of the Dell Model

.PARAMETER OsVersion
OsVersion of the Driver

.PARAMETER SystemFamily
Filters compatibility to Latitude, Optiplex, or Precision.  Venue, Vostro, and XPS are not included

.PARAMETER Expand
Expands the downloaded Dell Model Packs

.PARAMETER Pack
Creates a CAB file from the DellFamily DriverPack.  Default removes Intel Video

.PARAMETER MultiPackName
Name of the MultiPack that will be created in Workspace\Packages

.PARAMETER RemoveAudio
Removes drivers in the Audio Directory from being added to the CAB or MultiPack

.PARAMETER RemoveAmdVideo
Removes AMD Video Drivers from being added to the CAB or MultiPack

.PARAMETER RemoveIntelVideo
Removes Intel Video Drivers from being added to a MultiPack

.PARAMETER RemoveNvidiaVideo
Removes Nvidia Video Drivers from being added to the CAB or MultiPack
#>
function Save-DellModelPack {
    [CmdletBinding(DefaultParameterSetName='Download')]
    Param (
        [Parameter(ValueFromPipeline = $true)]
        [Object[]]$InputObject,

        [Parameter(Mandatory)]
        [string]$WorkspacePath,
        #===================================================================================================
        #   Filters
        #===================================================================================================
        [ValidateSet ('X10','X9','X8','X7','X6','X5','X4','X3','X2','X1')]
        [string]$Generation,

        [ValidateSet ('10.0','6.1')]
        [string]$OsVersion = '10.0',

        [ValidateSet ('Latitude','Optiplex','Precision')]
        [string]$SystemFamily,

        #[ValidateSet ('Latitude A','Latitude N','Precision M','Precision N','Precision W')]
        #[string]$CustomGroup,
        #===================================================================================================
        #   Download
        #===================================================================================================
        [Parameter(ParameterSetName = 'Download')]
        [switch]$Expand,
        #===================================================================================================
        #   Pack
        #===================================================================================================
        [Parameter(ParameterSetName = 'Pack', Mandatory = $true)]
        [switch]$Pack,
        #===================================================================================================
        #   Remove
        #===================================================================================================
        [Parameter(ParameterSetName = 'Pack')]
        [switch]$RemoveAudio = $false,
        
        [Parameter(ParameterSetName = 'Pack')]
        [switch]$RemoveAmdVideo = $false,

        [Parameter(ParameterSetName = 'Pack')]
        [switch]$RemoveNvidiaVideo = $false
        #===================================================================================================
        #   Scraps
        #===================================================================================================
        #[Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        #[ValidateSet('DellModel','DellFamily')]
        #[string]$OSDGroup,

        #[Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        #[ValidateSet ('x64','x86')]
        #[string]$OsArch,

        #[switch]$SkipGridView
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
        Publish-OSDDriverScripts -PublishPath $WorkspaceDownload

        $WorkspaceExpand = Get-PathOSDD -Path (Join-Path $OSDWorkspace 'Expand')
        Write-Verbose "Workspace Expand: $WorkspaceExpand" -Verbose

        $WorkspacePackage = Get-PathOSDD -Path (Join-Path $OSDWorkspace 'Package')
        Write-Verbose "Workspace Package: $WorkspacePackage" -Verbose
        Publish-OSDDriverScripts -PublishPath $WorkspacePackage
        #===================================================================================================
    }

    Process {
        #===================================================================================================
        #   Defaults
        #===================================================================================================
        $OSDGroup = 'DellModel'

        if ($PSCmdlet.ParameterSetName -eq 'Pack') {
            $Expand = $true
            $RemoveIntelVideo = $true
        }

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
            $PackagedDriverPath     = (Join-Path $WorkspacePackage (Join-Path $OSDGroup $OSDCabFile))
            Write-Verbose "DownloadedDriverGroup: $DownloadedDriverGroup"
            Write-Verbose "DownloadedDriverPath: $DownloadedDriverPath"
            Write-Verbose "ExpandedDriverPath: $ExpandedDriverPath"
            Write-Verbose "PackagedDriverPath: $PackagedDriverPath"

            if (Test-Path "$DownloadedDriverPath") {$OSDDriver.OSDStatus = 'Downloaded'}
            if (Test-Path "$ExpandedDriverPath") {$OSDDriver.OSDStatus = 'Expanded'}
            if (Test-Path "$PackagedDriverPath") {$OSDDriver.OSDStatus = 'Packaged'}
        }
        #===================================================================================================
        #   CustomGroup
        #[ValidateSet ('Latitude','Latitude X',Precision M','Precision N','Precision W')]
        #===================================================================================================
        if ($CustomGroup) {
            if ($CustomGroup -eq 'Latitude A') {
                $OSDDrivers = $OSDDrivers | Where-Object {$_.SystemFamily -match 'Latitude'}
                $OSDDrivers = $OSDDrivers | Where-Object {($_.Model -match 'Latitude D') -or ($_.Model -match 'Latitude E') -or ($_.Model -match 'Latitude X') -or ($_.Model -like "Latitude*U")}
            }
            if ($CustomGroup -eq 'Latitude N') {
                $OSDDrivers = $OSDDrivers | Where-Object {$_.SystemFamily -match 'Latitude'}
                $OSDDrivers = $OSDDrivers | Where-Object {$_.Model -notmatch 'Latitude D'}
                $OSDDrivers = $OSDDrivers | Where-Object {$_.Model -notmatch 'Latitude E'}
                $OSDDrivers = $OSDDrivers | Where-Object {$_.Model -notmatch 'Latitude X'}
                $OSDDrivers = $OSDDrivers | Where-Object {$_.Model -notlike "Latitude*U"}
            }
            if ($CustomGroup -eq 'Precision M') {
                $OSDDrivers = $OSDDrivers | Where-Object {$_.Model -match 'Precision M'}
            }
            if ($CustomGroup -eq 'Precision N') {
                $OSDDrivers = $OSDDrivers | Where-Object {$_.SystemFamily -match 'Precision'}
                $OSDDrivers = $OSDDrivers | Where-Object {$_.Model -notmatch 'Rack'}
                $OSDDrivers = $OSDDrivers | Where-Object {$_.Model -notmatch 'Tower'}
                $OSDDrivers = $OSDDrivers | Where-Object {$_.Model -notmatch 'Precision M'}
                $OSDDrivers = $OSDDrivers | Where-Object {$_.Model -notmatch 'Precision R'}
                $OSDDrivers = $OSDDrivers | Where-Object {$_.Model -notmatch 'Precision T'}
                $OSDDrivers = $OSDDrivers | Where-Object {$_.Model -notmatch 'Workstation'}
            }
            if ($CustomGroup -eq 'Precision W') {
                $OSDDrivers = $OSDDrivers | Where-Object {$_.SystemFamily -match 'Precision'}
                $OSDDrivers = $OSDDrivers | Where-Object {($_.Model -match 'Rack') -or ($_.Model -match 'Tower') -or ($_.Model -match 'Precision R') -or ($_.Model -match 'Precision T') -or ($_.Model -match 'Workstation')}
            }
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
        #   GridView
        #===================================================================================================
        $OSDDrivers = $OSDDrivers | Sort-Object LastUpdate -Descending
        if ($SkipGridView) {
            #Write-Warning "SkipGridView: Skipping Out-GridView"
        } else {
            $OSDDrivers = $OSDDrivers | Out-GridView -PassThru -Title "Select Drivers to Download and press OK"
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
                $PackagedDriverPath = (Join-Path $WorkspacePackage (Join-Path $OSDGroup $OSDCabFile))

                if (-not(Test-Path "$DownloadedDriverGroup")) {New-Item $DownloadedDriverGroup -Directory -Force | Out-Null}

                Write-Verbose "DownloadedDriverPath: $DownloadedDriverPath"
                Write-Verbose "ExpandedDriverPath: $ExpandedDriverPath"
                Write-Verbose "PackagedDriverPath: $PackagedDriverPath"

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
                if ($MyInvocation.MyCommand.Name -eq 'Save-DellMultiPack') {
                    $PackagedDriverGroup = Get-PathOSDD -Path (Join-Path $WorkspacePackage (Join-Path 'DellMultiPack' $MultiPackName))
                    $OSDDriver | ConvertTo-Json | Out-File -FilePath "$PackagedDriverGroup\$($OSDDriver.DriverName).drvpack" -Force
                } else {
                    $PackagedDriverGroup = Get-PathOSDD -Path (Join-Path $WorkspacePackage $OSDGroup)
                    $OSDDriver | Export-Clixml -Path "$ExpandedDriverPath\OSDDriver.clixml" -Force
                    $OSDDriver | ConvertTo-Json | Out-File -FilePath "$ExpandedDriverPath\OSDDriver.drvpack" -Force
                }
                #===================================================================================================
                #   Pack
                #===================================================================================================
                if ($PSCmdlet.ParameterSetName -eq 'Pack') {
                    #===================================================================================================
                    #   Create Package
                    #===================================================================================================
                    Write-Verbose "Verify: $PackagedDriverPath"
                    if (Test-Path "$PackagedDriverPath") {
                        Write-Warning "Driver Pack: $PackagedDriverPath already exists and will not be created"
                    } else {
                        Write-Warning "Driver Pack: Generating $PackagedDriverPath ... This will take a while"
                        New-CabFileDell $ExpandedDriverPath $PackagedDriverGroup $RemoveAudio $RemoveAmdVideo $RemoveIntelVideo $RemoveNvidiaVideo
                    }
                    #===================================================================================================
                    #   Verify Driver Package
                    #===================================================================================================
                    if (-not (Test-Path "$PackagedDriverPath")) {
                        Write-Warning "Driver Package: Could not package Driver to $PackagedDriverPath ..."
                        $OSDDriver | Export-Clixml -Path "$ExpandedDriverPath\OSDDriver.clixml" -Force
                        $OSDDriver | ConvertTo-Json | Out-File -FilePath "$ExpandedDriverPath\OSDDriver.drvpack" -Force
                        $OSDDriver | ConvertTo-Json | Out-File -FilePath "$PackagedDriverGroup\$($DriverName).drvpack" -Force
                        Continue
                    }
                    $OSDDriver.OSDStatus = "Packaged"
                    #===================================================================================================
                    #   Export Results
                    #===================================================================================================
                    $OSDDriver | Export-Clixml -Path "$ExpandedDriverPath\OSDDriver.clixml" -Force
                    $OSDDriver | ConvertTo-Json | Out-File -FilePath "$ExpandedDriverPath\OSDDriver.drvpack" -Force
                    $OSDDriver | ConvertTo-Json | Out-File -FilePath "$PackagedDriverGroup\$($DriverName).drvpack" -Force
                    #===================================================================================================
                    #   Publish-OSDDriverScripts
                    #===================================================================================================
                    Publish-OSDDriverScripts -PublishPath $PackagedDriverGroup
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
        Write-Host "Complete!" -ForegroundColor Green
        #===================================================================================================
    }
}