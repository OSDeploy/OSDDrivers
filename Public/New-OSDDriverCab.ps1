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
	New-OSDriverCAB -Path C:\Temp\Dell\LatitudeE10_A01
	Creates MSZIP Fast Compression CAB from of C:\Temp\Dell\LatitudeE10_A01
.EXAMPLE
	New-OSDriverCAB -Path C:\Temp\Dell -HighCompression -MakeCABsFromSubDirs
	Creates LZX High Compression CABS from all subdirectories of C:\Temp\Dell
.NOTES
	NAME:	New-OSDriverCAB.ps1
	AUTHOR:	David Segura, david@segura.org
	BLOG:	http://www.osdeploy.com
	CREATED:	02/18/2018
	VERSION:	1.1.0.2
#>

function New-OSDDriverCab
{
	[CmdletBinding()]
	Param (
        # Specifies the name and path of Folder that should be compress
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$SourceDirectory,
        
        #Path and Name of the Cab to create
        [string]$DestinationDirectory,
        
        # Specifies if High Compression should be used.
        #[switch]$HighCompression,
        
        # Specifies if the Makecab definition file should be kept after processing.
        # Should be used for troubleshooting only.
        #[switch]$KeepDDF,
        
        # Specifies if the source files should be deleted after the archive has been created.
        [switch]$RemoveSource,
        
        # Specifies if the output of the Makecab command should be redirected to the console.
        # Should be used for troubleshooting only.
        [switch]$ShowOutput
    )
    begin {
    }

    process {
        $SourceName = (Get-Item $SourceDirectory).Name

        $CabName = "$SourceName.cab"
        
        if ($DestinationDirectory) {
            if ( ! ( Test-Path $DestinationDirectory ) ) { new-item -Type Directory -Path $DestinationDirectory }
        } else {
            $DestinationDirectory = (Get-Item $SourceDirectory).Parent.FullName
        }

        if (Test-Path "$SourceDirectory\OSDDriver.xmlpnp") {
            Copy-Item -Path "$SourceDirectory\OSDDriver.xmlpnp" -Destination "$DestinationDirectory\$SourceName.xmlpnp"
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
        [void]$DirectiveString.AppendLine('.Set CabinetFileCountThreshold=0')
        [void]$DirectiveString.AppendLine('.Set FolderFileCountThreshold=0')
        [void]$DirectiveString.AppendLine('.Set FolderSizeThreshold=0')
        [void]$DirectiveString.AppendLine('.Set MaxCabinetSize=0')
        [void]$DirectiveString.AppendLine('.Set MaxDiskFileCount=0')
        [void]$DirectiveString.AppendLine('.Set MaxDiskSize=0')

        Get-ChildItem $SourceDirectory -Recurse | Unblock-File

        $DirectivePath = Join-Path -Path $DestinationDirectory -ChildPath "$SourceName.ddf"
        Get-ChildItem -Recurse $SourceDirectory | Where-Object { -Not($_.psiscontainer)} | Select-Object -ExpandProperty Fullname | Foreach-Object {
            [void]$DirectiveString.AppendLine("""$_"" ""$($_.SubString($SourceDirectory.Length + 1))""")
        }
        if ($PSCmdlet.ShouldProcess("Creating archive '$CabFullName'.")) {
            Write-Verbose "  Compressing folder '$SourceDirectory' to '$CabFullName'."
            $DirectiveString.ToString() | Out-File -FilePath $DirectivePath -Encoding UTF8
            if ($ShowOutput.IsPresent) {
                makecab /F $DirectivePath
            } else {
                makecab /F $DirectivePath | Out-Null
                #cmd /c "makecab /F ""$DirectivePath""" '>nul' # | Out-Null
            }
            Remove-Item $DirectivePath
            if (Test-Path 'setup.inf') {Remove-Item 'setup.inf' -Force}
            if (Test-Path 'setup.rpt') {Remove-Item 'setup.rpt' -Force}
        }
        if ($RemoveSource.IsPresent) {Remove-Item -Path $SourceDirectory -Recurse -Force}
    }
    end {}
}
