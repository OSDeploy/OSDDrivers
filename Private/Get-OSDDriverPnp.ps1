function Get-OSDDriverPnp {
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory = $true,ValueFromPipelineByPropertyName = $true)]
        [string]$ExpandedDriverPath
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

    $OSDDriverPnp = @()

    if (Test-Path "$ExpandedDriverPath") {
        Get-ChildItem "$ExpandedDriverPath" autorun.inf -Recurse | ForEach-Object {
            $RenameMessage = "$(Get-Date) Renaming $($_.FullName) to $($_.Name).txt"
            Add-Content -Path "$ExpandedDriverPath\OSDDriver-Renames.txt" -Value $RenameMessage
            Write-Warning "Get-OSDDriverPnp: $RenameMessage"
            $_ | Rename-Item -NewName $_.Name.Replace('.inf', '.txt') -Force
        }

        Get-ChildItem "$ExpandedDriverPath" setup.inf -Recurse | ForEach-Object {
            $RenameMessage = "$(Get-Date) Renaming $($_.FullName) to $($_.Name).txt"
            Add-Content -Path "$ExpandedDriverPath\OSDDriver-Renames.txt" -Value $RenameMessage
            Write-Warning "Get-OSDDriverPnp: $RenameMessage"
            $_ | Rename-Item -NewName $_.Name.Replace('.inf', '.txt') -Force
        }

        $ExpandInfs = Get-ChildItem -Path "$ExpandedDriverPath" -Recurse -Include *.inf -File | Where-Object {$_.Name -notlike "*autorun.inf*"} | Select-Object -Property FullName
        foreach ($ExpandInf in $ExpandInfs) {
            Write-Host "Process: $($ExpandInf.FullName)" -ForegroundColor DarkGray

            $OSDDriverPnp += Get-WindowsDriver -Online -Driver "$($ExpandInf.FullName)" | `
            Select-Object -Property HardwareId,Version,ManufacturerName,HardwareDescription,`
            Architecture,ServiceName,CompatibleIds,ExcludeIds,Driver,Inbox,CatalogFile,ClassName,`
            ClassGuid,ClassDescription,BootCritical,DriverSignature,ProviderName,Date,MajorVersion,`
            MinorVersion,Build,Revision | Sort-Object HardwareId
        }
    }
    #===================================================================================================
    #   Return
    #===================================================================================================
    Return $OSDDriverPnp
}