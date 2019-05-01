function Expand-OSDDrivers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$OSDDriverRepository,

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
        Write-Host '========================================================================================' -ForegroundColor DarkGray
        Write-Host "$($MyInvocation.MyCommand.Name) BEGIN" -ForegroundColor Green
        $global:OSDDriversVersion = $(Get-Module -Name OSDDrivers | Sort-Object Version | Select-Object Version -Last 1).Version
        Write-Host '========================================================================================' -ForegroundColor DarkGray
        #===================================================================================================
        #   Win32_ComputerSystem
        #===================================================================================================
        $CimCsManufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
        $CimCsModel = (Get-CimInstance -ClassName Win32_ComputerSystem).Model
        $CimCsSystemFamily = (Get-CimInstance -ClassName Win32_ComputerSystem).SystemFamily
        $CimCsSystemSKUNumber = (Get-CimInstance -ClassName Win32_ComputerSystem).SystemSKUNumber
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
        $OSDDrivers = Get-OSDDrivers -OSDDriverRepository $OSDDriverRepository
        #===================================================================================================
    }

    process {
        Write-Host '========================================================================================' -ForegroundColor DarkGray
        #Write-Host "$($MyInvocation.MyCommand.Name) PROCESS" -ForegroundColor Green

        foreach ($OSDDriver in $OSDDrivers) {
            Write-Host ""
            Write-Host "$($OSDDriver.DriverCabFullName)"
            $ExpandDriverCab = $true
            #===================================================================================================
            #   CAB Ready
            #===================================================================================================
            if ($OSDDriver.DriverCab -eq 'Ready') {
            } else {
                Write-Warning "Missing Driver CAB: $($OSDDriver.DriverCabFullName)"
                Continue
            }
            #===================================================================================================
            #   OSArch
            #===================================================================================================
            if ($OSDDriver.OSArch) {
                if ($CimOsOSArchitecture -like "*64*" -and $OSDDriver.OSArch -eq 'x86') {
                    Write-Verbose "OSArchitecture $CimOsOSArchitecture is not compatible"
                    Continue
                }
                if ($CimOsOSArchitecture -like "*32*" -and $OSDDriver.OSArch -eq 'x64') {
                    Write-Verbose "OSArchitecture $CimOsOSArchitecture is not compatible"
                    Continue
                }
            }
            #===================================================================================================
            #   OSVersionMin
            #===================================================================================================
            if ($OSDDriver.OSVersionMin) {
                Write-Verbose "OSVersionMin: $($OSDDriver.OSVersionMin)"
                if ([version]$CimOsVersion -lt [version]$OSDDriver.OSVersionMin) {
                    Write-Verbose "OSVersion $CimOsVersion is not compatible"
                    Continue
                }
            }
            #===================================================================================================
            #   OSVersionMax
            #===================================================================================================
            if ($OSDDriver.OSVersionMax) {
                #Write-Host "OSVersionMax: $($OSDDriver.OSVersionMax)" -ForegroundColor DarkGray
                if ([version]$CimOsVersion -gt [version]$OSDDriver.OSVersionMax) {
                    Write-Verbose "OSVersion $CimOsVersion is not compatible"
                    Continue
                }
            }
            #===================================================================================================
            #   OSBuildMin
            #===================================================================================================
            if ($OSDDriver.OSBuildMin) {
                #Write-Host "OSBuildMin: $($OSDDriver.OSBuildMin)" -ForegroundColor DarkGray
                if ([int]$CimOsBuildNumber -lt [int]$OSDDriver.OSBuildMin) {
                    Write-Verbose "OSBuild $CimOsBuildNumber is not compatible"
                    Continue
                }
            }
            #===================================================================================================
            #   OSBuildMax
            #===================================================================================================
            if ($OSDDriver.OSBuildMax) {
                #Write-Host "OSBuildMin: $($OSDDriver.OSBuildMin)" -ForegroundColor DarkGray
                if ([int]$CimOsBuildNumber -gt [int]$OSDDriver.OSBuildMax) {
                    Write-Verbose "OSBuild $CimOsBuildNumber is not compatible"
                    Continue
                }
            }
            #===================================================================================================
            #   MakeLike
            #===================================================================================================
            if ($OSDDriver.MakeLike) {
                $ExpandDriverCab = $false
                foreach ($item in $OSDDriver.MakeLike) {
                    #Write-Host "Driver CAB Compatible Make: $item" -ForegroundColor DarkGray
                    if ($CimCsManufacturer -like "*$item*") {$ExpandDriverCab = $true}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Verbose "Manufacturer $CimCsManufacturer is not compatible"
                    Continue
                }
            }
            #===================================================================================================
            #   MakeNotLike
            #===================================================================================================
            if ($OSDDriver.MakeNotLike) {
                foreach ($item in $OSDDriver.MakeNotLike) {
                    #Write-Host "Driver CAB Not Compatible Make: $item" -ForegroundColor DarkGray
                    if ($CimCsManufacturer -like "*$item*") {$ExpandDriverCab = $false}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Verbose "Manufacturer $CimCsManufacturer is not compatible"
                    Continue
                }
            }
            #===================================================================================================
            #   ModelLike
            #===================================================================================================
            if ($OSDDriver.ModelLike) {
                $ExpandDriverCab = $false
                foreach ($item in $OSDDriver.ModelLike) {
                    #Write-Host "Driver CAB Compatible Model: $item" -ForegroundColor DarkGray
                    if ($CimCsModel -like "*$item*") {$ExpandDriverCab = $true}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Verbose "Model $CimCsModel is not compatible"
                    Continue
                }
            }
            #===================================================================================================
            #   ModelNotLike
            #===================================================================================================
            if ($OSDDriver.ModelNotLike) {
                foreach ($item in $OSDDriver.ModelNotLike) {
                    #Write-Host "Driver CAB Not Compatible Model: $item" -ForegroundColor DarkGray
                    if ($CimCsModel -like "*$item*") {$ExpandDriverCab = $false}
                }
                if ($ExpandDriverCab -eq $false) {
                    Write-Verbose "Model $CimCsModel is not compatible"
                    Continue
                }
            }
            #===================================================================================================
            #   OSType
            #===================================================================================================
            if ($OSDDriver.OSType) {
                if ($RegInstallationType -notlike "*$($OSDDriver.OSType)*") {
                    Write-Verbose "OS InstallationType $($OSDDriver.OSType) is not compatible"
                    Continue
                }
            }
            #===================================================================================================
            #   Hardware
            #===================================================================================================




            if ($ExpandDriverCab -eq $false) {Continue}
            Write-Host "Expanding Driver CAB $($OSDDriver.DriverCabFullName)" -ForegroundColor Cyan
        }






<#         $Hardware = @()
        $Hardware = Import-Clixml -Path "C:\Drivers\Hardware.xml" | Select-Object -Property DeviceID, Caption
    
        $AllDrivers = @()
        $DriverXmls = Get-ChildItem 'D:\CoreDivers\Display Intel' *.pnpxml
        
        foreach ($DriverXml in $DriverXmls) {
            $AllDrivers += Import-CliXml -Path "$($DriverXml.FullName)"
        }
    
        foreach ($Driver in $AllDrivers) {
            $HardwareDescription = $($Driver.HardwareDescription)
            $HardwareId = $($Driver.HardwareId)
    
            if ($Hardware -like "*$HardwareId*") {
            Write-Host "Matching Hardware: $HardwareDescription $HardwareId" -Foregroundcolor Green}
        } #>
    }

    end {
        Write-Host '========================================================================================' -ForegroundColor DarkGray
        Write-Host "$($MyInvocation.MyCommand.Name) END" -ForegroundColor Green
    }
}