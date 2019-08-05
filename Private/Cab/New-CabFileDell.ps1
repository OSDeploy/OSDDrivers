function New-CabFileDell
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
        [switch]$RemoveAudio = $false,

        [Parameter(Position = 3)]
        [switch]$RemoveVideoAMD = $false,

        [Parameter(Position = 4)]
        [switch]$RemoveVideoNvidia = $false,

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
        #   SupportedSystems
        #===================================================================================================
        $SupportedSystems = ($SourceContent | Where-Object {$_.FullName -match 'SupportedSystems.txt'}).Directory.FullName

        if ($null -eq $SupportedSystems) {
            $SupportedSystems = Get-ChildItem "$ExpandedDriverPath\*\*\*" -Directory
        }
        Write-Verbose "SupportedSystems: $($SupportedSystems)" -Verbose
        #===================================================================================================
        #   RemoveAudio
        #===================================================================================================
        if ($RemoveAudio.IsPresent) {
            Write-Warning "Remove Category: Audio"
            $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Audio\\'}
        }
        #===================================================================================================
        #   Default Remove
        #===================================================================================================
        #$SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch 'release.dat'}
        $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*\win10\*\*\*\Windows7*"}
        $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*\win10\*\*\*\Windows8*"}
        $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*\win10\*\*\*\Windows9*"}
        $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*\win10\*\*\*\Windows10-x86*"}
        #===================================================================================================
        #   Remove Drivers - Intel Video
        #===================================================================================================
        Write-Warning "Remove Driver: Intel Video"
        $ExcludeDir = @()
        foreach ($item in $SupportedSystems) {
            $DriverBundles = @()
            $DriverBundles = Get-ChildItem "$item\Video\*" -Directory | Select-Object -Property FullName
        
            foreach ($DriverDir in $DriverBundles) {
                #Write-Host "$($DriverDir.FullName)" -ForegroundColor DarkGray
                $ExcludeFiles = @()
                $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'IntcDAud*.*' -File    #Intel Wireless
                if ($ExcludeFiles) {
                    Write-Host "$($DriverDir.FullName)" -ForegroundColor Gray
                    $ExcludeDir += $DriverDir.FullName
                }
            }
        }
        foreach ($item in $ExcludeDir) {
            $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*$($item)*"}
        }
        #===================================================================================================
        #   Remove Directory - Intel Video
        #===================================================================================================
        $ExcludeDriverDirs = @()
        $ExcludeDriverDirs = Get-ChildItem "$ExpandedDriverPath" 'igfxEM.exe' -File -Recurse | Select-Object -Property Directory -Unique
        foreach ($item in $ExcludeDriverDirs) {
            Write-Host "$($item.Directory)" -ForegroundColor Gray
            $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike [string]"$($item.Directory)*"}
        }
        #===================================================================================================
        #   Remove Drivers - AMD Video
        #===================================================================================================
        if ($RemoveVideoAMD.IsPresent) {
            Write-Warning "Remove Driver: AMD Video"
            $ExcludeDir = @()
            foreach ($item in $SupportedSystems) {
                $DriverBundles = @()
                $DriverBundles = Get-ChildItem "$item\Video\*" -Directory | Select-Object -Property FullName
            
                foreach ($DriverDir in $DriverBundles) {
                    #Write-Host "$($DriverDir.FullName)" -ForegroundColor DarkGray
                    $ExcludeFiles = @()
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse ati*.dll -File    #Intel Wireless
                    if ($ExcludeFiles) {
                        Write-Host "$($DriverDir.FullName)" -ForegroundColor Gray
                        $ExcludeDir += $DriverDir.FullName
                    }
                }
            }
            foreach ($item in $ExcludeDir) {
                $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*$($item)*"}
            }
        }
        #===================================================================================================
        #   Remove Drivers - Nvidia Video
        #===================================================================================================
        if ($RemoveVideoNvidia.IsPresent) {
            Write-Warning "Remove Driver: Nvidia Video"
            $ExcludeDir = @()
            foreach ($item in $SupportedSystems) {
                $DriverBundles = @()
                $DriverBundles = Get-ChildItem "$item\Video\*" -Directory | Select-Object -Property FullName
            
                foreach ($DriverDir in $DriverBundles) {
                    #Write-Host "$($DriverDir.FullName)" -ForegroundColor DarkGray
                    $ExcludeFiles = @()
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse nv*.dl* -File    #Intel Wireless
                    if ($ExcludeFiles) {
                        Write-Host "$($DriverDir.FullName)" -ForegroundColor Gray
                        $ExcludeDir += $DriverDir.FullName
                    }
                }
            }
            foreach ($item in $ExcludeDir) {
                $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*$($item)*"}
            }
        }
        #===================================================================================================
        #   OSDDriver-DDF1.clixml
        #===================================================================================================
        #Write-Host "Generating Content Directive: $ExpandedDriverPath\OSDDriver-DDF1.clixml" -ForegroundColor Gray
        $SourceContent | Select-Object -ExpandProperty Fullname | Export-Clixml "$ExpandedDriverPath\OSDDriver-DDF1.clixml" -Force


