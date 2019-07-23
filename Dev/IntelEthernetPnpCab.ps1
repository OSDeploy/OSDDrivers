Clear-Host
Import-Module OSDDrivers -Force
$IntelEthernets = Get-ChildItem 'D:\OSDDrivers\Expand\IntelEthernet' -Directory | Where {$_.Name -match 'IntelEthernet 24.1 P'}
foreach ($IntelEthernet in $IntelEthernets) {
    Save-OSDDriverPnp -ExpandedDriverPath "$($IntelEthernet.FullName)" -OSDPnpClass Net
    New-OSDDriverCab -ExpandedDriverPath "$($IntelEthernet.FullName)" -PackagePath 'D:\OSDDrivers\Package\IntelEthernet'
}