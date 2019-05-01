function Expand-OSDDrivers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$PathDriverCabs,

        [string]$PathExpandedDrivers = 'C:\Drivers',

        [switch]$GridView,

        [ValidateSet('x64','x86')]
        [string]$SetOSArch,
        [string]$SetOSBuild,
        [ValidateSet('Client','Server')]
        [string]$SetOSInstallationType,
        [ValidateSet('6.1','6.2','6.3','10.0')]
        [string]$SetOSVersion,
        [string]$SetMake,
        [string]$SetModel
    )

    begin {
        #Write-Host '========================================================================================' -ForegroundColor DarkGray
        #Write-Host "$($MyInvocation.MyCommand.Name) BEGIN" -ForegroundColor Green
        $global:OSDDriversVersion = $(Get-Module -Name OSDDrivers | Sort-Object Version | Select-Object Version -Last 1).Version
        Write-Host '========================================================================================' -ForegroundColor DarkGray
        #===================================================================================================
        #   Win32_ComputerSystem
        #===================================================================================================
        $CimCsManufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
        $CimCsModel = (Get-CimInstance -ClassName Win32_ComputerSystem).Model
        $CimCsSystemFamily = (Get-CimInstance -ClassName Win32_ComputerSystem).SystemFamily
        $CimCsSystemSKUNumber = (Get-CimInstance -ClassName Win32_ComputerSystem).SystemSKUNumber

        if ($env:SystemDrive -eq 'X:') {

        } else {
            #===================================================================================================
            #   Win32_OperatingSystem
            #===================================================================================================
            $CimOsCaption = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
            $CimOsVersion = (Get-CimInstance -ClassName Win32_OperatingSystem).Version
            $CimOsBuildNumber = (Get-CimInstance -ClassName Win32_OperatingSystem).BuildNumber
            $CimOsOSArchitecture = (Get-CimInstance -ClassName Win32_OperatingSystem).OSArchitecture
            #===================================================================================================
            #   Registry
            #===================================================================================================
            $RegInstallationType = (Get-ItemProperty 'HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion').InstallationType
        }


        #===================================================================================================
        #   Set
        #===================================================================================================
        if ($SetOSArch -eq 'x64') {$CimOsOSArchitecture = '64-bit'}
        if ($SetOSArch -eq 'x86') {$CimOsOSArchitecture = '32-bit'}
        if ($SetOSBuild) {$CimOsBuildNumber = $SetOSBuild}
        if ($SetOSInstallationType) {$RegInstallationType = $SetOSInstallationType}
        if ($SetOSVersion) {$CimOsVersion = $SetOSVersion}
        if ($SetMake) {$CimCsManufacturer = $SetMake}
        if ($SetModel) {$CimCsModel = $SetModel}
        #===================================================================================================
        #   Inventory
        #===================================================================================================
        Write-Host "Manufacturer: $CimCsManufacturer"
        Write-Host "Model: $CimCsModel"
        Write-Host "SystemFamily: $CimCsSystemFamily"
        Write-Host "SystemSKUNumber: $CimCsSystemSKUNumber"
        Write-Host "Caption: $CimOsCaption"
        Write-Host "Version: $CimOsVersion"
        Write-Host "BuildNumber: $CimOsBuildNumber"
        Write-Host "OSArchitecture: $CimOsOSArchitecture"
        Write-Host "InstallationType: $RegInstallationType"
        #===================================================================================================
        #   Get All Drivers Jsons
        #===================================================================================================
        $OSDDrivers = @()
        $OSDDrivers = Get-OSDDrivers -PathDriverCabs $PathDriverCabs
        #===================================================================================================
    }

    process {
        Write-Host '========================================================================================' -ForegroundColor DarkGray
        #Write-Host "$($MyInvocation.MyCommand.Name) PROCESS" -ForegroundColor Green

        $OSDDriversInventory = (New-OSDDriversInventory -PathExpandedDrivers $PathExpandedDrivers)
        $Hardware = @()
        $Hardware = Import-Clixml -Path "$OSDDriversInventory" | Select-Object -Property DeviceID, Caption

        Write-Host "Processing Driver Cabs ..." -ForegroundColor Cyan

        foreach ($OSDDriver in $OSDDrivers) {
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
                if ($CimOsOSArchitecture -like "*64*" -and $OSDDriver.OSArch -eq 'x86') {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with OSArchitecture $CimOsOSArchitecture" -Foregroundcolor DarkGray
                    Continue
                }
                if ($CimOsOSArchitecture -like "*32*" -and $OSDDriver.OSArch -eq 'x64') {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with OSArchitecture $CimOsOSArchitecture" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   OSVersionMin
            #===================================================================================================
            if ($OSDDriver.OSVersionMin) {
                Write-Verbose "Driver OSVersionMin: $($OSDDriver.OSVersionMin)"
                if ([version]$CimOsVersion -lt [version]$OSDDriver.OSVersionMin) {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with OSVersion $CimOsVersion" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   OSVersionMax
            #===================================================================================================
            if ($OSDDriver.OSVersionMax) {
                Write-Verbose "Driver OSVersionMax: $($OSDDriver.OSVersionMax)"
                if ([version]$CimOsVersion -gt [version]$OSDDriver.OSVersionMax) {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with OSVersion $CimOsVersion" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   OSBuildMin
            #===================================================================================================
            if ($OSDDriver.OSBuildMin) {
                Write-Verbose "Driver OSBuildMin: $($OSDDriver.OSBuildMin)"
                if ([int]$CimOsBuildNumber -lt [int]$OSDDriver.OSBuildMin) {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with OSBuild $CimOsBuildNumber" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   OSBuildMax
            #===================================================================================================
            if ($OSDDriver.OSBuildMax) {
                Write-Verbose "Driver OSBuildMax: $($OSDDriver.OSBuildMax)"
                if ([int]$CimOsBuildNumber -gt [int]$OSDDriver.OSBuildMax) {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with OSBuild $CimOsBuildNumber" -Foregroundcolor DarkGray
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
                    if ($CimCsManufacturer -like "*$item*") {$ExpandDriverCab = $true}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with Manufacturer $CimCsManufacturer" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   MakeNotLike
            #===================================================================================================
            if ($OSDDriver.MakeNotLike) {
                foreach ($item in $OSDDriver.MakeNotLike) {
                    Write-Verbose "Driver CAB Not Compatible Make: $item"
                    if ($CimCsManufacturer -like "*$item*") {$ExpandDriverCab = $false}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with Manufacturer $CimCsManufacturer" -Foregroundcolor DarkGray
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
                    if ($CimCsModel -like "*$item*") {$ExpandDriverCab = $true}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with Model $CimCsModel" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   ModelNotLike
            #===================================================================================================
            if ($OSDDriver.ModelNotLike) {
                foreach ($item in $OSDDriver.ModelNotLike) {
                    Write-Verbose "Driver CAB Not Compatible Model: $item"
                    if ($CimCsModel -like "*$item*") {$ExpandDriverCab = $false}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Host "$($OSDDriver.DriverCabFullName) is not compatible with Model $CimCsModel" -Foregroundcolor DarkGray
                    Continue
                }
            }
            #===================================================================================================
            #   OSInstallationType
            #===================================================================================================
            if ($OSDDriver.OSInstallationType) {
                Write-Verbose "Driver InstallationType: $($OSDDriver.OSInstallationType)"
                if ($RegInstallationType -notlike "*$($OSDDriver.OSInstallationType)*") {
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
                    Write-Host "Missing Driver HardwareID Database $($OSDDriver.DriverPnpFullName)" -Foregroundcolor DarkGray
                    Continue
                }
            }
        }

        if ($ExpandDriverCab -eq $false) {Continue}
        Write-Host "Expanding $($OSDDriver.DriverCabFullName) to $PathExpandedDrivers\$($OSDDriver.TaskName)" -ForegroundColor Cyan
        if (!(Test-Path "$PathExpandedDrivers\$($OSDDriver.TaskName)")) {
            New-Item -Path "$PathExpandedDrivers\$($OSDDriver.TaskName)" -ItemType Directory -Force | Out-Null
        }
        Expand -R "$($OSDDriver.DriverCabFullName)" -F:* "$PathExpandedDrivers\$($OSDDriver.TaskName)" | Out-Null
    }

    end {
        #Write-Host '========================================================================================' -ForegroundColor DarkGray
        #Write-Host "$($MyInvocation.MyCommand.Name) END" -ForegroundColor Green
    }
}