<#         if ($MakeCabLevel -eq 'L2' -or $MakeCabLevel -eq 'L3') {
            #===================================================================================================
            #   L2
            #===================================================================================================
            Write-Warning "L2 Remove Category: Video"
            $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Video\\'}
            #===================================================================================================
            #   OSDDriver-DDF2.clixml
            #===================================================================================================
            #Write-Host "Generating Content Directive: $ExpandedDriverPath\OSDDriver-DDF2.clixml" -ForegroundColor Gray
            $SourceContent | Select-Object -ExpandProperty Fullname | Export-Clixml "$ExpandedDriverPath\OSDDriver-DDF2.clixml" -Force
        } #>
<#         if ($MakeCabLevel -eq 'L3') {
            #===================================================================================================
            #   L3
            #===================================================================================================
            Write-Warning "L3 Remove Category: Dock"
            $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Docks\\'}
            $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Docks_Stands\\'}

            $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\05V44_A00-00\\'}   #Apoint
            $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\35M77_A00-00\\'}   #Apoint

            $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\3JG2J_A00-00\\'}   #Intel Bluetooth
            $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\78CC6_A00-00\\'}   #Intel Bluetooth
            $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\CC1FK-A00-00\\'}   #Intel Bluetooth
            $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\D6H2W_A00-00\\'}   #Intel Bluetooth
            $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\D6K9X_A00-00\\'}   #Intel Bluetooth
            $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\TD5PV_A00-00\\'}   #Intel Bluetooth
            $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\VK498_A00-00\\'}   #Intel Bluetooth

            $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Chipset\\'}
            $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Communication\\'}
            $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Network\\'}
            $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Security\\'}
            $SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Storage\\'}

            

            #$SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\USBNICW10\\'}
            #$SourceContent = $SourceContent | Where-Object {$_.FullName -notmatch '\\Win10\\x86\\'}
            #===================================================================================================
            #   No Directory Intel Chipset
            #===================================================================================================
            $ExcludeDriverDirs = @()
            $ExcludeDriverDirs = Get-ChildItem "$ExpandedDriverPath" -Include 'BraswellSystem.inf','cougide.inf','IvyBridgeSystem.inf' -File -Recurse | Select-Object -Property Directory -Unique
            if ($ExcludeDriverDirs) {
                Write-Warning "L3 Remove Driver: Intel Chipset"
                foreach ($item in $ExcludeDriverDirs) {
                    Write-Host "$($item.Directory)" -ForegroundColor Gray
                    $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike [string]"$($item.Directory)*"}
                }
            }
            #===================================================================================================
            #   No Intel Ethernet Packages
            #===================================================================================================
            Write-Warning "L3 Remove Driver: Intel Ethernet"
            $ExcludeDir = @()
            foreach ($item in $SupportedSystems) {
                $DriverBundles = @()
                $DriverBundles = Get-ChildItem "$item\Network\*" -Directory | Select-Object -Property FullName
            
                foreach ($DriverDir in $DriverBundles) {
                    #Write-Host "$($DriverDir.FullName)" -ForegroundColor DarkGray
                    $ExcludeFiles = @()
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'e1*.inf' -File              #Intel Ethernet
                    if ($ExcludeFiles) {
                        Write-Host "$($DriverDir.FullName)" -ForegroundColor Gray
                        $ExcludeDir += $DriverDir.FullName
                    }
                }
            }
            foreach ($item in $ExcludeDir) {
                $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*$($item)*"}
            }
            #===================================================================================================
            #   No Directory Intel Ethernet
            #===================================================================================================
            $ExcludeDriverDirs = @()
            $ExcludeDriverDirs = Get-ChildItem "$ExpandedDriverPath" -Include 'e1*.inf' -File -Recurse | Select-Object -Property Directory -Unique
            if ($ExcludeDriverDirs) {
                foreach ($item in $ExcludeDriverDirs) {
                    Write-Host "$($item.Directory)" -ForegroundColor Gray
                    $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike [string]"$($item.Directory)*"}
                }
            }
            #===================================================================================================
            #   No Directory Intel(R) Management and Security Application Local Management
            #===================================================================================================
            $ExcludeDriverDirs = @()
            $ExcludeDriverDirs = Get-ChildItem "$ExpandedDriverPath" -Include 'lms.exe' -File -Recurse | Select-Object -Property Directory -Unique
            if ($ExcludeDriverDirs) {
                Write-Warning "L3 Remove Driver: Intel Management and Security Application"
                foreach ($item in $ExcludeDriverDirs) {
                    Write-Host "$($item.Directory)" -ForegroundColor Gray
                    $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike [string]"$($item.Directory)*"}
                }
            }
            #===================================================================================================
            #   No Directory Intel USB3
            #===================================================================================================
            $ExcludeDriverDirs = @()
            $ExcludeDriverDirs = Get-ChildItem "$ExpandedDriverPath" -Include 'iusb3*.inf' -File -Recurse | Select-Object -Property Directory -Unique
            if ($ExcludeDriverDirs) {
                Write-Warning "L3 Remove Driver: Intel USB 3"
                foreach ($item in $ExcludeDriverDirs) {
                    Write-Host "$($item.Directory)" -ForegroundColor Gray
                    $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike [string]"$($item.Directory)*"}
                }
            }
            #===================================================================================================
            #   No Directory Intel Storage
            #===================================================================================================
            $ExcludeDriverDirs = @()
            $ExcludeDriverDirs = Get-ChildItem "$ExpandedDriverPath" -Include 'iaStorAC.inf' -File -Recurse | Select-Object -Property Directory -Unique
            if ($ExcludeDriverDirs) {
                Write-Warning "L3 Remove Driver: Intel Storage"
                foreach ($item in $ExcludeDriverDirs) {
                    Write-Host "$($item.Directory)" -ForegroundColor Gray
                    $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike [string]"$($item.Directory)*"}
                }
            }
            #===================================================================================================
            #   Remove Packages
            #===================================================================================================
            Write-Warning "L3 Remove Driver: Final Cleanup"
            $ExcludeDir = @()
            foreach ($item in $SupportedSystems) {
                $DriverBundles = @()
                $DriverBundles = Get-ChildItem "$item\*\*" -Directory | Select-Object -Property FullName
            
                foreach ($DriverDir in $DriverBundles) {
                    #Write-Host "$($DriverDir.FullName)" -ForegroundColor DarkGray
                    $ExcludeFiles = @()
                    #$ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'cvault.*' -File          #Dell ControlVault
                    #$ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'ialp*.inf' -File         #Intel SerialIO
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'DellTPad.exe' -File       #Dell Touchpad
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'tbt*.inf' -File           #Intel Thunderbolt
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'iWiGiG.inf' -File         #Intel WiGig
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'ath*.inf' -File           #Qualcomm Atheros
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'rts*.inf' -File           #Realtek USB
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'rtdell.inf' -File         #Realtek Camera
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'SWLOCRM.inf' -File        #Sierra Wireless
                    $ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'swmb*.inf' -File          #Sierra Wireless
                    if ($ExcludeFiles) {
                        Write-Host "$($DriverDir.FullName)" -ForegroundColor Gray
                        $ExcludeDir += $DriverDir.FullName
                    }
                }
            }
            foreach ($item in $ExcludeDir) {
                $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*$($item)*"}
            }
            #===================================================================================================
            #   Temp
            #===================================================================================================
