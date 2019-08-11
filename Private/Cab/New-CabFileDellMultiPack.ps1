function New-CabFileDellMultiPack
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$ExpandedDriverPath,
        
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$PublishPath,

        [Parameter(Position = 2)]
        [switch]$RemoveIntelVideo = $false,

        [switch]$HighCompression = $false,
        [switch]$RemoveDirective = $false,
        [switch]$RemoveSource = $false,
        [switch]$ShowOutput = $false
    )

    Begin {}

    Process {
        #===================================================================================================
        #   Defaults
        #===================================================================================================
        $HighCompression = $true
        $RemoveDirective = $false
        $SourceName = (Get-Item $ExpandedDriverPath).Name
        $CabName = "$SourceName.cab"
        if (Test-Path (Join-Path $PublishPath $CabName)) {Continue}
        #===================================================================================================
        #   PublishPath
        #===================================================================================================
        if ($PublishPath) {
            if ( ! ( Test-Path $PublishPath ) ) { New-Item -Type Directory -Path $PublishPath | Out-Null }
        } else {
            $PublishPath = (Get-Item $ExpandedDriverPath).Parent.FullName
        }
        #===================================================================================================
        #   Directive
        #===================================================================================================
        $DirectivePath = Join-Path -Path $PublishPath -ChildPath "$SourceName.ddf"
        
        $DirectiveString = [System.Text.StringBuilder]::new()
        [void]$DirectiveString.AppendLine(';*** MakeCAB Directive file;')
        [void]$DirectiveString.AppendLine('.OPTION EXPLICIT')
        [void]$DirectiveString.AppendLine(".Set CabinetNameTemplate=$CabName")
        [void]$DirectiveString.AppendLine(".Set DiskDirectory1=$PublishPath")
        [void]$DirectiveString.AppendLine('.Set Cabinet=ON')
        [void]$DirectiveString.AppendLine('.Set Compress=ON')
        if ($HighCompression.IsPresent) {[void]$DirectiveString.AppendLine('.Set CompressionType=LZX')}
        else {[void]$DirectiveString.AppendLine('.Set CompressionType=MSZIP')}
        [void]$DirectiveString.AppendLine('.Set CabinetFileCountThreshold=0')
        [void]$DirectiveString.AppendLine('.Set FolderFileCountThreshold=0')
        [void]$DirectiveString.AppendLine('.Set FolderSizeThreshold=0')
        [void]$DirectiveString.AppendLine('.Set MaxCabinetSize=0')
        [void]$DirectiveString.AppendLine('.Set MaxDiskFileCount=0')
        [void]$DirectiveString.AppendLine('.Set MaxDiskSize=0')
        #===================================================================================================
        #   Unblock
        #===================================================================================================
        Get-ChildItem $ExpandedDriverPath -Recurse | Unblock-File
        #===================================================================================================
        #   SourceContent
        #===================================================================================================
        $SourceContent = @()
        $SourceContent = Get-ChildItem -Recurse $ExpandedDriverPath | Where-Object { -Not($_.PsIsContainer)}
        #===================================================================================================
        #   Remove Directory - Intel Video
        #===================================================================================================
        if ($RemoveIntelVideo.IsPresent) {
            $ExcludeDriverDirs = @()
            $ExcludeDriverDirs = Get-ChildItem "$ExpandedDriverPath" 'igfxEM.exe' -File -Recurse | Select-Object -Property Directory -Unique
            foreach ($ExcludeDir in $ExcludeDriverDirs) {
                Write-Host "$($ExcludeDir.Directory)" -ForegroundColor Gray
                $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike [string]"$($ExcludeDir.Directory)*"}
            }
        }
        #===================================================================================================
        #   Complete Directive
        #===================================================================================================
        $SourceContent | Select-Object -ExpandProperty Fullname | Foreach-Object {
            [void]$DirectiveString.AppendLine("""$_"" ""$($_.SubString($ExpandedDriverPath.Length + 1))""")
        }
        #===================================================================================================
        #   MakeCab
        #===================================================================================================
        Write-Verbose "Compressing $ExpandedDriverPath" -Verbose
        $DirectiveString.ToString() | Out-File -FilePath $DirectivePath -Encoding UTF8
        if ($ShowOutput.IsPresent) {
            makecab /F $DirectivePath
        } else {
            #makecab /F $DirectivePath | Out-Null
            cmd /c "makecab /F ""$DirectivePath""" '>nul' # | Out-Null
        }
        #===================================================================================================
        #   Cleanup
        #===================================================================================================
        if (Test-Path 'setup.inf') {Remove-Item 'setup.inf' -Force}
        if (Test-Path 'setup.rpt') {Remove-Item 'setup.rpt' -Force}
        if ($RemoveDirective.IsPresent) {Remove-Item $DirectivePath -Force | Out-Null}
        if ($RemoveSource.IsPresent) {Remove-Item -Path $ExpandedDriverPath -Recurse -Force | Out-Null}
    }

    End {}
}
