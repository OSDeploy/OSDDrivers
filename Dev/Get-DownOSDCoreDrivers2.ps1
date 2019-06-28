<#
.SYNOPSIS
Download software related to OS Deployment

.DESCRIPTION
Download software related to OS Deployment, including the ADK and MDT

.LINK
https://www.osdeploy.com/OSDDriver/docs/functions/get-OSDDriver

.PARAMETER Name
Name of the software to download

.PARAMETER DownloadPath
This is the path to download the updates

.EXAMPLE
Get-OSDDriver -Name 'Google Chrome Enterprise x64' -DownloadPath C:\Temp
Downloads googlechromestandaloneenterprise64.msi to C:\Temp
Alternatively, use the shorter command line
OSDDriver 'Google Chrome Enterprise x64' C:\Temp
#>
function Get-DownOSDCoreDrivers2 {
    [CmdletBinding()]
    PARAM (
        [Parameter(Position=0,Mandatory=$true)]
        [ValidateSet(`
            'Intel Graphics',`
            'Intel Wireless',`
            'Intel Bluetooth'
        )]
        [string]$Name,
        [Parameter(Position=1)]
        [string]$DownloadPath,
        [ValidateSet('Exe','Zip')]
        [string]$DownloadType,
        [ValidateSet('Win10 x64','Win7 x64','Win10 x86','Win7 x86')]
        [string]$DownloadSet
    )
    #===================================================================================================
    #   Variables
    #===================================================================================================
    $Global:OSDInfoUrl = $null
    $Global:OSDPageUrl = $null
    $Global:OSDDownloadUrl = $null
    $Global:OSDDownloadFileName = $null
    $Global:OSDDownloadMethod = $null
    #===================================================================================================
    #   Paths
    #===================================================================================================
    #{374DE290-123F-4565-9164-39C4925E467B}
    if (!($DownloadPath)) {$DownloadPath = [Environment]::GetFolderPath("Desktop")}
    if (!(Test-Path "$DownloadPath")) {New-Item -Path "$DownloadPath" -ItemType Directory -Force | Out-Null}
    #===================================================================================================
    #   Software
    #===================================================================================================
    if ($Name -eq 'Intel Graphics') {
        DownIntelGraphics
        Write-Host "Validating $OSDDownloadUrl" -ForegroundColor Cyan
        Write-Host ""
        $URLLinks = @()
        $URLLinks = (Invoke-WebRequest -Uri "$OSDDownloadUrl").Links
        $URLLinks = $URLLinks | Where-Object {$_.href -like "/download*"}

        $UrlDownloads = @()

        foreach ($URLLink in $URLLinks) {
            Write-Host "$($URLLink.innerText)"

            Write-Host "https://downloadcenter.intel.com$($URLLink.href)" -ForegroundColor Cyan
            $UrlDownload = (Invoke-WebRequest -Uri "https://downloadcenter.intel.com$($URLLink.href)").Links
            $UrlDownload = $UrlDownload | Where-Object {($_.'data-direct-path' -like "*.exe") -or ($_.'data-direct-path' -like "*.zip")}

            if ($DownloadType -eq 'exe') {$UrlDownload = $UrlDownload | Where-Object {$_.'data-direct-path' -like "*.exe"}}
            if ($DownloadType -eq 'zip') {$UrlDownload = $UrlDownload | Where-Object {$_.'data-direct-path' -like "*.zip"}}
            
            foreach ($Item in $UrlDownload) {
                if ($Item.'data-direct-path') {Write-Host "$($Item.'data-direct-path')"}
            }
            $UrlDownloads += $UrlDownload
            Write-Host ""
        }
        $UrlDownloads = $UrlDownloads | Select-Object -Property Title, 'data-direct-path' | Out-GridView -PassThru
    }
    if ($Name -eq 'Intel Wireless') {
        DownIntelWireless
        Write-Host "Validating $OSDDownloadUrl" -ForegroundColor Cyan
        Write-Host ""
        $URLLinks = @()
        $URLLinks = (Invoke-WebRequest -Uri "$OSDDownloadUrl").Links
        $URLLinks = $URLLinks | Where-Object {$_.href -like "*downloadcenter.intel.com/download*"}
        $URLLinks = $URLLinks | Select-Object -First 1

        foreach ($URLLink in $URLLinks) {
            $DriverVersion = $($URLLink.innerText)
            Write-Host "$($URLLink.innerText)"

            Write-Host "$($URLLink.href)" -ForegroundColor Cyan
            $UrlDownload = (Invoke-WebRequest -Uri "$($URLLink.href)").Links
            $UrlDownload = $UrlDownload | Where-Object {($_.'data-direct-path' -like "*.exe") -or ($_.'data-direct-path' -like "*.zip")}

            if ($DownloadType -eq 'exe') {$UrlDownload = $UrlDownload | Where-Object {$_.'data-direct-path' -like "*.exe"}}
            if ($DownloadType -eq 'zip') {$UrlDownload = $UrlDownload | Where-Object {$_.'data-direct-path' -like "*.zip"}}
            
            foreach ($Item in $UrlDownload) {
                if ($Item.'data-direct-path') {Write-Host "$($Item.'data-direct-path')"}
            }
            $UrlDownloads += $UrlDownload
            Write-Host ""
        }
        $UrlDownloads = $UrlDownloads | Select-Object -Property Title, 'data-direct-path' | Out-GridView -PassThru
    }





    if ($Name -eq 'Intel Bluetooth') {
        DownIntelEthernet
        $UrlSelection = (Invoke-WebRequest -Uri "$OSDDownloadUrl").Links
        $UrlSelection = $UrlSelection | Where-Object {$_.href -like "/download/*"}
        $UrlSelection = $UrlSelection | Select-Object -Property innerText, href | Out-GridView -PassThru
        
        
        $UrlDownload = (Invoke-WebRequest -Uri "$($UrlSelection.href)").Links
        
        $UrlDownload = $UrlDownload | Where-Object {$_.download -like "*.exe" -or $_.download -like "*.zip"}
        $UrlDownload = $UrlDownload | Select-Object -Property download
        $UrlDownload = $UrlDownload | Out-GridView -PassThru
    }

    #===================================================================================================
    #   Download
    #===================================================================================================
    foreach ($UrlDownload in $UrlDownloads) {
        $DownloadLink = $($UrlDownload.'data-direct-path')
        $OSDDownloadFileName = Split-Path -Path $DownloadLink -Leaf
        Write-Host "Download Link: $DownloadLink" -ForegroundColor Cyan
        Write-Host "Download Full Path: $DownloadPath\$OSDDownloadFileName" -ForegroundColor Cyan
        Write-Host "Download Method: $OSDDownloadMethod" -ForegroundColor Cyan

        if (Test-Path "$DownloadPath\$OSDDownloadFileName") {
            Write-Warning "$DownloadPath\$OSDDownloadFileName already exists!"
        } else {
            if ($OSDDownloadMethod -eq 'BITS') {
                Start-BitsTransfer -Source "$DownloadLink" -Destination "$DownloadPath"
            }
            if ($OSDDownloadMethod -eq 'WebClient') {
                Write-Warning "Downloading without progress ..."
                (New-Object System.Net.WebClient).DownloadFile("$UrlDownload", "$DownloadPath\$OSDDownloadFileName")
                #Start-BitsTransfer -Source $UrlDownload -Destination "$DownloadPath\$OSDDownloadFileName"
            }
            if ($OSDDownloadMethod -eq 'WebRequest') {
                #$DownloadFileName = [System.IO.Path]::GetFileName((Get-RedirectedUrl "$UrlDownload"))
                #Write-Host $DownloadFileName
                Invoke-WebRequest -Uri $UrlDownload -OutFile "$DownloadPath\$OSDDownloadFileName"
            }
        }
        Expand-Archive -Path "$DownloadPath\$OSDDownloadFileName" -DestinationPath "$DownloadPath\$Name $DriverVersion Win 10 x64"
    }
}