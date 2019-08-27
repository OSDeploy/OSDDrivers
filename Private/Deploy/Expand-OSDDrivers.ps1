function Expand-OSDDrivers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$PublishPath,

        [string]$ExpandDriverPath,

        [switch]$GridView,

        [string]$SetMake,
        [string]$SetModel,
        [string]$SetFamily,
        [string]$SetSku,

        [ValidateSet('x64','x86')]
        [string]$SetOSArch,

        [string]$SetOSBuild,

        #[ValidateSet('Client','Server')]
        #[string]$SetOSInstallationType,

        [ValidateSet('6.1','6.2','6.3','10.0')]
        [string]$SetOSVersion
    )
    #===================================================================================================
    #   Get-OSDDriver
    #===================================================================================================
    $OSDDriverMultiPacks = @()
    $OSDDriverMultiPacks = Get-OSDDriverMultiPacks -PublishPath $PublishPath -ErrorAction SilentlyContinue

    $OSDDriverPackages = @()
    $OSDDriverPackages = Get-OSDDriverPackages -PublishPath $PublishPath -ErrorAction SilentlyContinue

    $OSDDriverTasks = @()
    $OSDDriverTasks = Get-OSDDriverTasks -PublishPath $PublishPath -ErrorAction SilentlyContinue
    #===================================================================================================
    #   Connect to Task Sequence Environment
    #===================================================================================================
    try {
        $TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to construct Microsoft.SMS.TSEnvironment object"
    }
    #===================================================================================================
    #   Defaults
    #===================================================================================================
    $IsWinPE = $env:SystemDrive -eq 'X:'
    Write-Verbose "IsWinPE: $IsWinPE" -Verbose
    #===================================================================================================
    #   Set OSDisk
    #===================================================================================================
    $OSDisk = 'C:'
    #===================================================================================================
    #   WinPE = Find OSDisk
    #===================================================================================================
    if ($IsWinPE) {
        if ($TSEnv) {
            #MDT Default
            if ($TSEnv.Value('OSDisk') -match ':') {$OSDisk = $TSEnv.Value('OSDisk')}
            #MDT Secondary
            elseif ($TSEnv.Value('OSDTargetDriveCache') -match ':') {$OSDisk = $TSEnv.Value('OSDTargetDriveCache')}
            #SCCM Default
            elseif ($TSEnv.Value('OSDTargetSystemDrive') -match ':') {$OSDisk = $TSEnv.Value('OSDTargetSystemDrive')}
        }
    } else {
        $OSDisk = $env:SystemDrive
    }
    Write-Verbose "OSDisk: $OSDisk" -Verbose
    #===================================================================================================
    #   ExpandDriverPath
    #===================================================================================================
    if (!$ExpandDriverPath) {$ExpandDriverPath = $OSDisk + '\Drivers'}
    Write-Verbose "ExpandDriverPath: $ExpandDriverPath" -Verbose
    #===================================================================================================
    #   Validate
    #===================================================================================================
    if (-not (Test-Path "$ExpandDriverPath")) {
        try {
            New-Item -Path "$ExpandDriverPath\" -ItemType Directory -Force | Out-Null
        }
        catch {
            Write-Warning "Could not create $ExpandDriverPath ... Exiting"
            Start-Sleep 10
            Exit 0
        }
    }
    #===================================================================================================
    #   Start-Transcript
    #===================================================================================================
    $LogName = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-OSDDrivers.log"
    Start-Transcript -Path "$ExpandDriverPath\$LogName" | Out-Null
    #===================================================================================================
    #   Image OSArchitecture
    #===================================================================================================
    if ($SetOSArch) {
        Write-Verbose "SetOSArch (Parameter): $SetOSArch" -Verbose
        $ImageOSArchitecture = $SetOSArch
    } else {
        #MDT
        if ($TSEnv) {$ImageProcessor = $TSEnv.Value('ImageProcessor')}

        if ($ImageProcessor) {
            Write-Verbose "ImageProcessor (TSEnv): $ImageProcessor" -Verbose
            $ImageOSArchitecture = $ImageProcessor
        } else {
            $CimOSArchitecture = (Get-CimInstance -ClassName Win32_OperatingSystem).OSArchitecture
            Write-Verbose "Cim OS Architecture (Win32_OperatingSystem): $CimOSArchitecture" -Verbose
            if ($CimOSArchitecture -like "*64*") {$ImageOSArchitecture = 'x64'}
            if ($CimOSArchitecture -like "*32*") {$ImageOSArchitecture = 'x86'}

            if ($TSEnv) {Write-Warning "This parameter can be set by adding a Task Sequence Variable: g"}
        }
    }
    Write-Verbose "Image OSArchitecture: $ImageOSArchitecture" -Verbose
    #===================================================================================================
    #   ImageOSBuild
    #===================================================================================================
    if ($SetOSBuild) {
        Write-Verbose "SetOSBuild (Parameter): $SetOSBuild" -Verbose
        $ImageOSBuild = $SetOSBuild
    } else {
        #MDT
        if ($TSEnv) {$ImageBuild = $TSEnv.Value('ImageBuild')}

        if ($ImageBuild) {
            Write-Verbose "ImageBuild (TSEnv): $ImageBuild" -Verbose
            $ImageOSBuild = ([version]$ImageBuild).Build
        } else {
            $ImageOSBuild = (Get-CimInstance -ClassName Win32_OperatingSystem).BuildNumber
            Write-Verbose "Cim OS BuildNumber (Win32_OperatingSystem): $ImageOSBuild" -Verbose
        }
    }
    Write-Verbose "Image OSBuild: $ImageOSBuild" -Verbose
    #===================================================================================================
    #   ImageOSVersion
    #===================================================================================================
    if ($SetOSVersion) {
        Write-Verbose "SetOSVersion (Parameter): $SetOSVersion" -Verbose
        $ImageOSVersion = $SetOSVersion
    } else {
        #MDT
        if ($TSEnv) {$ImageBuild = $TSEnv.Value('ImageBuild')}

        if ($ImageBuild) {
            Write-Verbose "ImageBuild (TSEnv): $ImageBuild" -Verbose
            $ImageOSVersion = "$(([version]$ImageBuild).Major).$(([version]$ImageBuild).Minor)"
        } else {
            $CimOSVersion = (Get-CimInstance -ClassName Win32_OperatingSystem).Version
            Write-Verbose "Cim OS Version (Win32_OperatingSystem): $CimOSVersion" -Verbose
            $ImageOSVersion = "$(([version]$CimOSVersion).Major).$(([version]$CimOSVersion).Minor)"
        }
    }
    Write-Verbose "Image OSVersion: $ImageOSVersion" -Verbose

    #TODO
    #===================================================================================================
    #   ImageOSInstallationType
    #===================================================================================================
