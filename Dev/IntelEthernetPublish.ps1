Clear-Host
Import-Module OSDDrivers -Force
$DriverVersion = '24.1'
$OSDPnpClass = 'Net'

$OSInstallationType = 'Server'
$OSVersionMatch = '10.0'
$OSArch = 'x64'

$OSBuildLE = '17134'
$OSBuildGE = $null
$OSDDriverFile = "D:\OSDDrivers\Package\IntelEthernet\IntelEthernet 24.1 PROAVF x64 S2016"
New-OSDDriverTask -OSDDriverFile "$($OSDDriverFile).cab" -DriverVersion $DriverVersion -OSDPnpClass $OSDPnpClass -OSInstallationType $OSInstallationType -OSVersionMatch $OSVersionMatch -OSArchMatch $OSArch -OSBuildGE $OSBuildGE -OSBuildLE $OSBuildLE
$OSDDriverFile = "D:\OSDDrivers\Package\IntelEthernet\IntelEthernet 24.1 PRO40GB x64 S2016"
New-OSDDriverTask -OSDDriverFile "$($OSDDriverFile).cab" -DriverVersion $DriverVersion -OSDPnpClass $OSDPnpClass -OSInstallationType $OSInstallationType -OSVersionMatch $OSVersionMatch -OSArchMatch $OSArch -OSBuildGE $OSBuildGE -OSBuildLE $OSBuildLE

$OSBuildLE = $null
$OSBuildGE = '17763'
$OSDDriverFile = "D:\OSDDrivers\Package\IntelEthernet\IntelEthernet 24.1 PRO40GB x64 S2019"
New-OSDDriverTask -OSDDriverFile "$($OSDDriverFile).cab" -DriverVersion $DriverVersion -OSDPnpClass $OSDPnpClass -OSInstallationType $OSInstallationType -OSVersionMatch $OSVersionMatch -OSArchMatch $OSArch -OSBuildGE $OSBuildGE -OSBuildLE $OSBuildLE
$OSDDriverFile = "D:\OSDDrivers\Package\IntelEthernet\IntelEthernet 24.1 PROAVF x64 S2019"
New-OSDDriverTask -OSDDriverFile "$($OSDDriverFile).cab" -DriverVersion $DriverVersion -OSDPnpClass $OSDPnpClass -OSInstallationType $OSInstallationType -OSVersionMatch $OSVersionMatch -OSArchMatch $OSArch -OSBuildGE $OSBuildGE -OSBuildLE $OSBuildLE

$OSBuildLE = '17134'
$OSBuildGE = $null

$OSArch = 'x86'
$OSDDriverFile = "D:\OSDDrivers\Package\IntelEthernet\IntelEthernet 24.1 PRO1000 x86 10"
New-OSDDriverTask -OSDDriverFile "$($OSDDriverFile).cab" -DriverVersion $DriverVersion -OSDPnpClass $OSDPnpClass -OSVersionMatch $OSVersionMatch -OSArchMatch $OSArch -OSBuildGE $OSBuildGE -OSBuildLE $OSBuildLE

$OSArch = 'x64'
$OSDDriverFile = "D:\OSDDrivers\Package\IntelEthernet\IntelEthernet 24.1 PRO1000 x64 10"
New-OSDDriverTask -OSDDriverFile "$($OSDDriverFile).cab" -DriverVersion $DriverVersion -OSDPnpClass $OSDPnpClass -OSVersionMatch $OSVersionMatch -OSArchMatch $OSArch -OSBuildGE $OSBuildGE -OSBuildLE $OSBuildLE
$OSDDriverFile = "D:\OSDDrivers\Package\IntelEthernet\IntelEthernet 24.1 PROXGB x64 10"
New-OSDDriverTask -OSDDriverFile "$($OSDDriverFile).cab" -DriverVersion $DriverVersion -OSDPnpClass $OSDPnpClass -OSVersionMatch $OSVersionMatch -OSArchMatch $OSArch -OSBuildGE $OSBuildGE -OSBuildLE $OSBuildLE

$OSBuildLE = $null
$OSBuildGE = '17763'
$OSArch = 'x86'
$OSDDriverFile = "D:\OSDDrivers\Package\IntelEthernet\IntelEthernet 24.1 PRO1000 x86 10.1809"
New-OSDDriverTask -OSDDriverFile "$($OSDDriverFile).cab" -DriverVersion $DriverVersion -OSDPnpClass $OSDPnpClass -OSVersionMatch $OSVersionMatch -OSArchMatch $OSArch -OSBuildGE $OSBuildGE -OSBuildLE $OSBuildLE
$OSArch = 'x64'
$OSDDriverFile = "D:\OSDDrivers\Package\IntelEthernet\IntelEthernet 24.1 PRO1000 x64 10.1809"
New-OSDDriverTask -OSDDriverFile "$($OSDDriverFile).cab" -DriverVersion $DriverVersion -OSDPnpClass $OSDPnpClass -OSVersionMatch $OSVersionMatch -OSArchMatch $OSArch -OSBuildGE $OSBuildGE -OSBuildLE $OSBuildLE
$OSDDriverFile = "D:\OSDDrivers\Package\IntelEthernet\IntelEthernet 24.1 PROXGB x64 10.1809"
New-OSDDriverTask -OSDDriverFile "$($OSDDriverFile).cab" -DriverVersion $DriverVersion -OSDPnpClass $OSDPnpClass -OSVersionMatch $OSVersionMatch -OSArchMatch $OSArch -OSBuildGE $OSBuildGE -OSBuildLE $OSBuildLE

$OSVersionMatch = '6.1'
$OSArch = 'x64'
$OSDDriverFile = "D:\OSDDrivers\Package\IntelEthernet\IntelEthernet 24.1 PROXGB x64 Win7"
New-OSDDriverTask -OSDDriverFile "$($OSDDriverFile).cab" -DriverVersion $DriverVersion -OSDPnpClass $OSDPnpClass -OSVersionMatch $OSVersionMatch -OSArchMatch $OSArch -OSBuildGE $OSBuildGE -OSBuildLE $OSBuildLE
$OSDDriverFile = "D:\OSDDrivers\Package\IntelEthernet\IntelEthernet 24.1 PRO1000 x64 Win7"
New-OSDDriverTask -OSDDriverFile "$($OSDDriverFile).cab" -DriverVersion $DriverVersion -OSDPnpClass $OSDPnpClass -OSVersionMatch $OSVersionMatch -OSArchMatch $OSArch -OSBuildGE $OSBuildGE -OSBuildLE $OSBuildLE
$OSArch = 'x86'
$OSDDriverFile = "D:\OSDDrivers\Package\IntelEthernet\IntelEthernet 24.1 PRO1000 x86 Win7"
New-OSDDriverTask -OSDDriverFile "$($OSDDriverFile).cab" -DriverVersion $DriverVersion -OSDPnpClass $OSDPnpClass -OSVersionMatch $OSVersionMatch -OSArchMatch $OSArch -OSBuildGE $OSBuildGE -OSBuildLE $OSBuildLE
