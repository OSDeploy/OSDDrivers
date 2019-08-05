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
        #===================================================================================================
        #   SourceName
        #===================================================================================================
        $SourceName = (Get-Item $ExpandedDriverPath).Name
        #===================================================================================================
        #   PublishPath
        #===================================================================================================
        if ($PublishPath) {
            if ( ! ( Test-Path $PublishPath ) ) { New-Item -Type Directory -Path $PublishPath | Out-Null }
        } else {
            $PublishPath = (Get-Item $ExpandedDriverPath).Parent.FullName
        }
        #===================================================================================================
        #   CabName
        #===================================================================================================
        $CabName = "$SourceName.cab"
        #===================================================================================================
        #   OSDDriver.drvpnp
        #===================================================================================================
        if (Test-Path "$ExpandedDriverPath\OSDDriver.drvpnp") {Copy-Item -Path "$ExpandedDriverPath\OSDDriver.drvpnp" -Destination "$PublishPath\$SourceName.drvpnp"}
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
        #   OSDDriver-DDF0.clixml
        #===================================================================================================
        #Write-Host "Generating Content Directive: $ExpandedDriverPath\OSDDriver-DDF0.clixml" -ForegroundColor Gray
        $SourceContent | Select-Object -ExpandProperty Fullname | Export-Clixml "$ExpandedDriverPath\OSDDriver-DDF0.clixml" -Force
        #===================================================================================================
        #   Remove Directory - Intel Video
        #===================================================================================================
        $ExcludeDriverDirs = @()
        $ExcludeDriverDirs = Get-ChildItem "$ExpandedDriverPath" 'igfxEM.exe' -File -Recurse | Select-Object -Property Directory -Unique
        foreach ($ExcludeDir in $ExcludeDriverDirs) {
            Write-Host "$($ExcludeDir.Directory)" -ForegroundColor Gray
            $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike [string]"$($ExcludeDir.Directory)*"}
        }
        #===================================================================================================
        #   OSDDriver-DDF1.clixml
        #===================================================================================================
        #Write-Host "Generating Content Directive: $ExpandedDriverPath\OSDDriver-DDF1.clixml" -ForegroundColor Gray
        $SourceContent | Select-Object -ExpandProperty Fullname | Export-Clixml "$ExpandedDriverPath\OSDDriver-DDF1.clixml" -Force
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
        #if (Test-Path 'setup.inf') {Remove-Item 'setup.inf' -Force}
        #if (Test-Path 'setup.rpt') {Remove-Item 'setup.rpt' -Force}
        if (Test-Path "$ExpandedDriverPath\OSDDriver-Devices.txt") {
            Copy-Item "$ExpandedDriverPath\OSDDriver-Devices.txt" -Destination "$PublishPath\$SourceName.drvtxt" -Force | Out-Null
            Remove-Item "$ExpandedDriverPath\OSDDriver-Devices.txt" -Force | Out-Null
        }
        if (Test-Path "$ExpandedDriverPath\OSDDriver.drvpnp") {Remove-Item "$ExpandedDriverPath\OSDDriver.drvpnp" -Force | Out-Null}
        if (Test-Path "$ExpandedDriverPath\OSDDriver-DDF0.clixml") {Remove-Item "$ExpandedDriverPath\OSDDriver-DDF0.clixml" -Force | Out-Null}
        if (Test-Path "$ExpandedDriverPath\OSDDriver-DDF1.clixml") {Remove-Item "$ExpandedDriverPath\OSDDriver-DDF1.clixml" -Force | Out-Null}
        if ($RemoveDirective.IsPresent) {Remove-Item $DirectivePath -Force | Out-Null}
        if ($RemoveSource.IsPresent) {Remove-Item -Path $ExpandedDriverPath -Recurse -Force | Out-Null}
    }

    End {}
}
