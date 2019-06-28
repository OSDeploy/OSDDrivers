function Expand-OSDDrivers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$PackagePath,

        [string]$PathDrivers,

        [switch]$GridView,

        [string]$SetMake,
        [string]$SetModel,

        [ValidateSet('x64','x86')]
        [string]$SetOSArch,

        [string]$SetOSBuild,

        [ValidateSet('Client','Server')]
        [string]$SetOSInstallationType,

        [ValidateSet('6.1','6.2','6.3','10.0')]
        [string]$SetOSVersion
    )

    begin {
        #===================================================================================================
        #   Module Version
        #===================================================================================================
        $global:OSDDriversVersion = $(Get-Module -Name OSDDrivers | Sort-Object Version | Select-Object Version -Last 1).Version
        #===================================================================================================
        #   Microsoft.SMS.TSEnvironment
        #===================================================================================================
        try {
            $TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to construct Microsoft.SMS.TSEnvironment object"
        }
        #===================================================================================================
        #   Get All Drivers Jsons
        #===================================================================================================
        $OSDDrivers = @()
        $OSDDrivers = Get-OSDDrivers -PackagePath $PackagePath
        #===================================================================================================
    }

    process {
        Write-Host '========================================================================================' -ForegroundColor DarkGray
        #Write-Host "$($MyInvocation.MyCommand.Name) PROCESS" -ForegroundColor Green

        #===================================================================================================
        #   Gather
        #===================================================================================================
        $IsWinPE = $env:SystemDrive -eq 'X:'
        if ($TSEnv) {$OSDisk = $TSEnv.Value('OSDisk')}
        #===================================================================================================
        #   PathDrivers
        #===================================================================================================
        if ($IsWinPE) {
            if (!$PathDrivers) {
                if ($OSDisk) {
                    $PathDrivers = $OSDisk + '\Drivers'
                } else {
                    $PathDrivers = 'C:\Drivers'
                }
            }
        } else {
            if (!$PathDrivers) {
                $PathDrivers = $env:SystemDrive + '\Drivers'
            }
        }
        #===================================================================================================
        #   Validate
        #===================================================================================================
        if (-not (Test-Path "$PathDrivers")) {
            try {
                New-Item -Path "$PathDrivers\" -ItemType Directory -Force | Out-Null
            }
            catch {
                Write-Warning "Could not validate $PathDrivers ... Exiting"
                Start-Sleep 10
                Exit 0
            }
        }
        #===================================================================================================
        #   Start-Transcript
        #===================================================================================================
        $LogName = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-OSDDrivers.log"
        Start-Transcript -Path "$PathDrivers\$LogName"
        #===================================================================================================
        #   ImageOSArchitecture
        #===================================================================================================
        if ($TSEnv) {$ImageProcessor = $TSEnv.Value('ImageProcessor')}

        if ($SetOSArch) {
            Write-Verbose "Reading value from Parameter" -Verbose
            $ImageOSArchitecture = $SetOSArch
        } elseif ($ImageProcessor) {
            Write-Verbose "Reading value from TSEnv" -Verbose
            $ImageOSArchitecture = $ImageProcessor
        } else {
            Write-Verbose "Reading value from Win32_OperatingSystem" -Verbose
            $CimOSArchitecture = (Get-CimInstance -ClassName Win32_OperatingSystem).OSArchitecture
            if ($CimOSArchitecture -like "*64*") {$ImageOSArchitecture = 'x64'}
            if ($CimOSArchitecture -like "*32*") {$ImageOSArchitecture = 'x86'}
        }
        Write-Verbose "Image OSArchitecture: $ImageOSArchitecture" -Verbose
        #===================================================================================================
        #   ImageOSBuild
        #===================================================================================================
        if ($TSEnv) {$ImageBuild = $TSEnv.Value('ImageBuild')}

        if ($SetOSBuild) {
            Write-Verbose "Reading value from Parameter" -Verbose
            $ImageOSBuild = $SetOSBuild
        } elseif ($ImageBuild) {
            Write-Verbose "Reading value from TSEnv" -Verbose
            $ImageOSBuild = ([version]$ImageBuild).Build
        } else {
            Write-Verbose "Reading value from Win32_OperatingSystem" -Verbose
            $ImageOSBuild = (Get-CimInstance -ClassName Win32_OperatingSystem).BuildNumber
        }
        Write-Verbose "Image OSBuild: $ImageOSBuild" -Verbose
        #===================================================================================================
        #   ImageOSVersion
        #===================================================================================================
        if ($SetOSVersion) {
            Write-Verbose "Reading value from Parameter" -Verbose
            $ImageOSVersion = $SetOSVersion
        } elseif ($ImageBuild) {
            Write-Verbose "Reading value from TSEnv" -Verbose
            $ImageOSVersion = "$(([version]$ImageBuild).Major).$(([version]$ImageBuild).Minor)"
        } else {
            Write-Verbose "Reading value from Win32_OperatingSystem" -Verbose
            $CimOSVersion = (Get-CimInstance -ClassName Win32_OperatingSystem).Version
            $ImageOSVersion = "$(([version]$CimOSVersion).Major).$(([version]$CimOSVersion).Minor)"
        }
        Write-Verbose "Image OSVersion: $ImageOSVersion" -Verbose
        #===================================================================================================
        #   ImageOSInstallationType
        #===================================================================================================
        if ($TSEnv) {$TaskSequenceTemplate = $TSEnv.Value('TaskSequenceTemplate')}

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
        Write-Verbose "Image OSInstallationType: $ImageOSInstallationType" -Verbose
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
        Write-Verbose "System Family: $SystemFamily" -Verbose

        $SystemSKUNumber = (Get-CimInstance -ClassName Win32_ComputerSystem).SystemSKUNumber
        Write-Verbose "System SKUNumber: $SystemSKUNumber" -Verbose
        #===================================================================================================
        #   New-OSDDriversInventory
        #===================================================================================================
        $OSDDriversInventory = (New-OSDDriversInventory -PathDrivers $PathDrivers)
        $Hardware = @()
        $Hardware = Import-Clixml -Path "$OSDDriversInventory" | Select-Object -Property DeviceID, Caption
        #===================================================================================================
        #   Expand-OSDDrivers
        #===================================================================================================
        Write-Host "Processing Driver Cabs ..." -ForegroundColor Cyan

        foreach ($OSDDriver in $OSDDrivers) {
            #Write-Host ""
            #Write-Host "$($OSDDriver.DriverCabFullName)"
            $ExpandDriverCab = $true
            #===================================================================================================
            #   CAB Ready
            #===================================================================================================
            if ($OSDDriver.DriverCab -eq 'Ready') {
            } else {
                Write-Host "Missing Driver CAB $($OSDDriver.DriverCabFullName)" -Foregroundcolor DarkGray
                Continue
            }
            #===================================================================================================
            #   OSArch
            #===================================================================================================
            if ($OSDDriver.OSArch) {
                Write-Verbose "Driver OSArch: $($OSDDriver.OSArch)"
                if ($ImageOSArchitecture -like "*64*" -and $OSDDriver.OSArch -eq 'x86') {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with Image OSArchitecture $ImageOSArchitecture" -Foregroundcolor DarkGray
                    Continue
                }
                if ($ImageOSArchitecture -like "*32*" -and $OSDDriver.OSArch -eq 'x64') {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with Image OSArchitecture $ImageOSArchitecture" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   OSVersionMin
            #===================================================================================================
            if ($OSDDriver.OSVersionMin) {
                Write-Verbose "Driver OSVersionMin: $($OSDDriver.OSVersionMin)"
                if ([version]$ImageOSVersion -lt [version]$OSDDriver.OSVersionMin) {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with Image OSVersion $ImageOSVersion" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   OSVersionMax
            #===================================================================================================
            if ($OSDDriver.OSVersionMax) {
                Write-Verbose "Driver OSVersionMax: $($OSDDriver.OSVersionMax)"
                if ([version]$ImageOSVersion -gt [version]$OSDDriver.OSVersionMax) {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with Image OSVersion $ImageOSVersion" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   OSBuildMin
            #===================================================================================================
            if ($OSDDriver.OSBuildMin) {
                Write-Verbose "Driver OSBuildMin: $($OSDDriver.OSBuildMin)"
                if ([int]$ImageOSBuild -lt [int]$OSDDriver.OSBuildMin) {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with Image OSBuild $ImageOSBuild" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   OSBuildMax
            #===================================================================================================
            if ($OSDDriver.OSBuildMax) {
                Write-Verbose "Driver OSBuildMax: $($OSDDriver.OSBuildMax)"
                if ([int]$ImageOSBuild -gt [int]$OSDDriver.OSBuildMax) {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with Image OSBuild $ImageOSBuild" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   MakeLike
            #===================================================================================================
            if ($OSDDriver.MakeLike) {
                $ExpandDriverCab = $false
                foreach ($item in $OSDDriver.MakeLike) {
                    Write-Verbose "Driver CAB Compatible Make: $item"
                    if ($SystemMake -like "*$item*") {$ExpandDriverCab = $true}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with System Manufacturer $SystemMake" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   MakeNotLike
            #===================================================================================================
            if ($OSDDriver.MakeNotLike) {
                foreach ($item in $OSDDriver.MakeNotLike) {
                    Write-Verbose "Driver CAB Not Compatible Make: $item"
                    if ($SystemMake -like "*$item*") {$ExpandDriverCab = $false}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with System Manufacturer $SystemMake" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   ModelLike
            #===================================================================================================
            if ($OSDDriver.ModelLike) {
                $ExpandDriverCab = $false
                foreach ($item in $OSDDriver.ModelLike) {
                    Write-Verbose "Driver CAB Compatible Model: $item"
                    if ($SystemModel -like "*$item*") {$ExpandDriverCab = $true}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with System Model $SystemModel" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   ModelNotLike
            #===================================================================================================
            if ($OSDDriver.ModelNotLike) {
                foreach ($item in $OSDDriver.ModelNotLike) {
                    Write-Verbose "Driver CAB Not Compatible Model: $item"
                    if ($SystemModel -like "*$item*") {$ExpandDriverCab = $false}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with System Model $SystemModel" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   OSInstallationType
            #===================================================================================================
            if ($OSDDriver.OSInstallationType) {
                Write-Verbose "Driver InstallationType: $($OSDDriver.OSInstallationType)"
                if ($ImageOSInstallationType -notlike "*$($OSDDriver.OSInstallationType)*") {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with Image OS InstallationType $($OSDDriver.OSInstallationType)" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   Hardware
            #===================================================================================================
            if ($OSDDriver.DriverPnpFullName) {
                if (Test-Path "$($OSDDriver.DriverPnpFullName)") {
                    Write-Verbose "Driver HardwareID Database: $($OSDDriver.DriverPnpFullName)"
                    $ExpandDriverCab = $false
                    $PnpCabDrivers = @()
                    $PnpCabDrivers = Import-CliXml -Path "$($OSDDriver.DriverPnpFullName)"
                
                    foreach ($PnpDriverId in $PnpCabDrivers) {
                        $HardwareDescription = $($PnpDriverId.HardwareDescription)
                        $HardwareId = $($PnpDriverId.HardwareId)
                
                        if ($Hardware -like "*$HardwareId*") {
                            Write-Host "$($OSDDriver.DriverCabFullName) HardwareID Match: $HardwareDescription $HardwareId" -Foregroundcolor Green
                            $ExpandDriverCab = $true
                        }
                    }

                    if ($ExpandDriverCab -eq $false) {
                        Write-Host "$($OSDDriver.DriverCabFullName) is not compatbile with the PNPID Hardware on this system" -Foregroundcolor DarkGray
                        Continue
                    }

                } else {
                    #Write-Host "Missing Driver HardwareID Database $($OSDDriver.DriverPnpFullName)" -Foregroundcolor DarkGray
                    #Continue
                }
            }
            if ($ExpandDriverCab -eq $false) {Continue}
            if (!(Test-Path "$PathDrivers\$($OSDDriver.TaskName)")) {
                New-Item -Path "$PathDrivers\$($OSDDriver.TaskName)" -ItemType Directory -Force | Out-Null
            }
            Write-Host "Expanding $($OSDDriver.DriverCabFullName) to $PathDrivers\$($OSDDriver.TaskName)" -ForegroundColor Cyan
            Expand -R "$($OSDDriver.DriverCabFullName)" -F:* "$PathDrivers\$($OSDDriver.TaskName)" | Out-Null
        }
    }

    end {
        #Write-Host '========================================================================================' -ForegroundColor DarkGray
        #Write-Host "$($MyInvocation.MyCommand.Name) END" -ForegroundColor Green
        Stop-Transcript
    }
}