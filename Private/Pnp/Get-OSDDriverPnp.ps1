function Get-OSDDriverPnp {
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory = $true,ValueFromPipelineByPropertyName = $true)]
        [string]$ExpandedDriverPath,
        [switch]$GeForce,
        [switch]$NoHardwareIdRev,
        [switch]$NoHardwareIdSubsys
    )
    #===================================================================================================
    #   Validate Admin Rights
    #===================================================================================================
    if ($Pack.IsPresent) {
        $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        If (!( $IsAdmin )) {
            Write-Warning "Elevation is required to generate Driver PNP files"
            Break
        }
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
            Select-Object -Property HardwareId,HardwareDescription,Version,ManufacturerName,`
            Architecture,ServiceName,CompatibleIds,ExcludeIds,Driver,Inbox,CatalogFile,ClassName,`
            ClassGuid,ClassDescription,BootCritical,DriverSignature,ProviderName,Date,MajorVersion,`
            MinorVersion,Build,Revision | Sort-Object HardwareId
        }
    }
    #===================================================================================================
    #   Filter
    #===================================================================================================
    #$OSDDriverPnp = $OSDDriverPnp | Where-Object {$_.HardwareId -notlike "SWC*"}
    $OSDDriverPnp = $OSDDriverPnp | Where-Object {$_.HardwareId -ne 'PCI\VEN_8086'}
    $OSDDriverPnp = $OSDDriverPnp | Where-Object {$_.HardwareId -notlike "{*"}
    if ($GeForce.IsPresent) {$OSDDriverPnp = $OSDDriverPnp | Where-Object {$_.HardwareDescription -match "GeForce"}}
    foreach ($Pnp in $OSDDriverPnp) {
        $Pnp.HardwareId = ($Pnp.HardwareId -split '\&CC')[0]
        if ($NoHardwareIdRev.IsPresent) {$Pnp.HardwareId = ($Pnp.HardwareId -split '\&REV')[0]}
        if ($NoHardwareIdSubsys.IsPresent) {$Pnp.HardwareId = ($Pnp.HardwareId -split '\&SUBSYS')[0]}
        #if ($Pnp.HardwareId -match 'PCI\\') {
            #$HardwareId = $Pnp.HardwareId -split '&'
            #$Pnp.HardwareId = "$($HardwareId[0])&$($HardwareId[1])"
        #}
    }
    $OSDDriverPnp = $OSDDriverPnp | Sort-Object HardwareId -Unique
    #===================================================================================================
    #   Return
    #===================================================================================================
    Return $OSDDriverPnp
}