<#     if ($TSEnv) {$TaskSequenceTemplate = $TSEnv.Value('TaskSequenceTemplate')}

    if ($SetOSInstallationType) {
        Write-Verbose "Reading value from Parameter" -Verbose
        $ImageOSInstallationType = $SetOSInstallationType
    } elseif ($TaskSequenceTemplate) {
        Write-Verbose "Reading value from TSEnv" -Verbose
        if ($TaskSequenceTemplate -like "*Client*") {$ImageOSInstallationType = 'Client'}
        if ($TaskSequenceTemplate -like "*Server*") {$ImageOSInstallationType = 'Server'}
    } else {
        Write-Verbose "Reading value from Registry" -Verbose
        $ImageOSInstallationType = (Get-ItemProperty 'HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion').InstallationType
    }
    if ($ImageOSInstallationType -eq 'WinPE') {$ImageOSInstallationType = 'Client'}
    Write-Verbose "Image OSInstallationType: $ImageOSInstallationType" -Verbose #>
    #===================================================================================================
    #   Hardware
    #===================================================================================================
    $SystemMake = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
    if ($SetMake) {$SystemMake = $SetMake}
    Write-Verbose "System Make: $SystemMake" -Verbose

    $SystemModel = (Get-CimInstance -ClassName Win32_ComputerSystem).Model
    if ($SetModel) {$SystemModel = $SetModel}
    Write-Verbose "System Model: $SystemModel" -Verbose

    $SystemFamily = (Get-CimInstance -ClassName Win32_ComputerSystem).SystemFamily
    if ($SetFamily) {$SystemFamily = $SetFamily}
    Write-Verbose "System Family: $SystemFamily" -Verbose

    $SystemSKUNumber = (Get-CimInstance -ClassName Win32_ComputerSystem).SystemSKUNumber
    if ($SetSku) {$SystemSKUNumber = $SetSku}
    Write-Verbose "System SKUNumber: $SystemSKUNumber" -Verbose
    #===================================================================================================
    #   Save-MyHardware
    #===================================================================================================
    $MyHardware = @()
    Save-MyHardware -ExpandDriverPath $ExpandDriverPath | Out-Null
    $MyHardware = Get-MyHardware | Select-Object -Property DeviceID, Caption
    # Alternate Method
    # $MyHardware = (Save-MyHardware -ExpandDriverPath $ExpandDriverPath | Import-CliXml | Select-Object -Property DeviceID, Caption)

    #===================================================================================================
    #   Process MultiPacks
    #===================================================================================================
    Write-Host "Searching OSDDriver Tasks ..." -ForegroundColor Green
    $ExpandDrivers = @()

    $DriverPacks = @()
    $MultiPacks = @()
    $NvidiaPacks = @()
    #===================================================================================================
    #   DriverTaskFile
    #===================================================================================================
    foreach ($DriverTaskFile in $OSDDriverTasks) {
        #===================================================================================================
        #   Set Defaults
        #===================================================================================================
        $ExpandDriverPackage = $true
        #===================================================================================================
        #   Variables
        #===================================================================================================
        $DriverTaskBaseName     = $DriverTaskFile.BaseName
        $DriverTaskDirectory    = $DriverTaskFile.DirectoryName
        $DriverTaskFullName     = $DriverTaskFile.FullName
        
        $DriverTaskGroup         = Split-Path $DriverTaskDirectory -Leaf

        $DriverTaskCab          = "$(Join-Path $DriverTaskDirectory $DriverTaskBaseName).cab"
        $DriverTaskMultiPack      = "$(Join-Path $DriverTaskDirectory $DriverTaskBaseName).multipack"

        Write-Verbose "DriverTaskGroup: $DriverTaskGroup"
        Write-Verbose "DriverTaskBaseName: $DriverTaskBaseName"
        Write-Verbose "DriverTaskDirectory: $DriverTaskDirectory"
        Write-Verbose "DriverTaskFullName: $DriverTaskFullName"
        Write-Verbose "DriverTaskCab: $DriverTaskCab"
        Write-Verbose "DriverTaskMultiPack: $DriverTaskMultiPack"
        #===================================================================================================
        #   DriverTask
        #===================================================================================================
        $DriverTask = @()
        $DriverTask = Get-Content "$DriverTaskFullName" | ConvertFrom-Json
        #Write-Host -ForegroundColor Gray "$DriverTaskFullName"
        #===================================================================================================
        #   OsVersion
        #===================================================================================================
        if ($DriverTask.OsVersion) {
            $ExpandDriverPackage = $false
            foreach ($item in $DriverTask.OsVersion) {
                Write-Verbose "Driver Package Compatible OsArch: $item"
                if ($ImageOSVersion -match $item) {$ExpandDriverPackage = $true}
            }
            if ($ExpandDriverPackage -eq $false) {
                Write-Verbose "OSDDriver is not compatible with ImageOSVersion $ImageOSVersion"
                Continue
            }
        }
        #===================================================================================================
        #   OsArch
        #===================================================================================================
        if ($DriverTask.OsArch) {
            $ExpandDriverPackage = $false
            foreach ($item in $DriverTask.OsArch) {
                Write-Verbose "Driver Package Compatible OsArch: $item"
                if ($ImageOSArchitecture -match $item) {$ExpandDriverPackage = $true}
            }
            if ($ExpandDriverPackage -eq $false) {
                Write-Verbose "OSDDriver is not compatible with ImageOSArchitecture $ImageOSArchitecture"
                Continue
            }
        }
        #===================================================================================================
        #   Make
        #===================================================================================================
        if ($DriverTask.Make) {
            $ExpandDriverPackage = $false
            foreach ($item in $DriverTask.Make) {
                Write-Verbose "Driver CAB Compatible Make: $item"
                if ($SystemMake -match $item) {$ExpandDriverPackage = $true}
            }
            if ($ExpandDriverPackage -eq $false) {
                Write-Verbose "OSDDriver is not compatible with SystemMake $SystemMake"
                Continue
            }
        }
        #===================================================================================================
        #   ModelPack DellModel
        #===================================================================================================
        if ($DriverTask.OSDType -eq 'ModelPack' -and $DriverTask.OSDGroup -eq 'DellModel') {
            if ($DriverTask.Model -or $DriverTask.SystemSku) {
                $ExpandDriverPackage = $false
                foreach ($item in $DriverTask.Model) {
                    if ($SystemModel -eq $item) {
                        $ExpandDriverPackage = $true
                        Write-Verbose "OSDDriver is compatible with $SystemModel"
                        #$ExpandDrivers += $DriverPackage
                        Continue
                    }
                }
                foreach ($item in $DriverTask.SystemSku) {
                    if ($SystemSKUNumber -eq $item) {
                        $ExpandDriverPackage = $true
                        Write-Verbose "OSDDriver is compatible with SystemSKUNumber $SystemSKUNumber"
                        #$ExpandDrivers += $DriverPackage
                        Continue
                    }
                }
                if ($ExpandDriverPackage -eq $false) {
                    Write-Verbose "OSDDriver is not compatible with SystemModel $SystemModel $SystemSKUNumber"
                    Continue
                } else {
                    Write-Verbose "OSDDriver $DriverTaskBaseName is compatible with $SystemModel"
                    #$ExpandDrivers += $DriverPackage
                    #Continue
                }
            }
        }
        #===================================================================================================
        #   MakeNotMatch
        #===================================================================================================
        if ($DriverTask.MakeNotMatch) {
            foreach ($item in $DriverTask.MakeNotMatch) {
                if ($SystemMake -match $item) {$ExpandDriverPackage = $false}
            }
            if ($ExpandDriverPackage -eq $false) {Continue}
        }
        #===================================================================================================
        #   ModelNotMatch
        #===================================================================================================
        if ($DriverTask.ModelNotMatch) {
            foreach ($item in $DriverTask.ModelNotMatch) {
                if ($SystemModel -match $item) {$ExpandDriverPackage = $false}
            }
            if ($ExpandDriverPackage -eq $false) {Continue}
        }
        #===================================================================================================
        #   OsBuildMin
        #===================================================================================================
<#             if ($DriverTask.OsBuildMin) {
            $OsBuildMin = $DriverTask.OsBuildMin
            if (-not($ImageOSBuild -ge "$($OsBuildMin)")) {
                Write-Host "Image OSBuild $ImageOSBuild is not Greater or Equal to OSBuild Minimum $($OsBuildMin)" -ForegroundColor DarkGray
                Continue
            }
        } #>
        #===================================================================================================
        #   OsBuildMax
        #===================================================================================================
