function Get-DownDisplayIntel {
    [CmdletBinding()]
    Param ()
    $Global:OSDInfoUrl = $null
    $Global:OSDDownloadUrl = 'https://downloadcenter.intel.com/product/80939/Graphics-Drivers'
    $Global:OSDPageUrl = $null
    $Global:OSDDownloadFileName = ''
    $Global:OSDDownloadMethod = 'BITS'
    $Global:DriverClass = 'Display'
    $Global:DriverClassGUID = '{4D36E968-E325-11CE-BFC1-08002BE10318}'
}
function Get-DownDisplayIntelLinks {
    [CmdletBinding()]
    Param ()
    $URLLinks = $URLLinks | Select-Object -Property innerText, href
    $URLLinks = $URLLinks | Where-Object {$_.innerText -notlike "*Beta*"}
    $URLLinks = $URLLinks | Where-Object {$_.innerText -notlike "*embedded*"}
    $URLLinks = $URLLinks | Where-Object {$_.innerText -notlike "*exe*"}
    $URLLinks = $URLLinks | Where-Object {$_.innerText -notlike "*production*"}
    $URLLinks = $URLLinks | Where-Object {$_.innerText -notlike "*Radeon*"}
    $URLLinks = $URLLinks | Where-Object {$_.innerText -notlike "*Windows XP*"}
    $URLLinks = $URLLinks | Where-Object {$_.innerText -notlike "*XP32*"}
    $URLLinks = $URLLinks | Where-Object {$_.href -like "/download*"}
    foreach ($URLLink in $URLLinks) {
        $URLLink.innerText = ($URLLink).innerText.replace('][',' ')
        $URLLink.innerText = $URLLink.innerText -replace '[[]', ''
        $URLLink.innerText = $URLLink.innerText -replace '[]]', ''
        $URLLink.innerText = $URLLink.innerText -replace '[®]', ''
        $URLLink.innerText = $URLLink.innerText -replace '[*]', ''
    }

    foreach ($URLLink in $URLLinks) {
        if ($URLLink.innerText -like "*Graphics Media Accelerator*") {$URLLink.innerText = 'Intel Graphics MA'} #Win7
        if ($URLLink.innerText -like "*HD Graphics*") {$URLLink.innerText = 'Intel Graphics HD'} #Win7
        if ($URLLink.innerText -like "*15.33*") {$URLLink.innerText = 'Intel Graphics 15.33'} #Win7 #Win10
        if ($URLLink.innerText -like "*15.36*") {$URLLink.innerText = 'Intel Graphics 15.36'} #Win7
        if ($URLLink.innerText -like "*Intel Graphics Driver for Windows 15.40*") {$URLLink.innerText = 'Intel Graphics 15.40'} #Win7
        if ($URLLink.innerText -like "*15.40 6th Gen*") {$URLLink.innerText = 'Intel Graphics 15.40 G6'} #Win7
        if ($URLLink.innerText -like "*15.40 4th Gen*") {$URLLink.innerText = 'Intel Graphics 15.40 G4'} #Win10
        if ($URLLink.innerText -like "*15.45*") {$URLLink.innerText = 'Intel Graphics 15.45'} #Win7
        if ($URLLink.innerText -like "*DCH*") {$URLLink.innerText = 'Intel Graphics DCH'} #Win10
        $URLLink.href = "https://downloadcenter.intel.com$($URLLink.href)"
    }
    #===================================================================================================
    #   Exclude Drivers
    #===================================================================================================
    $URLLinks = $URLLinks | Where-Object {$_.innerText -notlike "*Intel Graphics 15.40 G4*"}
    $URLLinks = $URLLinks | Where-Object {$_.innerText -notlike "*Intel Graphics 15.40 G6*"}

    Return $URLLinks
}
function Get-DownWirelessIntel {
    [CmdletBinding()]
    Param ()
    $Global:OSDInfoUrl = $null
    $Global:OSDDownloadUrl = 'https://www.intel.com/content/www/us/en/support/articles/000017246/network-and-i-o/wireless-networking.html'
    $Global:OSDPageUrl = $null
    $Global:OSDDownloadFileName = ''
    $Global:OSDDownloadMethod = 'BITS'
    $Global:DriverClass = 'Net'
    $Global:DriverClassGUID = '{4D36E972-E325-11CE-BFC1-08002BE10318}'
}
function Get-DownWirelessIntelLinks {
    [CmdletBinding()]
    Param ()
    $URLLinks = $URLLinks | Select-Object -Property innerText, href
    $URLLinks = $URLLinks | Where-Object {$_.href -like "*downloadcenter.intel.com/download*"}
    $URLLinks = $URLLinks | Select-Object -First 1
    Return $URLLinks
}

function Get-DownWirelessNetworking {
    [CmdletBinding()]
    Param ()
    $Global:OSDInfoUrl = $null
    $Global:OSDDownloadUrl = 'https://downloadcenter.intel.com/product/59485/Wireless-Networking'
    $Global:OSDPageUrl = $null
    $Global:OSDDownloadFileName = ''
    $Global:OSDDownloadMethod = 'BITS'
    $Global:DriverClass = 'Net'
    $Global:DriverClassGUID = '{4D36E972-E325-11CE-BFC1-08002BE10318}'
}


function Get-DownWirelessNetworkingLinks {
    [CmdletBinding()]
    Param ()
    $URLLinks = $URLLinks | Select-Object -Property innerText, href
    $URLLinks = $URLLinks | Where-Object {$_.innerText -notlike "*exe*"}
    $URLLinks = $URLLinks | Where-Object {$_.innerText -notlike "*bluetooth*"}
    
    $URLLinks = $URLLinks | Where-Object {$_.href -like "/download*"}
    foreach ($URLLink in $URLLinks) {
        $URLLink.innerText = ($URLLink).innerText.replace('][',' ')
        $URLLink.innerText = $URLLink.innerText -replace '[[]', ''
        $URLLink.innerText = $URLLink.innerText -replace '[]]', ''
        $URLLink.innerText = $URLLink.innerText -replace '[®]', ''
        $URLLink.innerText = $URLLink.innerText -replace '[*]', ''
    }

    foreach ($URLLink in $URLLinks) {
        $URLLink.href = "https://downloadcenter.intel.com$($URLLink.href)"
    }
    #===================================================================================================
    #   Exclude Drivers
    #===================================================================================================


    Return $URLLinks
}
















function Get-DownNetIntelBluetooth {
    $Global:OSDInfoUrl = $null
    $Global:OSDDownloadUrl = 'https://www.intel.com/content/www/us/en/support/articles/000005773/network-and-i-o/wireless-networking.html'
    $Global:OSDPageUrl = $null
    $Global:OSDDownloadFileName = ''
    $Global:OSDDownloadMethod = 'BITS'
}