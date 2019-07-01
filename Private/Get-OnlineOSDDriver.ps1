function Get-OnlineOSDDriver {
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Display Intel','Wireless Intel')]
        [string]$DriverGroup
    )
    #===================================================================================================
    #   Get Online OSDDriver
    #===================================================================================================
    if ($DriverGroup -eq 'Display Intel') {$OnlineOSDDriver = Get-OnlineOSDDriverDisplayIntel}
    if ($DriverGroup -eq 'Wireless Intel') {$OnlineOSDDriver = Get-OnlineOSDDriverWirelessIntel}
    #===================================================================================================
    #   Return
    #===================================================================================================
    Return $OnlineOSDDriver
}