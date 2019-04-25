#https://gist.github.com/mobzystems/793007db28e3ffcc20e2
#https://www.reddit.com/r/nvidia/comments/5jj6re/how_to_download_extract_and_install_drivers/
$7zip = "$env:ProgramFiles\7-Zip\7z.exe"

if (-not (Test-Path "$7zip")) {
    Throw "This operation requires 7-Zip installed at $7zip needed"
} 

$Source = "D:\OSDCoreDrivers\CoreDrivers\Display Nvidia\425.31-quadro-desktop-notebook-win10-64bit-international-whql.exe"

$Destination = "D:\OSDCoreDrivers\CoreDrivers\Display Nvidia\425.31-quadro-desktop-notebook-win10-64bit-international-whql"

$Switches += " -bd -y"
$Switches = $Switches.TrimStart()
$7zcmd = "e"

$verb = "Extracting"
            
Write-Verbose "$verb archive `"$Path`""
[string]$cmd = "`"$7zip`" $7zcmd $Switches `"$Path`" $files"
Write-Debug $cmd

Invoke-Expression "&$cmd" -OutVariable output | Write-Verbose

# Check result
if ($CheckOK) {
    if (-not ([string]$output).Contains("Everything is Ok")) {
        throw "$verb archive `"$Path`" failed: $output"
    }
}

# No error: return the 7-Zip output
Write-Output $output


Function Expand-7zArchive {
    [CmdletBinding()]
    Param(
        # The path of the archive to update
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Path,

        # The path to extract files to
        [Parameter(Mandatory=$false, Position=1)]
        [string]$Destination = ".",

        # A list of file names or patterns to include
        [Parameter(Mandatory=$false, ValueFromPipeLine=$true, Position=2)]
        [string[]]$Include = @("*"),

        # A list of file names or patterns to exclude
        [Parameter(Mandatory=$false)]
        [string[]]$Exclude = @(),

        # Apply include patterns recursively
        [switch]$Recurse,

        # Additional switches for 7za
        [string]$Switches = "",

        # Force overwriting existing files
        [switch]$Force
    )

    Begin {
        $Switches = $Switches + " `"-o$Destination`""
        if ($Force) {
            $Switches = $Switches + " -aoa" # Overwrite ALL
        } else {
            $Switches = $Switches + " -aos" # SKIP extracting existing files
        }

        $filesToProcess = @()
    }
    Process {
        $filesToProcess += $Include
    }

    End {
        [string[]]$result = Perform7zOperation -Operation Extract -Path $Path -Include $filesToProcess -Exclude $Exclude -Recurse:$Recurse -Switches $Switches

        $result | ForEach-Object {
            if ($_.StartsWith("Skipping    ")) {
                Write-Warning $_
            }
        }
    }
}