<#             if ($DriverTask.OsBuildMax) {
            $OsBuildMax = $DriverTask.OsBuildMax
            if (-not($ImageOSBuild -le "$($OsBuildMax)")) {
                Write-Host "$DriverPackageFullName reuires an Image OSBuild $ImageOSBuild is not Less or Equal to required OSBuild Maximum $($OsBuildMax)" -ForegroundColor DarkGray
                Continue
            }
        } #>
        #===================================================================================================
        #   Separate Tasks
        #===================================================================================================
        if (Test-Path "$DriverTaskMultiPack") {
            $MultiPacks += $DriverTaskFile
            Continue
        }
        if ($DriverTask.OSDGroup -eq 'NvidiaPack') {
            $NvidiaPacks += $DriverTaskFile
            Continue
        }
        $DriverPacks += $DriverTaskFile
        Continue
    }
    #===================================================================================================
    #   Process DriverPacks
    #===================================================================================================
    if ($DriverPacks) {
        Write-Host "Processing DriverPacks ..." -ForegroundColor Green
        $ExpandDriverPacks = @()
        foreach ($DriverTaskFile in $DriverPacks) {
    
            $DriverTaskBaseName     = $DriverTaskFile.BaseName
            $DriverTaskDirectory    = $DriverTaskFile.DirectoryName
            $DriverTaskFullName     = $DriverTaskFile.FullName
            
            $DriverTaskGroup         = Split-Path $DriverTaskDirectory -Leaf
    
            $DriverTaskCab          = "$(Join-Path $DriverTaskDirectory $DriverTaskBaseName).cab"
            $DriverTaskZip          = "$(Join-Path $DriverTaskDirectory $DriverTaskBaseName).zip"
            $DriverTaskPnp          = "$(Join-Path $DriverTaskDirectory $DriverTaskBaseName).drvpnp"
            $DriverTaskMultiPack      = "$(Join-Path $DriverTaskDirectory $DriverTaskBaseName).multipack"
    
    
            Write-Verbose "DriverTaskGroup: $DriverTaskGroup"
            Write-Verbose "DriverTaskBaseName: $DriverTaskBaseName"
            Write-Verbose "DriverTaskDirectory: $DriverTaskDirectory"
            Write-Verbose "DriverTaskFullName: $DriverTaskFullName"
            Write-Verbose "DriverTaskCab: $DriverTaskCab"
            Write-Verbose "DriverTaskPnp: $DriverTaskPnp"
            Write-Verbose "DriverTaskMultiPack: $DriverTaskMultiPack"
    
            Write-Host -ForegroundColor Gray "$($DriverTaskFile.FullName)"
    
            if (Test-Path $DriverTaskPnp) {
                $ExpandDriverPackage = $false
                $HardwareIdMatches = @()
                $OSDPnpFile = @()
                $OSDPnpFile = Import-CliXml -Path "$DriverTaskPnp"
            
                foreach ($PnpDriverId in $OSDPnpFile) {
                    $HardwareDescription = $($PnpDriverId.HardwareDescription)
                    $HardwareId = $($PnpDriverId.HardwareId)
            
                    if ($MyHardware -like "*$HardwareId*") {
                        #Write-Host "$HardwareDescription $HardwareId " -Foregroundcolor Cyan
                        $ExpandDriverPackage = $true
                        $HardwareIdMatches += "$HardwareDescription $HardwareId"
                    }
                }
    
                if ($ExpandDriverPackage -eq $false) {
                    Write-Verbose "Driver does not support the Hardware in this system"
                    Continue
                }
                if ($HardwareIdMatches) {
                    #Write-Host "HardwareID Match"
                    foreach ($HardwareIdMatch in $HardwareIdMatches) {
                        Write-Verbose "$($HardwareIdMatch)" -Verbose
                    }
                }
            }
            if (Test-Path $DriverTaskCab) {
                $ExpandDriverPacks += $DriverTaskCab
            }
            if (Test-Path $DriverTaskZip) {
                $ExpandDriverPacks += $DriverTaskZip
            }
        }
    }
    #===================================================================================================
    #   Process NvidiaPacks
    #===================================================================================================
    if ($NvidiaPacks) {
        Write-Host "Processing NvidiaPacks ..." -ForegroundColor Green
        $ExpandNvidiaPacks = @()
        $ExpandNvidiaTasks = @()
        foreach ($DriverTaskFile in $NvidiaPacks) {
            $DriverTaskBaseName     = $DriverTaskFile.BaseName
            $DriverTaskDirectory    = $DriverTaskFile.DirectoryName
            $DriverTaskFullName     = $DriverTaskFile.FullName
            
            $DriverTaskGroup         = Split-Path $DriverTaskDirectory -Leaf
    
            $DriverTaskCab          = "$(Join-Path $DriverTaskDirectory $DriverTaskBaseName).cab"
            $DriverTaskZip          = "$(Join-Path $DriverTaskDirectory $DriverTaskBaseName).zip"
            $DriverTaskPnp          = "$(Join-Path $DriverTaskDirectory $DriverTaskBaseName).drvpnp"
            $DriverTaskMultiPack      = "$(Join-Path $DriverTaskDirectory $DriverTaskBaseName).multipack"
    
    
            Write-Verbose "DriverTaskGroup: $DriverTaskGroup"
            Write-Verbose "DriverTaskBaseName: $DriverTaskBaseName"
            Write-Verbose "DriverTaskDirectory: $DriverTaskDirectory"
            Write-Verbose "DriverTaskFullName: $DriverTaskFullName"
            Write-Verbose "DriverTaskCab: $DriverTaskCab"
            Write-Verbose "DriverTaskPnp: $DriverTaskPnp"
            Write-Verbose "DriverTaskMultiPack: $DriverTaskMultiPack"
    
            Write-Host -ForegroundColor Gray "$($DriverTaskFile.FullName)"
    
            if (Test-Path $DriverTaskPnp) {
                $ExpandDriverPackage = $false
                $HardwareIdMatches = @()
                $OSDPnpFile = @()
                $OSDPnpFile = Import-CliXml -Path "$DriverTaskPnp"
            
                foreach ($PnpDriverId in $OSDPnpFile) {
                    $HardwareDescription = $($PnpDriverId.HardwareDescription)
                    $HardwareId = $($PnpDriverId.HardwareId)
            
                    if ($MyHardware -like "*$HardwareId*") {
                        #Write-Host "$HardwareDescription $HardwareId " -Foregroundcolor Cyan
                        $ExpandDriverPackage = $true
                        $HardwareIdMatches += "$HardwareDescription $HardwareId"
                    }
                }
    
                if ($ExpandDriverPackage -eq $false) {
                    Write-Verbose "Driver does not support the Hardware in this system"
                    Continue
                }
                if ($HardwareIdMatches) {
                    #Write-Host "HardwareID Match"
                    foreach ($HardwareIdMatch in $HardwareIdMatches) {
                        Write-Verbose "$($HardwareIdMatch)" -Verbose
                    }
                }
            }
            if (Test-Path $DriverTaskCab) {
                $ExpandNvidiaTasks += $DriverTaskFullName
                $ExpandNvidiaPacks += $DriverTaskCab
                Continue
            }
            if (Test-Path $DriverTaskZip) {
                $ExpandNvidiaTasks += $DriverTaskFullName
                $ExpandNvidiaPacks += $DriverTaskZip
                Continue
            }
            $ExpandNvidiaTasks += $DriverTaskFullName
        }
    }
    #===================================================================================================
    #   Throw NvidiaPacks
    #===================================================================================================
    if ($ExpandNvidiaTasks) {
        $ExpandNvidiaTasks = $ExpandNvidiaTasks | Sort-Object | Select-Object -Last 1

        $NvidiaTask = @()
        $NvidiaTask = Get-Content "$ExpandNvidiaTasks" | ConvertFrom-Json
        Write-Verbose "Selecting NvidiaPack Grouping $($NvidiaTask.DriverGrouping)" -Verbose
        Write-Verbose "Selecting NvidiaPack ReleaseId $($NvidiaTask.DriverReleaseId)" -Verbose

        if ($TSEnv) {
            Write-Verbose "Setting Task Sequence Variable NvidiaPackGrouping to $($NvidiaTask.DriverGrouping)" -Verbose
            $TSEnv.Value('NvidiaPackGrouping') = "$($NvidiaTask.DriverGrouping)"
            Write-Verbose "Setting Task Sequence Variable NvidiaPackReleaseId to $($NvidiaTask.DriverReleaseId)" -Verbose
            $TSEnv.Value('NvidiaPackReleaseId') = "$($NvidiaTask.DriverReleaseId)"
        }
    }
    $ExpandNvidiaPacks = $ExpandNvidiaPacks | Where-Object {$_ -match $NvidiaTask.DriverGrouping}
    #===================================================================================================
    #   Expand DriverPacks
    #===================================================================================================
    if ($ExpandDriverPacks) {
        Write-Host "Expanding DriverPacks ..." -Foregroundcolor Green
        foreach ($ExpandDriverPack in $ExpandDriverPacks) {
            $ExpandItem = Get-Item $ExpandDriverPack | Select-Object -Property *

            $DriverPackageName = $ExpandItem.Name
            $DriverPackageBaseName = $ExpandItem.BaseName
            $DriverPackageFullName = $ExpandItem.FullName
            $DriverPackageDirectoryName = $ExpandItem.DirectoryName

            Write-Verbose "DriverPackageName: $DriverPackageName"
            Write-Verbose "DriverPackageBaseName: $DriverPackageBaseName"
            Write-Verbose "DriverPackageFullName: $DriverPackageFullName"
            Write-Verbose "DriverPackageDirectoryName: $DriverPackageDirectoryName"

            if (!(Test-Path "$ExpandDriverPath\$DriverPackageBaseName")) {
                New-Item -Path "$ExpandDriverPath\$DriverPackageBaseName" -ItemType Directory -Force | Out-Null
            }
            if ($DriverPackageName -match '.cab') {
                #Write-Host "Expanding CAB $DriverPackageFullName to $ExpandDriverPath\$DriverPackageBaseName" -ForegroundColor Cyan
                Write-Verbose "Expanding $ExpandDriverPath\$DriverPackageBaseName" -Verbose
                Expand -R "$DriverPackageFullName" -F:* "$ExpandDriverPath\$DriverPackageBaseName" | Out-Null
            }
            if ($DriverPackageName -match '.zip') {
                Write-Host "Expanding ZIP $DriverPackageFullName to $ExpandDriverPath\$DriverPackageBaseName" -ForegroundColor Cyan
                Expand-Archive -Path "$DriverPackageFullName" -DestinationPath "$ExpandDriverPath" -Force
            }
        }
    }
    #===================================================================================================
    #   Expand NvidiaPacks
    #===================================================================================================
    if ($ExpandNvidiaPacks) {
        Write-Host "Expanding NvidiaPacks ..." -Foregroundcolor Green
        foreach ($ExpandDriverPack in $ExpandNvidiaPacks) {
            $ExpandItem = Get-Item $ExpandDriverPack | Select-Object -Property *

            $DriverPackageName = $ExpandItem.Name
            $DriverPackageBaseName = $ExpandItem.BaseName
            $DriverPackageFullName = $ExpandItem.FullName
            $DriverPackageDirectoryName = $ExpandItem.DirectoryName

            Write-Verbose "DriverPackageName: $DriverPackageName"
            Write-Verbose "DriverPackageBaseName: $DriverPackageBaseName"
            Write-Verbose "DriverPackageFullName: $DriverPackageFullName"
            Write-Verbose "DriverPackageDirectoryName: $DriverPackageDirectoryName"

            if (!(Test-Path "$ExpandDriverPath\$DriverPackageBaseName")) {
                New-Item -Path "$ExpandDriverPath\$DriverPackageBaseName" -ItemType Directory -Force | Out-Null
            }
            if ($DriverPackageName -match '.cab') {
                #Write-Host "Expanding CAB $DriverPackageFullName to $ExpandDriverPath\$DriverPackageBaseName" -ForegroundColor Cyan
                Write-Verbose "Expanding $ExpandDriverPath\$DriverPackageBaseName" -Verbose
                Expand -R "$DriverPackageFullName" -F:* "$ExpandDriverPath\$DriverPackageBaseName" | Out-Null
            }
            if ($DriverPackageName -match '.zip') {
                Write-Host "Expanding ZIP $DriverPackageFullName to $ExpandDriverPath\$DriverPackageBaseName" -ForegroundColor Cyan
                Expand-Archive -Path "$DriverPackageFullName" -DestinationPath "$ExpandDriverPath" -Force
            }
        }
    }
    #===================================================================================================
    #   Process MultiPacks
    #===================================================================================================
    if ($MultiPacks) {
        Write-Host "Processing MultiPacks ..." -ForegroundColor Green
        foreach ($DriverTaskFile in $MultiPacks) {
            $DriverTaskBaseName     = $DriverTaskFile.BaseName
            $DriverTaskDirectory    = $DriverTaskFile.DirectoryName
            $DriverTaskFullName     = $DriverTaskFile.FullName
            
            $DriverTaskGroup         = Split-Path $DriverTaskDirectory -Leaf
            $DriverTaskMultiPack      = "$(Join-Path $DriverTaskDirectory $DriverTaskBaseName).multipack"
    
    
            Write-Verbose "DriverTaskGroup: $DriverTaskGroup"
            Write-Verbose "DriverTaskBaseName: $DriverTaskBaseName"
            Write-Verbose "DriverTaskDirectory: $DriverTaskDirectory"
            Write-Verbose "DriverTaskFullName: $DriverTaskFullName"
            Write-Verbose "DriverTaskMultiPack: $DriverTaskMultiPack"
    
            Write-Host -ForegroundColor Gray "$($DriverTaskFile.FullName)"
    
            if (!(Test-Path "$DriverTaskMultiPack")) {
                Write-Verbose "Could not find $DriverTaskMultiPack"
                Continue
            }
    
            #===================================================================================================
            #   MultiPackFileList
            #===================================================================================================
            $MultiPackDrivers = @()
            $MultiPackDrivers = Get-Content "$DriverTaskMultiPack" | ConvertFrom-Json
            foreach ($ExpandDriver in $MultiPackDrivers) {
                $MultiPackDriverFullName = (Join-Path $DriverTaskDirectory $ExpandDriver)
                Write-Verbose "MultiPackDriverFullName: $MultiPackDriverFullName"
    
                if (Test-Path "$MultiPackDriverFullName") {
                    $ExpandMultiPack = (Join-Path $ExpandDriverPath $DriverTaskBaseName)
                    Write-Verbose "ExpandMultiPack: $ExpandMultiPack"
                    
                    $MultiPackDriverBaseName = ((Get-Item $MultiPackDriverFullName).BaseName)
                    Write-Verbose "MultiPackDriverBaseName: $MultiPackDriverBaseName"
                    $MultiPackDriverCategory = ((Get-Item $MultiPackDriverFullName).Directory.Name)
                    Write-Verbose "MultiPackDriverCategory: $MultiPackDriverCategory"
                    $MultiPackDriverOsArch = ((Get-Item $MultiPackDriverFullName).Directory.Parent)
                    Write-Verbose "MultiPackDriverOsArch: $MultiPackDriverOsArch"
    
                    $ExpandParent = "$ExpandMultiPack\$MultiPackDriverOsArch\$MultiPackDriverCategory"
                    $ExpandDirectory = "$ExpandParent\$MultiPackDriverBaseName"
    
                    Write-Verbose "Expanding $ExpandDirectory" -Verbose
    
                    if (!(Test-Path "$ExpandDirectory")) {
                        New-Item -Path "$ExpandDirectory" -ItemType Directory -Force | Out-Null
                    }
                    if ($MultiPackDriverFullName -match '.cab') {
                        Write-Verbose "Expanding CAB $MultiPackDriverFullName to $ExpandDirectory"
                        Expand -R "$MultiPackDriverFullName" -F:* "$ExpandDirectory" | Out-Null
                    }
                    if ($MultiPackDriverFullName -match '.zip') {
                        Write-Verbose "Expanding ZIP $MultiPackDriverFullName to $ExpandDirectory"
                        Expand-Archive -Path "$MultiPackDriverFullName" -DestinationPath "$ExpandParent" -Force
                    }
                }
            }
        }
    }
