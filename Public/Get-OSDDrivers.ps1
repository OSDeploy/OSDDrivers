<#
.SYNOPSIS
OSDDrivers Module

.DESCRIPTION
OSDDrivers Module

.LINK
https://osddrivers.osdeploy.com/module/functions/get-osddrivers
#>
function Get-OSDDrivers {
    [CmdletBinding()]
    Param (
        #Creates OSDDrivers directory structure
        #Directories are automatically created with first Import
        #Alias: Create
        [Alias('Create')]
        [switch]$CreatePaths,

        #Initializes OSDDrivers variables
        #This action will occur automatically if OSDDrivers variables are not set
        [switch]$Initialize,

        #Hides Write-Host output. Used when called from other functions
        #Alias: Silent
        [Alias('Silent')]
        [switch]$HideDetails,
        
        #Changes the path from the default of C:\OSDDrivers to the path specified
        #Alias: Path
        [Alias('Path','SetPath')]
        [ValidateNotNullOrEmpty()]
        [string]$SetHome,

        #Updates the OSDDrivers Module
        #Alias: Update
        [Alias('Update')]
        [switch]$UpdateModule
    )
    #===================================================================================================
    #   Initialize-OSDDrivers
    #===================================================================================================
    #Must initialize the OSDDrivers variables.  This will set all to defaults
    #If Home is not set, then we need to initialize as well
    if ($SetHome) {Initialize-OSDDrivers -SetHome $SetHome}
    elseif (($Initialize.IsPresent) -or (!($global:GetOSDDrivers.Home))) {Initialize-OSDDrivers}
    if (($(Get-ItemProperty "HKCU:\Software\OSDeploy").GetOSDDriversHome) -ne $global:GetOSDDriversHome) {Initialize-OSDDrivers}
    #===================================================================================================
    #   OSDDrivers.PSModule*
    #===================================================================================================
    $global:GetOSDDrivers.PSModuleOSD               = Get-Module -Name OSD | Select-Object *
    $global:GetOSDDrivers.PSModuleOSDDrivers        = Get-Module -Name OSDDrivers | Select-Object *
    #===================================================================================================
    #   OSDDrivers.Public*
    #===================================================================================================
    $global:GetOSDDrivers.PublicJson                = $null
    $global:GetOSDDrivers.PublicJsonURL             = "https://raw.githubusercontent.com/OSDeploy/OSD.Public/master/OSD.json"
    #===================================================================================================
    #   OSDDrivers.Version*
    #===================================================================================================
    $global:GetOSDDrivers.VersionOSD                = $global:GetOSDDrivers.PSModuleOSD.Version | Sort-Object | Select-Object -Last 1
    $global:GetOSDDrivers.VersionOSDPublic          = $global:GetOSDDrivers.VersionOSD
    
    $global:GetOSDDrivers.VersionOSDDrivers         = $global:GetOSDDrivers.PSModuleOSDDrivers.Version | Sort-Object | Select-Object -Last 1
    $global:GetOSDDrivers.VersionOSDDriversPublic   = $global:GetOSDDrivers.VersionOSDDrivers

    if (!($HideDetails.IsPresent)) {
        $StatusCode = try {(Invoke-WebRequest -Uri $global:GetOSDDrivers.PublicJsonURL -UseBasicParsing -DisableKeepAlive).StatusCode}
        catch [Net.WebException]{[int]$_.Exception.Response.StatusCode}
        if ($StatusCode -ne "200") {
            #Check Failed
        } else {
            $global:GetOSDDrivers.PublicJson               = Invoke-RestMethod -Uri $global:GetOSDDrivers.PublicJsonURL
            $global:GetOSDDrivers.VersionOSDPublic         = $global:GetOSDDrivers.PublicJson.OSD
            $global:GetOSDDrivers.VersionOSDDriversPublic  = $global:GetOSDDrivers.PublicJson.OSDDrivers
        }
    }
    #===================================================================================================
    #   Display Version Information
    #===================================================================================================
    if (!($HideDetails.IsPresent)) {
        if ($null -eq $global:GetOSDDrivers.PublicJson) {
            Write-Verbose "OSDDrivers $($global:GetOSDDrivers.VersionOSDDrivers) | OSD $($global:GetOSDDrivers.VersionOSD) | OFFLINE" -Verbose
        } else {
            if ($global:GetOSDDrivers.VersionOSD -ge $global:GetOSDDrivers.VersionOSDPublic) {
                Write-Host "OSD $($global:GetOSDDrivers.VersionOSD) " -ForegroundColor Green -NoNewline
            } else {
                Write-Host "OSD $($global:GetOSDDrivers.VersionOSD) " -ForegroundColor Yellow -NoNewline
            }
            Write-Host "| " -ForegroundColor White -NoNewline
            if ($global:GetOSDDrivers.VersionOSDDrivers -ge $global:GetOSDDrivers.VersionOSDDriversPublic) {
                Write-Host "OSDDrivers $($global:GetOSDDrivers.VersionOSDDrivers) " -ForegroundColor Green
            } else {
                Write-Host "OSDDrivers $($global:GetOSDDrivers.VersionOSDDrivers) " -ForegroundColor Yellow
            }
        }
    }
    #===================================================================================================
    #   Display OSDBulder Home Path
    #===================================================================================================
    if (!($HideDetails.IsPresent)) {
        Write-Host "Home        $global:GetOSDDriversHome"
        Write-Host "-Download   $global:SetOSDDriversPathDownload" -ForegroundColor Gray
        Write-Host "-Expand     $global:SetOSDDriversPathExpand" -ForegroundColor Gray
        Write-Host "-Packages   $global:SetOSDDriversPathPackages" -ForegroundColor Gray
        #Show-OSDDriversHomeMap
    }
    #===================================================================================================
    #   Verify Single Version of OSDDrivers
    #===================================================================================================
    if (($global:GetOSDDrivers.PSModuleOSDDrivers).Count -gt 1) {
        Write-Warning "Multiple OSDDrivers Modules are loaded"
        Write-Warning "Close all open PowerShell sessions before using OSDDrivers"
        Break
    }
    #===================================================================================================
    #   CreatePaths
    #===================================================================================================
    if ($CreatePaths.IsPresent) {
        if (!(Test-Path $global:GetOSDDriversHome)) {New-Item $global:GetOSDDriversHome -ItemType Directory -Force | Out-Null}
        if (!(Test-Path $global:SetOSDDriversPathDownload)) {New-Item $global:SetOSDDriversPathDownload -ItemType Directory -Force | Out-Null}
        if (!(Test-Path $global:SetOSDDriversPathExpand)) {New-Item $global:SetOSDDriversPathExpand -ItemType Directory -Force | Out-Null}
        if (!(Test-Path $global:SetOSDDriversPathPackages)) {New-Item $global:SetOSDDriversPathPackages -ItemType Directory -Force| Out-Null}
        Publish-OSDDriverScripts -PublishPath $global:SetOSDDriversPathPackages
    }
    #===================================================================================================
    #   Show-OSDDriversHome
    #===================================================================================================
    if ($HideDetails -eq $false) {
        #===================================================================================================
        #   Display Home Content
        #===================================================================================================
        if (!($HideDetails.IsPresent)) {
            #===================================================================================================
            #   Versioning
            #===================================================================================================
            if ($global:GetOSDDrivers.VersionOSD -gt $global:GetOSDDrivers.VersionOSDPublic) {
                Write-Host
                Write-Host "OSD Module Release Preview" -ForegroundColor Green
                Write-Host "The current Public version is $($global:GetOSDDrivers.VersionOSDPublic)" -ForegroundColor DarkGray
            } elseif ($global:GetOSDDrivers.VersionOSD -eq $global:GetOSDDrivers.VersionOSDPublic) {
                #Write-Host "OSD is up to date" -ForegroundColor Green
            } else {
                Write-Host
                Write-Warning "OSD can be updated to $($global:GetOSDDrivers.VersionOSDPublic)"
                Write-Host "Install-Module OSD -Force" -ForegroundColor Cyan
            }

            if ($global:GetOSDDrivers.VersionOSDDrivers -gt $global:GetOSDDrivers.VersionOSDDriversPublic) {
                Write-Host
                Write-Host "OSDDrivers Module Release Preview" -ForegroundColor Green
                Write-Host "The current Public version is $($global:GetOSDDrivers.VersionOSDDriversPublic)" -ForegroundColor DarkGray
            } elseif ($global:GetOSDDrivers.VersionOSDDrivers -eq $global:GetOSDDrivers.VersionOSDDriversPublic) {
                #Write-Host "OSDDrivers is up to date" -ForegroundColor Green
                #""
            } else {
                Write-Host
                Write-Warning "OSDDrivers can be updated to $($global:GetOSDDrivers.VersionOSDDriversPublic)"
                Write-Host "OSDDrivers -UpdateModule" -ForegroundColor Cyan
            }
            #===================================================================================================
            #   Links and Updates
            #===================================================================================================
            Write-Host ""
            Write-Host "Latest Updates:" -ForegroundColor Gray
            foreach ($line in $global:GetOSDDrivers.PublicJson.OSDDriversUpdates) {Write-Host $line -ForegroundColor DarkGray}
            Write-Host ""
            Write-Host "Helpful Links:" -ForegroundColor Gray
            foreach ($line in $global:GetOSDDrivers.PublicJson.OSDDriversHelp) {Write-Host $line -ForegroundColor DarkGray}
            Write-Host ""
            Write-Host "New Links:" -ForegroundColor Gray
            foreach ($line in $global:GetOSDDrivers.PublicJson.OSDDriversNew) {Write-Host $line -ForegroundColor DarkGray}
            #===================================================================================================
            #   Shortcuts
            #===================================================================================================
            Write-Host ''
            Write-Host "Shortcuts:" -ForegroundColor Gray
            Write-Host 'OSDDrivers -CreatePaths             '           -ForegroundColor DarkGray -NoNewline
            Write-Host 'Create OSDDrivers Directory Structure'          -ForegroundColor DarkGray
            Write-Host 'OSDDrivers -Initialize              '           -ForegroundColor DarkGray -NoNewline
            Write-Host 'Refresh OSDDrivers Variables and Settings'      -ForegroundColor DarkGray
            Write-Host 'OSDDrivers -SetHome D:\OSDDrivers   '           -ForegroundColor Green -NoNewline
            Write-Host 'Change OSDDrivers Home Path'                    -ForegroundColor Green
            Write-Host 'OSDDrivers -UpdateModule            '           -ForegroundColor DarkGray -NoNewline
            Write-Host 'Update the OSDDrivers Module'                   -ForegroundColor DarkGray
        
            Write-Host 'Update-OSDDriverMultiPack           '           -ForegroundColor DarkGray -NoNewline
            Write-Host 'Update existing MultiPacks'                     -ForegroundColor DarkGray
            Write-Host 'Update-OSDDriverScripts             '           -ForegroundColor DarkGray -NoNewline
            Write-Host 'Update existing Deployment Scripts'             -ForegroundColor DarkGray
        }
    }
    #===================================================================================================
    #   Update Module
    #===================================================================================================
    if ($UpdateModule.IsPresent) {
        Update-ModuleOSDDrivers
    }
}