function Expand-OSDDrivers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$PathDriverPackages,

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
        #Write-Host '========================================================================================' -ForegroundColor DarkGray
        #Write-Host "$($MyInvocation.MyCommand.Name) BEGIN" -ForegroundColor Green
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
        $OSDDrivers = Get-OSDDrivers -PathDriverPackages $PathDriverPackages
        #===================================================================================================
    }

    process {
        Write-Host '========================================================================================' -ForegroundColor DarkGray
        #Write-Host "$($MyInvocation.MyCommand.Name) PROCESS" -ForegroundColor Green

        #===================================================================================================
        #   PathDrivers
        #===================================================================================================
        if (-not ($PathDrivers)) {
            $OSDDriversDrive = $null
            if ($TSEnv) {
                $OSDDriversDrive = $TSEnv.Value("OSDisk")
                if ($null -eq $OSDDriversDrive) {$OSDDriversDrive = $TSEnv.Value("OSDTargetDriveCache")}
            }

            if ($null -eq $OSDDriversDrive) {$OSDDriversDrive = $env:SystemDrive}
            if ($OSDDriversDrive -eq 'X:') {$OSDDriversDrive = 'C:'}

            if (-not (Test-Path "$OSDDriversDrive\")) {
                Write-Warning "Could not locate a Drive to Expand-OSDDrivers ... Exiting"
                Start-Sleep 10
                Exit 0
            }
            $PathDrivers = "$OSDDriversDrive\Drivers"
        }

        if (-not (Test-Path "$PathDrivers")) {
            try {
                New-Item -Path "$PathDrivers\" -ItemType Directory -Force | Out-Null
            }
            catch {
                Write-Warning "Could not locate a Drive to Expand-OSDDrivers ... Exiting"
                Start-Sleep 10
                Exit 0
            }
        }
        #===================================================================================================
        #   Start-Transcript
        #===================================================================================================
        $LogName = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-OSDDrivers.log"
        Start-Transcript -Path "$PathDrivers\$LogName"
        Write-Verbose "PathDrivers: $PathDrivers" -Verbose
        #===================================================================================================
        #   OSDArch
        #===================================================================================================
        if ($TSEnv) {
            $OSDArch = $TSEnv.Value("ImageProcessor")
        } else {
            $CimOSArchitecture = (Get-CimInstance -ClassName Win32_OperatingSystem).OSArchitecture
            if ($CimOSArchitecture -like "*64*") {$OSDArch = 'x64'}
            if ($CimOSArchitecture -like "*32*") {$OSDArch = 'x86'}
        }
        if ($SetOSArch) {$OSDArch = $SetOSArch}
        if ($null -eq $OSDArch) {$OSDArch = 'x64'}
        Write-Verbose "Image OSDArch: $OSDArch" -Verbose
        #===================================================================================================
        #   OSDVersion
        #===================================================================================================
        if ($TSEnv) {
            $TSEnvImageBuild = $TSEnv.Value("ImageBuild")
            $OSDVersion = "$(([version]$TSEnvImageBuild).Major).$(([version]$TSEnvImageBuild).Minor)"
        } else {
            $CimOSVersion = (Get-CimInstance -ClassName Win32_OperatingSystem).Version
            $OSDVersion = "$(([version]$CimOSVersion).Major).$(([version]$CimOSVersion).Minor)"
        }
        if ($SetOSVersion) {$OSDVersion = $SetOSVersion}
        if ($null -eq $SetOSVersion) {$SetOSVersion = '10.0'}
        Write-Verbose "Image OSDVersion: $OSDVersion" -Verbose
        #===================================================================================================
        #   OSDBuild
        #===================================================================================================
        if ($TSEnv) {
            $TSEnvImageBuild = $TSEnv.Value("ImageBuild")
            $OSDBuild = ([version]$TSEnvImageBuild).Build
        } else {
            $OSDBuild = (Get-CimInstance -ClassName Win32_OperatingSystem).BuildNumber
        }
        if ($SetOSBuild) {$OSDBuild = $SetOSBuild}
        if ($null -eq $SetOSBuild) {$SetOSBuild = '17763'}
        Write-Verbose "Image OSDBuild: $OSDBuild" -Verbose
        #===================================================================================================
        #   OSDInstallationType
        #===================================================================================================
        if ($TSEnv) {
            $OSDInstallationType = $TSEnv.Value("TaskSequenceTemplate")
            if ($OSDInstallationType -like "*Client*") {$OSDInstallationType = 'Client'}
            if ($OSDInstallationType -like "*Server*") {$OSDInstallationType = 'Server'}
        } elseif ($env:SystemDrive -eq 'X:') {
            $OSDInstallationType = 'Client'
        } else {
            $OSDInstallationType = (Get-ItemProperty 'HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion').InstallationType
        }

        if ($SetOSInstallationType) {$OSDInstallationType = $SetOSInstallationType}
        if ($null -eq $OSDInstallationType) {$OSDInstallationType = 'Client'}
        if ((-not($OSDInstallationType -eq 'Client')) -or (-not($OSDInstallationType -eq 'Server'))) {
            $OSDInstallationType = 'Client'
        }
        Write-Verbose "Image OSDInstallationType: $OSDInstallationType" -Verbose
        #===================================================================================================
        #   OSDMake
        #===================================================================================================
        if ($TSEnv) {
            $OSDMake = $TSEnv.Value("Make")
        } else {
            $OSDMake = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
        }
        if ($SetMake) {$OSDMake = $SetMake}
        if ($null -eq $OSDMake) {$OSDMake = 'Microsoft'}
        Write-Verbose "System OSDMake: $OSDMake" -Verbose
        #===================================================================================================
        #   OSDModel
        #===================================================================================================
        if ($TSEnv) {
            $OSDModel = $TSEnv.Value("Model")
        } else {
            $OSDModel = (Get-CimInstance -ClassName Win32_ComputerSystem).Model
        }
        if ($SetModel) {$OSDModel = $SetModel}
        if ($null -eq $OSDModel) {$OSDModel = 'Virtual Machine'}
        Write-Verbose "System OSDModel: $OSDModel" -Verbose
        #===================================================================================================
        #   Other
        #===================================================================================================
        $SystemFamily = (Get-CimInstance -ClassName Win32_ComputerSystem).SystemFamily
        Write-Verbose "System SystemFamily: $SystemFamily" -Verbose
        $SystemSKUNumber = (Get-CimInstance -ClassName Win32_ComputerSystem).SystemSKUNumber
        Write-Verbose "System SystemSKUNumber: $SystemSKUNumber" -Verbose
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
                if ($OSDArch -like "*64*" -and $OSDDriver.OSArch -eq 'x86') {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with OSArchitecture $OSDArch" -Foregroundcolor DarkGray
                    Continue
                }
                if ($OSDArch -like "*32*" -and $OSDDriver.OSArch -eq 'x64') {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with OSArchitecture $OSDArch" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   OSVersionMin
            #===================================================================================================
            if ($OSDDriver.OSVersionMin) {
                Write-Verbose "Driver OSVersionMin: $($OSDDriver.OSVersionMin)"
                if ([version]$OSDVersion -lt [version]$OSDDriver.OSVersionMin) {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with OSVersion $OSDVersion" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   OSVersionMax
            #===================================================================================================
            if ($OSDDriver.OSVersionMax) {
                Write-Verbose "Driver OSVersionMax: $($OSDDriver.OSVersionMax)"
                if ([version]$OSDVersion -gt [version]$OSDDriver.OSVersionMax) {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with OSVersion $OSDVersion" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   OSBuildMin
            #===================================================================================================
            if ($OSDDriver.OSBuildMin) {
                Write-Verbose "Driver OSBuildMin: $($OSDDriver.OSBuildMin)"
                if ([int]$OSDBuild -lt [int]$OSDDriver.OSBuildMin) {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with OSBuild $OSDBuild" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   OSBuildMax
            #===================================================================================================
            if ($OSDDriver.OSBuildMax) {
                Write-Verbose "Driver OSBuildMax: $($OSDDriver.OSBuildMax)"
                if ([int]$OSDBuild -gt [int]$OSDDriver.OSBuildMax) {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with OSBuild $OSDBuild" -Foregroundcolor DarkGray
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
                    if ($OSDMake -like "*$item*") {$ExpandDriverCab = $true}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with Manufacturer $OSDMake" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   MakeNotLike
            #===================================================================================================
            if ($OSDDriver.MakeNotLike) {
                foreach ($item in $OSDDriver.MakeNotLike) {
                    Write-Verbose "Driver CAB Not Compatible Make: $item"
                    if ($OSDMake -like "*$item*") {$ExpandDriverCab = $false}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with Manufacturer $OSDMake" -Foregroundcolor DarkGray
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
                    if ($OSDModel -like "*$item*") {$ExpandDriverCab = $true}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with Model $OSDModel" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   ModelNotLike
            #===================================================================================================
            if ($OSDDriver.ModelNotLike) {
                foreach ($item in $OSDDriver.ModelNotLike) {
                    Write-Verbose "Driver CAB Not Compatible Model: $item"
                    if ($OSDModel -like "*$item*") {$ExpandDriverCab = $false}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with Model $OSDModel" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   OSInstallationType
            #===================================================================================================
            if ($OSDDriver.OSInstallationType) {
                Write-Verbose "Driver InstallationType: $($OSDDriver.OSInstallationType)"
                if ($OSDInstallationType -notlike "*$($OSDDriver.OSInstallationType)*") {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with OS InstallationType $($OSDDriver.OSInstallationType)" -Foregroundcolor DarkGray
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
                        Write-Host "$($OSDDriver.DriverCabFullName) is not compatbile with the Hardware on this system" -Foregroundcolor DarkGray
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