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

function New-DriverCabDellFamily
{
    [CmdletBinding()]
    Param (
        # Specifies the name and path of Folder that should be compress
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$DriverExpandPath,
        
        #Path and Name of the Cab to create
        [string]$DestinationDirectory,

        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [array]$DriverCleanup,
        
        # Specifies if High Compression should be used.
        #[switch]$HighCompression,
        
        # Specifies if the Makecab definition file should be kept after processing.
        # Should be used for troubleshooting only.
        #[switch]$KeepDDF,
        
        # Specifies if the source files should be deleted after the archive has been created.
        [switch]$RemoveSource,
        
        # Specifies if the output of the Makecab command should be redirected to the console.
        # Should be used for troubleshooting only.
        [switch]$ShowOutput,
        [string]$DellFamily
    )

    Begin {}

    Process {
        $SourceName = (Get-Item $DriverExpandPath).Name
        $CabName = "$SourceName.cab"
        
        if ($DestinationDirectory) {
            if ( ! ( Test-Path $DestinationDirectory ) ) { new-item -Type Directory -Path $DestinationDirectory }
        } else {
            $DestinationDirectory = (Get-Item $DriverExpandPath).Parent.FullName
        }
        
        $CabFullName = Join-Path -Path $DestinationDirectory -ChildPath $CabName
        
        $DirectiveString = [System.Text.StringBuilder]::new()
        [void]$DirectiveString.AppendLine(';*** MakeCAB Directive file;')
        [void]$DirectiveString.AppendLine('.OPTION EXPLICIT')
        [void]$DirectiveString.AppendLine(".Set CabinetNameTemplate=$CabName")
        [void]$DirectiveString.AppendLine(".Set DiskDirectory1=$DestinationDirectory")
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

        Get-ChildItem $DriverExpandPath -Recurse | Unblock-File

        $DirectivePath = Join-Path -Path $DestinationDirectory -ChildPath "$SourceName.cabddf"

        $SourceContent = Get-ChildItem -Recurse $DriverExpandPath | Where-Object { -Not($_.PsIsContainer)}

        if ($DriverCleanup) {
            $SupportedSystems = ($SourceContent | Where-Object {$_.FullName -match 'SupportedSystems.txt'}).Directory.FullName
            Write-Host "SupportedSystems: $($SupportedSystems)" -ForegroundColor Gray

            $ExcludeDir = @()
            foreach ($item in $SupportedSystems) {
                $DriverBundles = @()
                $DriverBundles = Get-ChildItem "$item\*\*" -Directory | Select-Object -Property FullName
            
                foreach ($DriverDir in $DriverBundles) {
                    Write-Host "$($DriverDir.FullName)" -ForegroundColor DarkGray
                    $ExcludeFiles = @()
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'BraswellSystem.inf'
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'e1*.inf'
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'iaStorAC.inf'
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'ibt*.inf'
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'iWiGiG.inf'
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'tbt*.inf'
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'Netwtw*.inf'
                    if ($ExcludeFiles) {
                        $ExcludeDir += $DriverDir.FullName
                    }
                }
            }
            foreach ($item in $ExcludeDir) {
                $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*$($item)*"}
            }
            foreach ($Cleanup in $DriverCleanup) {
                Write-Host "Removing $($Cleanup)" -ForegroundColor Gray
                $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch "$($Cleanup)"}
            }
            #$SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Audio\\'} #Remove Audio
            #$SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Video\\'} #Remove Video
            $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch 'release.dat'}
            #$SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Win10\\x86\\'} #Remove x86
            $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*\win10\*\*\*\Windows7*"}
            $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*\win10\*\*\*\Windows8*"}
            $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*\win10\*\*\*\Windows9*"}
            $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*\win10\*\*\*\Windows10-x86*"}
        }
        $SourceContent = $SourceContent | Where-Object {-Not($_.PsIsContainer)}

        $SourceContent | Select-Object -ExpandProperty Fullname | Foreach-Object {
            [void]$DirectiveString.AppendLine("""$_"" ""$($_.SubString($DriverExpandPath.Length + 1))""")
        }
        if ($PSCmdlet.ShouldProcess("Creating archive '$CabFullName'.")) {
            Write-Verbose "Compressing $DriverExpandPath" -Verbose
            $DirectiveString.ToString() | Out-File -FilePath $DirectivePath -Encoding UTF8
            if ($ShowOutput.IsPresent) {
                makecab /F $DirectivePath
            } else {
                makecab /F $DirectivePath | Out-Null
                #cmd /c "makecab /F ""$DirectivePath""" '>nul' # | Out-Null
            }
            #Remove-Item $DirectivePath
            if (Test-Path 'setup.inf') {Remove-Item 'setup.inf' -Force}
            if (Test-Path 'setup.rpt') {Remove-Item 'setup.rpt' -Force}
        }
        if ($RemoveSource.IsPresent) {Remove-Item -Path $DriverExpandPath -Recurse -Force}
    }

    End {}
}
