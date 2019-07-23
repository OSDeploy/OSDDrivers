function Compress-OSDDriver {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$ExpandedDriverPath,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$PublishPath

        #[Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        #[ValidateSet('Bluetooth','Camera','Display','HDC','HIDClass','Keyboard','Media','Monitor','Mouse','Net','SCSIAdapter','SmartCardReader','System','USBDevice')]
        #[string]$OSDPnpClass,

        #[switch]$EnablePnpDetection
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
    Test-ExpandedDriverPath $ExpandedDriverPath
    #===================================================================================================
    #   Test-PublishPath
    #===================================================================================================
    Test-PublishPath $PublishPath
    #===================================================================================================
    #   Get-DirectoryName
    #===================================================================================================
    $DirectoryName = Get-DirectoryName $ExpandedDriverPath
    #===================================================================================================
    #   Get-ParentDirectoryFullName
    #===================================================================================================
    $ParentDirectoryFullName = Get-ParentDirectoryFullName $ExpandedDriverPath
    #===================================================================================================
    #   EnablePnpDetection
    #===================================================================================================
    if ($EnablePnpDetection.IsPresent) {
        if ($OSDPnpClass) {
            Write-Verbose "ExpandedDriverPath: $ExpandedDriverPath -OSDPnpClass $OSDPnpClass" -Verbose
            Save-OSDDriverPnp -ExpandedDriverPath $ExpandedDriverPath -OSDPnpClass $OSDPnpClass
        } else {
            Write-Verbose "ExpandedDriverPath: $ExpandedDriverPath" -Verbose
            Save-OSDDriverPnp -ExpandedDriverPath $ExpandedDriverPath
        }
    }
    #===================================================================================================
    #   Publish-OSDDriverPnp
    #===================================================================================================
    if (Test-Path "$ExpandedDriverPath\OSDDriver.cabpnp") {
        Write-Host "Compress-OSDDrievr: $PublishPath\$DirectoryName.cabpnp ..." -ForegroundColor Gray
        Copy-Item -Path "$ExpandedDriverPath\OSDDriver.cabpnp" -Destination "$PublishPath\$DirectoryName.cabpnp" -Force -ErrorAction Stop | Out-Null
    }
    #===================================================================================================
    #   Compress-Archive
    #===================================================================================================
    $OSDDriverZipFile = "$PublishPath\$($DirectoryName).zip"
    if (Test-Path "$OSDDriverZipFile") {
        Write-Verbose "Compress-Archive: $OSDDriverZipFile ... exists!" -Verbose
    } else {
        Write-Verbose "Compress-Archive: $OSDDriverZipFile ... This may take a while"
        Compress-Archive -Path "$ExpandedDriverPath" -DestinationPath "$OSDDriverZipFile" -ErrorAction Stop
    }
    #===================================================================================================
    #   New-OSDDriverTask
    #===================================================================================================
    if (-not (Test-Path "$PublishPath\$DirectoryName.cabtask")) {
        Write-Warning "Use New-OSDDriverTask to create a Task for $OSDDriverZipFile"
        Write-Warning "e.g.: New-OSDDriverTask -OSDDriverFile '$OSDDriverZipFile'"
    } else {
        Write-Verbose "Publish: $PublishPath\$DirectoryName.cabtask ... exists!" -Verbose
    }
}