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
    if ($DriverGroup -eq 'Display Intel') {$OnlineOSDDriver = Get-DriverGroupDisplayIntel}
    if ($DriverGroup -eq 'Wireless Intel') {$OnlineOSDDriver = Get-DriverGroupWirelessIntel}
    #===================================================================================================
    #   Return
    #===================================================================================================
    Return $OnlineOSDDriver
}