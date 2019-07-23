$SrcRoot = 'D:\OSDDrivers\Driver\Expand\OSD IntelEthernet 24.1'
$DstRoot = 'D:\OSDDrivers\Driver\Expand'
#===================================================================================================
#   PRO40GB
#===================================================================================================
$Source = "PRO40GB\Winx64\NDIS65\*"
$Destination = 'OSD IntelEthernet 24.1 Pro40GB x64 S2016'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force
Remove-Item -Path "$DstRoot\$Destination\Universal" -Force

$Source = "PRO40GB\Winx64\NDIS68\*"
$Destination = 'OSD IntelEthernet 24.1 Pro40GB x64 S2019'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force
#===================================================================================================
#   PRO1000 x86
#===================================================================================================
$Source = "PRO1000\Win32\NDIS62\*"
$Destination = 'OSD IntelEthernet 24.1 PRO1000 x86 Win7'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force
Remove-Item -Path "$DstRoot\$Destination\WinPE" -Force

$Source = "PRO1000\Win32\NDIS62\WinPE\*"
$Destination = 'OSD IntelEthernet 24.1 PRO1000 x86 WinPE3'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force

<# $Source = "PRO1000\Win32\NDIS63\*"
$Destination = 'OSD IntelEthernet 24.1 PRO1000 x86 Win8'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force
Remove-Item -Path "$DstRoot\$Destination\WinPE" -Force

$Source = "PRO1000\Win32\NDIS63\WinPE\*"
$Destination = 'OSD IntelEthernet 24.1 PRO1000 x86 WinPE4'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force

$Source = "PRO1000\Win32\NDIS64\*"
$Destination = 'OSD IntelEthernet 24.1 PRO1000 x86 Win8.1'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force
Remove-Item -Path "$DstRoot\$Destination\WinPE" -Force

$Source = "PRO1000\Win32\NDIS64\WinPE\*"
$Destination = 'OSD IntelEthernet 24.1 PRO1000 x86 WinPE5'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force #>

$Source = "PRO1000\Win32\NDIS65\*"
$Destination = 'OSD IntelEthernet 24.1 PRO1000 x86 10'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force
Remove-Item -Path "$DstRoot\$Destination\Universal" -Force
Remove-Item -Path "$DstRoot\$Destination\WinPE" -Force

$Source = "PRO1000\Win32\NDIS65\WinPE\*"
$Destination = 'OSD IntelEthernet 24.1 PRO1000 x86 WinPE10'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force

$Source = "PRO1000\Win32\NDIS68\*"
$Destination = 'OSD IntelEthernet 24.1 PRO1000 x86 10.1809'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force
Remove-Item -Path "$DstRoot\$Destination\WinPE" -Force

$Source = "PRO1000\Win32\NDIS68\WinPE\*"
$Destination = 'OSD IntelEthernet 24.1 PRO1000 x86 WinPE10.1809'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force
#===================================================================================================
#   PRO1000 x64
#===================================================================================================
$Source = "PRO1000\Winx64\NDIS62\*"
$Destination = 'OSD IntelEthernet 24.1 PRO1000 x64 Win7'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force

<# $Source = "PRO1000\Winx64\NDIS63\*"
$Destination = 'OSD IntelEthernet 24.1 PRO1000 x64 Win8'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force

$Source = "PRO1000\Winx64\NDIS64\*"
$Destination = 'OSD IntelEthernet 24.1 PRO1000 x64 Win8.1'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force #>

$Source = "PRO1000\Winx64\NDIS65\*"
$Destination = 'OSD IntelEthernet 24.1 PRO1000 x64 10'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force
Remove-Item -Path "$DstRoot\$Destination\Universal" -Force

$Source = "PRO1000\Winx64\NDIS68\*"
$Destination = 'OSD IntelEthernet 24.1 PRO1000 x64 10.1809'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force
#===================================================================================================
#   PROAVF x64
#===================================================================================================
$Source = "PROAVF\Winx64\NDIS65\*"
$Destination = 'OSD IntelEthernet 24.1 PROAVF x64 S2016'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force

$Source = "PROAVF\Winx64\NDIS68\*"
$Destination = 'OSD IntelEthernet 24.1 PROAVF x64 S2019'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force
#===================================================================================================
#   PROXGB x86
#===================================================================================================
$Source = "PROXGB\Win32\NDIS62\WinPE\*"
$Destination = 'OSD IntelEthernet 24.1 PROXGB x86 WinPE3'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force

$Source = "PROXGB\Win32\NDIS65\WinPE\*"
$Destination = 'OSD IntelEthernet 24.1 PROXGB x86 WinPE10'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force

$Source = "PROXGB\Win32\NDIS68\WinPE\*"
$Destination = 'OSD IntelEthernet 24.1 PROXGB x86 WinPE10 1809'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force
#===================================================================================================
#   PROXGB x64
#===================================================================================================
$Source = "PROXGB\Winx64\NDIS62\*"
$Destination = 'OSD IntelEthernet 24.1 PROXGB x64 Win7'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force
Remove-Item -Path "$DstRoot\$Destination\WinPE" -Force

$Source = "PROXGB\Winx64\NDIS62\WinPE\ixe62x64.zip"
$Destination = 'OSD IntelEthernet 24.1 PROXGB x64 WinPE3'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Expand-Archive -Path "$SrcRoot\$Source" -DestinationPath "$DstRoot\$Destination" -Force

$Source = "PROXGB\Winx64\NDIS65\*"
$Destination = 'OSD IntelEthernet 24.1 PROXGB x64 10'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force
Remove-Item -Path "$DstRoot\$Destination\Universal" -Force

<# $Source = "PROXGB\Winx64\NDIS65\*"
$Destination = 'OSD IntelEthernet 24.1 PROXGB x64 S2016'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force
Remove-Item -Path "$DstRoot\$Destination\Universal" -Force #>

$Source = "PROXGB\Winx64\NDIS68\*"
$Destination = 'OSD IntelEthernet 24.1 PROXGB x64 10.1809'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force

<# $Source = "PROXGB\Winx64\NDIS68\*"
$Destination = 'OSD IntelEthernet 24.1 PROXGB x64 S2019'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force

$Source = "PROXGB\Winx64\NDIS68\*"
$Destination = 'OSD IntelEthernet 24.1 PROXGB x64 WinPE10 1809'
New-Item "$DstRoot\$Destination" -ItemType Directory -Force | Out-Null
Copy-Item "$SrcRoot\$Source" -Destination "$DstRoot\$Destination" -Force #>