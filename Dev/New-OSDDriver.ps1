function New-OSDDriver {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$DriverPath,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$PublishPath,

        [switch]$PnpMatch,

        [ValidateSet('Bluetooth','Camera','Display','HDC','HIDClass','Keyboard','Media','Monitor','Mouse','Net','SCSIAdapter','SmartCardReader','System','USBDevice')]
        [string]$DriverClass

    )
    #======================================================================================
    #   Validate Admin Rights
    #======================================================================================
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    If (!( $isAdmin )) {
        Write-Host "Checking User Account Control settings ..." -ForegroundColor Green
        if ((Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System).EnableLUA -eq 0) {
            #UAC Disabled
            Write-Host '========================================================================================' -ForegroundColor DarkGray
            Write-Host "User Account Control is Disabled ... " -ForegroundColor Green
            Write-Host "You will need to correct your UAC Settings ..." -ForegroundColor Green
            Write-Host "Try running this script in an Elevated PowerShell session ... Exiting" -ForegroundColor Green
            Write-Host '========================================================================================' -ForegroundColor DarkGray
            Start-Sleep -s 10
            Exit 0
        } else {
            #UAC Enabled
            Write-Host "UAC is Enabled" -ForegroundColor Green
            Start-Sleep -s 3
            if ($Silent) {
                Write-Host "-- Restarting as Administrator (Silent)" -ForegroundColor Cyan ; Start-Sleep -Seconds 1
                Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Silent" -Verb RunAs -Wait
            } elseif($Restart) {
                Write-Host "-- Restarting as Administrator (Restart)" -ForegroundColor Cyan ; Start-Sleep -Seconds 1
                Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Restart" -Verb RunAs -Wait
            } else {
                Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Start-Sleep -Seconds 1
                Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -Wait
            }
            Exit 0
        }
    } else {
        #Write-Host '========================================================================================' -ForegroundColor DarkGray
        #Write-Host "-- Running with Elevated Permissions ..." -ForegroundColor Cyan ; Start-Sleep -Seconds 1
        #Write-Host '========================================================================================' -ForegroundColor DarkGray
    }
    #===================================================================================================
    #   Test-DriverPath
    #===================================================================================================
    Test-DriverPath $DriverPath
    #===================================================================================================
    #   Test-PublishPath
    #===================================================================================================
    #Test-PublishPath $PublishPath
    #===================================================================================================
    #   Get-DirectoryName
    #===================================================================================================
    $DirectoryName = Get-DirectoryName $DriverPath
    #===================================================================================================
    #   Get-ParentDirectoryFullName
    #===================================================================================================
    $ParentDirectoryFullName = Get-ParentDirectoryFullName $DriverPath
    #===================================================================================================
    #   PnpMatch
    #===================================================================================================
    if ($PnpMatch.IsPresent) {
        if ($DriverClass) {
            Write-Verbose "DriverPath: $DriverPath $DriverClass" -Verbose
            Save-OSDDriverPnp -ExpandedDriverPath $DriverPath -OSDPnpClass $DriverClass
        } else {
            Write-Verbose "DriverPath: $DriverPath" -Verbose
            Save-OSDDriverPnp -ExpandedDriverPath $DriverPath
        }
        #===================================================================================================
        #   Publish OSDDriverPnp
        #===================================================================================================
        #Write-Verbose "Publish: $PublishPath\$DirectoryName.cabpnp ..." -Verbose
        #Copy-Item -Path "$DriverPath.cabpnp" -Destination "$PublishPath" -Force -ErrorAction Stop | Out-Null
        #Break
    }
    #===================================================================================================
    #   New-OSDDriverCabFile
    #===================================================================================================
    $OSDDriverCabFile = "$DriverPath.cab"
    if (Test-Path "$OSDDriverCabFile") {
        Write-Verbose "Build: $OSDDriverCabFile ... exists!" -Verbose
    } else {
        Write-Warning "Build: $OSDDriverCabFile ... This may take a while"
        New-OSDDriverCabFile -DriverExpandPath "$DriverPath" -DestinationDirectory $PublishPath
    }
    #===================================================================================================
    #   Publish-DriverCab
    #===================================================================================================
    if (Test-Path "$PublishPath\$DirectoryName.cab") {
        Write-Verbose "Publish: $PublishPath\$DirectoryName.cab ... exists!" -Verbose
    } else {
        Write-Verbose "Publish: $PublishPath\$DirectoryName.cab ..." -Verbose
        Copy-Item -Path "$DriverPath.cab" -Destination "$PublishPath" -Force -ErrorAction Stop | Out-Null
    }
    #===================================================================================================
    #   New-AutoDriverTask
    #===================================================================================================
    if (-not (Test-Path "$PublishPath\$DirectoryName.cabtask")) {
        Write-Warning "Use New-AutoDriverTask to create a Task for $PublishPath\$DirectoryName.cab"
        Write-Warning "e.g.: New-AutoDriverTask -DriverCabPath '$PublishPath\$DirectoryName.cab'"
    } else {
        Write-Verbose "Publish: $PublishPath\$DirectoryName.cabtask ... exists!" -Verbose
    }
}