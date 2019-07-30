<#
.LINK
    https://www.osdeploy.com/psmodule/osdrivers/
.SYNOPSIS
    Creates a CAB file from a Directory or Child Directories
.DESCRIPTION
    Creates a CAB file from a Directory or Child Directories
.PARAMETER Path
    Directory to create the CAB from
.PARAMETER HighCompression
    Forces LZX High Compression (Slower).  Unchecked is MSZIP Fast Compression
.PARAMETER MakeCABsFromSubDirs
    Creates CAB files from Path Subdirectories
.EXAMPLE
    New-AutoDriverCabFile -Path C:\Temp\Dell\LatitudeE10_A01
    Creates MSZIP Fast Compression CAB from of C:\Temp\Dell\LatitudeE10_A01
.EXAMPLE
    New-AutoDriverCabFile -Path C:\Temp\Dell -HighCompression -MakeCABsFromSubDirs
    Creates LZX High Compression CABS from all subdirectories of C:\Temp\Dell
.NOTES
    NAME:	New-AutoDriverCabFile.ps1
    AUTHOR:	David Segura, david@segura.org
    BLOG:	http://www.osdeploy.com
    CREATED:	02/18/2018
    VERSION:	1.1.0.2
#>
function New-CabDellFamily
{
    [CmdletBinding()]
    Param (
        # Specifies the name and path of Folder that should be compress
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$ExpandedDriverPath,
        
        #Path and Name of the Cab to create
        [string]$PackagePath,
        [switch]$Core,

        #[Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        #[array]$DriverCleanup,
        
        # Specifies if High Compression should be used.
        #[switch]$HighCompression,
        
        # Specifies if the Makecab definition file should be kept after processing.
        # Should be used for troubleshooting only.
        #[switch]$KeepDDF,
        
        # Specifies if the source files should be deleted after the archive has been created.
        #[switch]$RemoveSource,
        
        # Specifies if the output of the Makecab command should be redirected to the console.
        # Should be used for troubleshooting only.
        [switch]$ShowOutput
    )

    Begin {}

    Process {
        $SourceName = (Get-Item $ExpandedDriverPath).Name
        $CabName = "$SourceName.cab"
        
        if ($PackagePath) {
            if ( ! ( Test-Path $PackagePath ) ) { New-Item -Type Directory -Path $PackagePath | Out-Null }
        } else {
            $PackagePath = (Get-Item $ExpandedDriverPath).Parent.FullName
        }

        if (Test-Path "$ExpandedDriverPath\OSDDriver.drvpnp") {
            Copy-Item -Path "$ExpandedDriverPath\OSDDriver.drvpnp" -Destination "$PackagePath\$SourceName.drvpnp"
        }
        
        $CabFullName = Join-Path -Path $PackagePath -ChildPath $CabName
        
        $DirectiveString = [System.Text.StringBuilder]::new()
        [void]$DirectiveString.AppendLine(';*** MakeCAB Directive file;')
        [void]$DirectiveString.AppendLine('.OPTION EXPLICIT')
        [void]$DirectiveString.AppendLine(".Set CabinetNameTemplate=$CabName")
        [void]$DirectiveString.AppendLine(".Set DiskDirectory1=$PackagePath")
        [void]$DirectiveString.AppendLine('.Set Cabinet=ON')
        [void]$DirectiveString.AppendLine('.Set Compress=ON')
        [void]$DirectiveString.AppendLine('.Set CompressionType=LZX')
        #[void]$DirectiveString.AppendLine('.Set CompressionType=MSZIP')
        [void]$DirectiveString.AppendLine('.Set CabinetFileCountThreshold=0')
        [void]$DirectiveString.AppendLine('.Set FolderFileCountThreshold=0')
        [void]$DirectiveString.AppendLine('.Set FolderSizeThreshold=0')
        [void]$DirectiveString.AppendLine('.Set MaxCabinetSize=0')
        [void]$DirectiveString.AppendLine('.Set MaxDiskFileCount=0')
        [void]$DirectiveString.AppendLine('.Set MaxDiskSize=0')

        Get-ChildItem $ExpandedDriverPath -Recurse | Unblock-File

        $DirectivePath = Join-Path -Path $PackagePath -ChildPath "$SourceName.ddf"

        $SourceContent = Get-ChildItem -Recurse $ExpandedDriverPath | Where-Object { -Not($_.PsIsContainer)}
        #===================================================================================================
        #   OSDDriver-DDF-Full.clixml
        #===================================================================================================
        Write-Host "Generating Content Directive: $ExpandedDriverPath\OSDDriver-DDF-Full.clixml" -ForegroundColor Gray
        $SourceContent | Select-Object -ExpandProperty Fullname | Export-Clixml "$ExpandedDriverPath\OSDDriver-DDF-Full.clixml" -Force
        #===================================================================================================
        #   Cleanup
        #===================================================================================================
        $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch 'release.dat'}
        $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*\win10\*\*\*\Windows7*"}
        $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*\win10\*\*\*\Windows8*"}
        $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*\win10\*\*\*\Windows9*"}
        $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*\win10\*\*\*\Windows10-x86*"}
        #===================================================================================================
        #   NoAudio
        #===================================================================================================
        $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Audio\\'}
        #===================================================================================================
        #   NoVideo
        #===================================================================================================
        $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Video\\'}
        #===================================================================================================
        #   SupportedSystems
        #===================================================================================================
        $SupportedSystems = ($SourceContent | Where-Object {$_.FullName -match 'SupportedSystems.txt'}).Directory.FullName
        Write-Verbose "SupportedSystems: $($SupportedSystems)"
        #===================================================================================================
        #   NoCoreIntel
        #===================================================================================================
        $ExcludeDir = @()
        foreach ($item in $SupportedSystems) {
            $DriverBundles = @()
            $DriverBundles = Get-ChildItem "$item\*\*" -Directory | Select-Object -Property FullName
        
            foreach ($DriverDir in $DriverBundles) {
                #Write-Host "$($DriverDir.FullName)" -ForegroundColor DarkGray
                $ExcludeFiles = @()
                $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'Netw*.inf'    #Intel Wireless
                if ($ExcludeFiles) {
                    $ExcludeDir += $DriverDir.FullName
                }
            }
        }
        foreach ($item in $ExcludeDir) {
            $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*$($item)*"}
        }
        #===================================================================================================
        #   OSDDriver-DDF
        #===================================================================================================
        Write-Host "Generating Content Directive: $ExpandedDriverPath\OSDDriver-DDF-Default.clixml" -ForegroundColor Gray
        $SourceContent | Select-Object -ExpandProperty Fullname | Export-Clixml "$ExpandedDriverPath\OSDDriver-DDF-Default.clixml" -Force
        #===================================================================================================
        #   Core
        #===================================================================================================
        if ($Core.IsPresent) {
            $ExcludeDir = @()
            foreach ($item in $SupportedSystems) {
                $DriverBundles = @()
                $DriverBundles = Get-ChildItem "$item\*\*" -Directory | Select-Object -Property FullName
            
                foreach ($DriverDir in $DriverBundles) {
                    #Write-Host "$($DriverDir.FullName)" -ForegroundColor DarkGray
                    $ExcludeFiles = @()
                    #$ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'ibt*.inf'            #Intel Bluetooth
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'BraswellSystem.inf'   #Intel Chipset
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'cougide.inf'          #Intel Chipset
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'IvyBridgeSystem.inf'  #Intel Chipset
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'heci.inf'             #Intel Chipset
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'e1*.inf'              #Intel Ethernet
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'iaStorAC.inf'         #Intel Storage
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'iusb3*.inf'           #Intel USBEHC
                    if ($ExcludeFiles) {
                        $ExcludeDir += $DriverDir.FullName
                    }
                }
            }
            foreach ($item in $ExcludeDir) {
                $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*$($item)*"}
            }

            $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Docks_Stands\\'}
            #$SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\USBNICW10\\'}
            #$SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Win10\\x86\\'}
            $ExcludeDir = @()
            foreach ($item in $SupportedSystems) {
                $DriverBundles = @()
                $DriverBundles = Get-ChildItem "$item\*\*" -Directory | Select-Object -Property FullName
            
                foreach ($DriverDir in $DriverBundles) {
                    #Write-Host "$($DriverDir.FullName)" -ForegroundColor DarkGray
                    $ExcludeFiles = @()
                    #$ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'cvault.*'            #Dell ControlVault
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'DellTPad.exe'         #Dell Touchpad
                    #$ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'ialp*.inf'           #Intel SerialIO
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'tbt*.inf'             #Intel Thunderbolt
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'iWiGiG.inf'           #Intel WiGig
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'ath*.inf'             #Qualcomm Atheros
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'rts*.inf'             #Realtek USB
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'rtdell.inf'           #Realtek Camera
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'SWLOCRM.inf'            #Sierra Wireless
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'swmb*.inf'            #Sierra Wireless
                    if ($ExcludeFiles) {
                        $ExcludeDir += $DriverDir.FullName
                    }
                }
            }
            foreach ($item in $ExcludeDir) {
                $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*$($item)*"}
            }
            #===================================================================================================
            #   OSDDriver-DDF-Core
            #===================================================================================================
            Write-Host "Generating Content Directive: $ExpandedDriverPath\OSDDriver-DDF-Core.clixml" -ForegroundColor Gray
            $SourceContent | Select-Object -ExpandProperty Fullname | Export-Clixml "$ExpandedDriverPath\OSDDriver-DDF-Core.clixml" -Force
        }
        #===================================================================================================
        #   MakeCab
        #===================================================================================================
        $SourceContent | Select-Object -ExpandProperty Fullname | Foreach-Object {
            [void]$DirectiveString.AppendLine("""$_"" ""$($_.SubString($ExpandedDriverPath.Length + 1))""")
        }

        Write-Verbose "Compressing $ExpandedDriverPath" -Verbose
        $DirectiveString.ToString() | Out-File -FilePath $DirectivePath -Encoding UTF8
        if ($ShowOutput.IsPresent) {
            makecab /F $DirectivePath
        } else {
            #makecab /F $DirectivePath | Out-Null
            cmd /c "makecab /F ""$DirectivePath""" '>nul' # | Out-Null
        }
        #Remove-Item $DirectivePath
        if (Test-Path 'setup.inf') {Remove-Item 'setup.inf' -Force}
        if (Test-Path 'setup.rpt') {Remove-Item 'setup.rpt' -Force}
        if ($RemoveSource.IsPresent) {Remove-Item -Path $ExpandedDriverPath -Recurse -Force}
    }

    End {}
}
