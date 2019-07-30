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
    #   Get-OSDDriverPackages
    #===================================================================================================
    $OSDDriverPackages = @()
    $OSDDriverPackages = Get-OSDDriverPackages -PublishPath $PublishPath -ErrorAction SilentlyContinue
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
    #   Expand-OSDDrivers
    #===================================================================================================
    Write-Host "Processing OSDDriver Packages ..." -ForegroundColor Green
    $ExpandDrivers = @()

    foreach ($OSDDriver in $OSDDriverPackages) {
        $OSDDriverCab = $OSDDriver.Name
        $OSDDriverBaseName = $OSDDriver.BaseName
        $OSDDriverFullName = $OSDDriver.FullName
        $OSDDriverDirectoryName = $OSDDriver.DirectoryName

        $OSDDriverPnp = "$(Join-Path $OSDDriverDirectoryName $OSDDriverBaseName).drvpnp"
        $OSDDriverTask = "$(Join-Path $OSDDriverDirectoryName $OSDDriverBaseName).drvtask"

        Write-Host "$OSDDriverFullName ... " -ForegroundColor Gray -NoNewLine
        $ExpandDriverCab = $true
        #===================================================================================================
        #   WinPE
        #===================================================================================================
        if ($OSDDriverCab -match 'WinPE') {
            Write-Host "Driver is intended for WinPE" -ForegroundColor DarkGray
            Continue
        }
        #===================================================================================================
        #   OSDDriverTask
        #===================================================================================================
        if (Test-Path $OSDDriverTask) {
            $DriverTask = @()
            $DriverTask = Get-Content "$OSDDriverTask" | ConvertFrom-Json
            #===================================================================================================
            #   OSArch
            #===================================================================================================
            if ($DriverTask.OSArchMatch) {
                Write-Verbose "Driver OSArchMatch: $($DriverTask.OSArchMatch)"

                if ($DriverTask.OSArchMatch -match 'x64') {
                    if ($ImageOSArchitecture -like "*32*" -or $ImageOSArchitecture -like "*x86*") {
                        Write-Host "Not compatible with Image OSArchitecture $ImageOSArchitecture" -ForegroundColor DarkGray
                        Continue
                    }
                }
                if ($DriverTask.OSArchMatch -match 'x86') {
                    if ($ImageOSArchitecture -like "*64*") {
                        Write-Host "Not compatible with Image OSArchitecture $ImageOSArchitecture" -ForegroundColor DarkGray
                        Continue
                    }
                }
            }
            #===================================================================================================
            #   OSVersionMatch
            #===================================================================================================
            if ($DriverTask.OSVersionMatch) {
                $OSVersionMatch = $DriverTask.OSVersionMatch
                if (-not($OSVersionMatch -match $ImageOSVersion)) {
                    Write-Host "Not compatible with Image OSVersion $ImageOSVersion" -ForegroundColor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   OSBuildGE
            #===================================================================================================
            if ($DriverTask.OSBuildGE) {
                $OSBuildGE = $DriverTask.OSBuildGE
                if (-not($ImageOSBuild -ge "$($OSBuildGE)")) {
                    Write-Host "Image OSBuild $ImageOSBuild is not Greater or Equal to required OSBuild $($OSBuildGE)" -ForegroundColor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   OSBuildLE
            #===================================================================================================
            if ($DriverTask.OSBuildLE) {
                $OSBuildLE = $DriverTask.OSBuildLE
                if (-not($ImageOSBuild -le "$($OSBuildLE)")) {
                    Write-Host "Image OSBuild $ImageOSBuild is not Less or Equal to required OSBuild $($OSBuildLE)" -ForegroundColor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   MakeLike
            #===================================================================================================
            if ($DriverTask.MakeLike) {
                $ExpandDriverCab = $false
                foreach ($item in $DriverTask.MakeLike) {
                    Write-Verbose "Driver CAB Compatible Make: $item"
                    if ($SystemMake -like $item) {$ExpandDriverCab = $true}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "Not compatible with System Make $SystemMake" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   MakeNotLike
            #===================================================================================================
            if ($DriverTask.MakeNotLike) {
                foreach ($item in $DriverTask.MakeNotLike) {
                    Write-Verbose "Driver CAB Not Compatible Make: $item"
                    if ($SystemMake -like $item) {$ExpandDriverCab = $false}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "Not compatible with System Make $SystemMake" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   MakeMatch
            #===================================================================================================
            if ($DriverTask.MakeMatch) {
                $ExpandDriverCab = $false
                foreach ($item in $DriverTask.MakeMatch) {
                    Write-Verbose "Driver CAB Compatible Make: $item"
                    if ($SystemMake -match $item) {$ExpandDriverCab = $true}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "Not compatible with System Make $SystemMake" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   MakeNotMatch
            #===================================================================================================
            if ($DriverTask.MakeNotMatch) {
                foreach ($item in $DriverTask.MakeNotMatch) {
                    Write-Verbose "Driver CAB Not Compatible Make: $item"
                    if ($SystemMake -match $item) {$ExpandDriverCab = $false}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "Not compatible with System Make $SystemMake" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   ModelLike
            #===================================================================================================
            if ($DriverTask.ModelLike) {
                $ExpandDriverCab = $false
                foreach ($item in $DriverTask.ModelLike) {
                    Write-Verbose "Driver CAB Compatible Model: $item"
                    if ($SystemModel -like $item) {$ExpandDriverCab = $true}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "$SystemModel ModelLike is evaluated false" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   ModelNotLike
            #===================================================================================================
            if ($DriverTask.ModelNotLike) {
                foreach ($item in $DriverTask.ModelNotLike) {
                    Write-Verbose "Driver CAB Not Compatible Model: $item"
                    if ($SystemModel -like $item) {
                        $ExpandDriverCab = $false
                    }
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "$SystemModel ModelNotLike is evaluated false" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   ModelMatch
            #===================================================================================================
            if ($DriverTask.ModelMatch) {
                $ExpandDriverCab = $false
                foreach ($item in $DriverTask.ModelMatch) {
                    Write-Verbose "Driver CAB Compatible Model: $item"
                    if ($SystemModel -match $item) {$ExpandDriverCab = $true}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "$SystemModel ModelMatch is evaluated false" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   ModelNotMatch
            #===================================================================================================
            if ($DriverTask.ModelNotMatch) {
                foreach ($item in $DriverTask.ModelNotMatch) {
                    Write-Verbose "Driver CAB Not Compatible Model: $item"
                    if ($SystemModel -match $item) {
                        $ExpandDriverCab = $false
                    }
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "$SystemModel ModelNotMatch is evaluated false" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   ModelEq
            #===================================================================================================
            if ($DriverTask.ModelEq) {
                $ExpandDriverCab = $false
                foreach ($item in $DriverTask.ModelEq) {
                    Write-Verbose "Driver CAB Compatible Model: $item"
                    if ($SystemModel -contains $item) {$ExpandDriverCab = $true}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "$SystemModel ModelEq is evaluated false" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   ModelNotEq
            #===================================================================================================
            if ($DriverTask.ModelNotEq) {
                foreach ($item in $DriverTask.ModelNotEq) {
                    Write-Verbose "Driver CAB Not Compatible Model: $item"
                    if ($SystemModel -contains $item) {
                        $ExpandDriverCab = $false
                    }
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "$SystemModel ModelNotEq is evaluated false" -Foregroundcolor DarkGray
                    Continue
                }
            }
            <#         #===================================================================================================
            #   FamilyLike
            #===================================================================================================
            if ($DriverTask.FamilyLike) {
                $ExpandDriverCab = $false
                foreach ($item in $DriverTask.FamilyLike) {
                    Write-Verbose "Driver CAB Compatible Family: $item"
                    if ($SystemFamily -like "*$item*") {$ExpandDriverCab = $true}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "Not compatible with System Family $SystemFamily" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   FamilyNotLike
            #===================================================================================================
            if ($DriverTask.FamilyNotLike) {
                foreach ($item in $DriverTask.FamilyNotLike) {
                    Write-Verbose "Driver CAB Not Compatible Family: $item"
                    if ($SystemFamily -like "*$item*") {$ExpandDriverCab = $false}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "Not compatible with System Family $SystemFamily" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   SkuLike
            #===================================================================================================
            if ($DriverTask.SkuLike) {
                $ExpandDriverCab = $false
                foreach ($item in $DriverTask.SkuLike) {
                    Write-Verbose "Driver CAB Compatible Sku: $item"
                    if ($SystemSku -like "*$item*") {$ExpandDriverCab = $true}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "Not compatible with System Sku $SystemSku" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   SkuNotLike
            #===================================================================================================
            if ($DriverTask.SkuNotLike) {
                foreach ($item in $DriverTask.SkuNotLike) {
                    Write-Verbose "Driver CAB Not Compatible Sku: $item"
                    if ($SystemSku -like "*$item*") {$ExpandDriverCab = $false}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "Not compatible with System Sku $SystemSku" -Foregroundcolor DarkGray
                    Continue
                }
            } #>
            #===================================================================================================
            #   OSInstallationType
            #===================================================================================================
            #TODO
    <#         if ($DriverTask.OSInstallationType) {
                Write-Verbose "Driver InstallationType: $($DriverTask.OSInstallationType)"
                if ($ImageOSInstallationType -notlike "*$($DriverTask.OSInstallationType)*") {
                    Write-Host "Not compatible with Image OS InstallationType $($DriverTask.OSInstallationType)" -Foregroundcolor DarkGray
                    Continue
                }
            } #>
        }
        #===================================================================================================
        #   OSDDriverPnp
        #===================================================================================================
        if (Test-Path $OSDDriverPnp) {
            $ExpandDriverCab = $false
            $HardwareIdMatches = @()
            $OSDPnpFile = @()
            $OSDPnpFile = Import-CliXml -Path "$OSDDriverPnp"
        
            foreach ($PnpDriverId in $OSDPnpFile) {
                $HardwareDescription = $($PnpDriverId.HardwareDescription)
                $HardwareId = $($PnpDriverId.HardwareId)
        
                if ($MyHardware -like "*$HardwareId*") {
                    #Write-Host "$HardwareDescription $HardwareId " -Foregroundcolor Cyan
                    $ExpandDriverCab = $true
                    $HardwareIdMatches += "$HardwareDescription $HardwareId"
                }
            }

            if ($ExpandDriverCab -eq $false) {
                Write-Host "Driver does not support the Hardware in this system" -ForegroundColor DarkGray
                Continue
            }
            if ($HardwareIdMatches) {
                Write-Host "HardwareID Match"
                foreach ($HardwareIdMatch in $HardwareIdMatches) {
                    Write-Host "$($HardwareIdMatch)" -ForegroundColor Cyan
                }
            }
        } else {
            Write-Host "Compatible"
        }
        $ExpandDrivers += $OSDDriver
    }
    #===================================================================================================
    #   ExpandDrivers
    #===================================================================================================
    Write-Host "Expanding Drivers ..." -Foregroundcolor Green
    foreach ($ExpandDriver in $ExpandDrivers) {
        $OSDDriverCab = $ExpandDriver.Name
        $OSDDriverBaseName = $ExpandDriver.BaseName
        $OSDDriverFullName = $ExpandDriver.FullName
        $OSDDriverDirectoryName = $ExpandDriver.DirectoryName

        if (!(Test-Path "$ExpandDriverPath\$OSDDriverBaseName")) {
            New-Item -Path "$ExpandDriverPath\$OSDDriverBaseName" -ItemType Directory -Force | Out-Null
        }
        if ($OSDDriverCab -match '.cab') {
            Write-Host "Expanding CAB $OSDDriverFullName to $ExpandDriverPath\$OSDDriverBaseName" -ForegroundColor Cyan
            Expand -R "$OSDDriverFullName" -F:* "$ExpandDriverPath\$OSDDriverBaseName" | Out-Null
        }
        if ($OSDDriverCab -match '.zip') {
            Write-Host "Expanding ZIP $OSDDriverFullName to $ExpandDriverPath\$OSDDriverBaseName" -ForegroundColor Cyan
            Expand-Archive -Path "$OSDDriverFullName" -DestinationPath "$ExpandDriverPath" -Force
        }
    }
    Stop-Transcript | Out-Null
}