<#     #===================================================================================================
    #   Process MultiPacks
    #===================================================================================================
    Write-Host "Searching OSDDriver MultiPacks ..." -ForegroundColor Green
    $ExpandDrivers = @()

    foreach ($MultiPack in $OSDDriverMultiPacks) {
        #===================================================================================================
        #   MultiPackFileList
        #===================================================================================================
        $MultiPackDrivers = @()
        $MultiPackDrivers = Get-Content "$MultiPackFileList" | ConvertFrom-Json
        $MultiPackDrivers = $MultiPackDrivers | Where-Object {$_ -match $ImageOSArchitecture}

        foreach ($ExpandDriver in $MultiPackDrivers) {

            $MultiPackDriverFullName = (Join-Path $MultiPackDirectory $ExpandDriver)
            Write-Verbose "$MultiPackDriverFullName"

            if (Test-Path "$MultiPackDriverFullName") {
                $ExpandMultiPack = (Join-Path $ExpandDriverPath $MultiPackName)
                Write-Verbose "$ExpandMultiPack"
                
                $MultiPackDriverBaseName = ((Get-Item $MultiPackDriverFullName).BaseName)
                Write-Verbose "$MultiPackDriverBaseName"
                $MultiPackDriverCategory = ((Get-Item $MultiPackDriverFullName).Directory.Name)
                Write-Verbose "$MultiPackDriverCategory"
                $MultiPackDriverOsArch = ((Get-Item $MultiPackDriverFullName).Directory.Parent)
                Write-Verbose "$MultiPackDriverOsArch"

                $ExpandParent = "$ExpandMultiPack\$MultiPackDriverOsArch\$MultiPackDriverCategory"
                $ExpandDirectory = "$ExpandParent\$MultiPackDriverBaseName"

                Write-Verbose "Expanding $ExpandDirectory" -Verbose

                if (!(Test-Path "$ExpandDirectory")) {
                    New-Item -Path "$ExpandDirectory" -ItemType Directory -Force | Out-Null
                }
                if ($MultiPackDriverFullName -match '.cab') {
                    Write-Verbose "Expanding CAB $MultiPackDriverFullName to $ExpandDirectory"
                    Expand -R "$MultiPackDriverFullName" -F:* "$ExpandDirectory" | Out-Null
                }
                if ($MultiPackDriverFullName -match '.zip') {
                    Write-Verbose "Expanding ZIP $MultiPackDriverFullName to $ExpandDirectory"
                    Expand-Archive -Path "$MultiPackDriverFullName" -DestinationPath "$ExpandParent" -Force
                }
            }
        }
    } #>
    Stop-Transcript | Out-Null
}