<#             $ExcludeDir = @()
            foreach ($item in $SupportedSystems) {
                $DriverBundles = @()
                $DriverBundles = Get-ChildItem "$item\*\*" -Directory | Select-Object -Property FullName
            
                foreach ($DriverDir in $DriverBundles) {
                    #Write-Host "$($DriverDir.FullName)" -ForegroundColor DarkGray
                    $ExcludeFiles = @()
                    #$ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'ibt*.inf'            #Intel Bluetooth
                    ###$ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'BraswellSystem.inf'   #Intel Chipset
                    ###$ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'cougide.inf'          #Intel Chipset
                    ###$ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'IvyBridgeSystem.inf'  #Intel Chipset
                    #$ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'heci.inf'             #Intel Chipset
                    ###$ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'e1*.inf'              #Intel Ethernet
                    ###$ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'iaStorAC.inf'         #Intel Storage
                    ###$ExcludeFiles += Get-ChildItem "$($DriverDir.FullName)" -Recurse 'iusb3*.inf'           #Intel USBEHC
                    if ($ExcludeFiles) {
                        $ExcludeDir += $DriverDir.FullName
                    }
                }
            }
            foreach ($item in $ExcludeDir) {
                $SourceContent = $SourceContent | Where-Object {$_.FullName -notlike "*$($item)*"}
            } #>
            #===================================================================================================
            #   OSDDriver-DDF3.clixml
            #===================================================================================================
            #Write-Host "Generating Content Directive: $ExpandedDriverPath\OSDDriver-DDF3.clixml" -ForegroundColor Gray
            #$SourceContent | Select-Object -ExpandProperty Fullname | Export-Clixml "$ExpandedDriverPath\OSDDriver-DDF3.clixml" -Force
        #} #>
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
        if ($RemoveDirective.IsPresent) {Remove-Item $DirectivePath -Force | Out-Null}
        if ($RemoveSource.IsPresent) {Remove-Item -Path $ExpandedDriverPath -Recurse -Force | Out-Null}
    }

    End {}
}
