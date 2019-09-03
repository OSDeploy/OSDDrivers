function Show-OSDWmiQuery {
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline = $true)]
        [Object[]]$InputObject,

        [Parameter(Mandatory)]
        [ValidateSet ('Dell','HP')]
        [string]$Make = 'Dell',

        [Parameter(Mandatory)]
        [ValidateSet ('Model','SystemId')]
        [string]$Result,

        [switch]$ShowTextFile
    )

    BEGIN {$ComputerModels = @()}

    PROCESS {
        if ($InputObject) {
            $ModelPacks += $InputObject
            $ComputerModels = foreach ($ModelPack in $ModelPacks) {
                foreach ($item in $ModelPack.Model) {
                    $ObjectProperties = @{
                        Model = $item
                    }
                    New-Object -TypeName PSObject -Property $ObjectProperties
                }
            }
        } else {
            $ModelPacks = @()
            if ($Make -eq 'Dell'){$ModelPacks = Get-DellModelPack | Sort-Object Model -Unique}
            if ($Make -eq 'Hp'){$ModelPacks = Get-HpModelPack | Sort-Object Model -Unique}
            $ModelPacks = $ModelPacks | Select-Object Make, Model, Generation, SystemSku | Out-GridView -PassThru -Title 'Select Computer Models to Generate a WMI Query'
        }
    }

    END {
        $Items = @()
        #===================================================================================================
        #   Model
        #===================================================================================================
        if ($Result -eq 'Model') {
            foreach ($Item in $ModelPacks.Model) {$Items += $Item}
            $Items = $Items | Sort-Object -Unique
            $WmiCodePath = Join-Path -Path $env:TEMP -ChildPath "WmiQuery.txt"
            $WmiCodeString = [System.Text.StringBuilder]::new()
            [void]$WmiCodeString.AppendLine('SELECT Model FROM Win32_ComputerSystem WHERE')

            foreach ($Item in $Items) {
                [void]$WmiCodeString.AppendLine("Model = '$($Item)'")
    
                if ($Item -eq $Items[-1]){
                    #"last item in array is $Item"
                } else {
                    [void]$WmiCodeString.Append('OR ')
                }
            }
            $WmiCodeString.ToString() | Out-File -FilePath $WmiCodePath -Encoding UTF8
            if ($ShowTextFile.IsPresent) {
                notepad.exe $WmiCodePath
            }
            Return $WmiCodeString.ToString()
        }
        #===================================================================================================
        #   Dell SystemId
        #===================================================================================================
        if ($Result -eq 'SystemId' -and $Make -eq 'Dell') {
            foreach ($Item in $ModelPacks.SystemSku) {$Items += $Item}
            $Items = $Items | Sort-Object -Unique
            $WmiCodePath = Join-Path -Path $env:TEMP -ChildPath "WmiQuery.txt"
            $WmiCodeString = [System.Text.StringBuilder]::new()
            [void]$WmiCodeString.AppendLine('SELECT SystemSku FROM Win32_ComputerSystem WHERE')
        
            foreach ($Item in $Items) {
                [void]$WmiCodeString.AppendLine("SystemSku = '$($Item)'")
    
                if ($Item -eq $Items[-1]){
                    #"last item in array is $Item"
                } else {
                    [void]$WmiCodeString.Append('OR ')
                }
            }
            $WmiCodeString.ToString() | Out-File -FilePath $WmiCodePath -Encoding UTF8
            if ($ShowTextFile.IsPresent) {
                notepad.exe $WmiCodePath
            }
            Return $WmiCodeString.ToString()
        }
        #===================================================================================================
        #   HP SystemId
        #===================================================================================================
        if ($Result -eq 'SystemId' -and $Make -eq 'HP') {
            Write-Verbose "HP SystemId" -Verbose
            foreach ($Item in $ModelPacks.SystemSku) {$Items += $Item}

            $Items = $Items | Sort-Object -Unique
            $WmiCodePath = Join-Path -Path $env:TEMP -ChildPath "WmiQuery.txt"
            $WmiCodeString = [System.Text.StringBuilder]::new()
            [void]$WmiCodeString.AppendLine('SELECT Product FROM Win32_BaseBoard WHERE')
            foreach ($Item in $Items) {
                [void]$WmiCodeString.AppendLine("Product = '$($Item)'")
    
                if ($Item -eq $Items[-1]){
                    #"last item in array is $Item"
                } else {
                    [void]$WmiCodeString.Append('OR ')
                }
            }
            $WmiCodeString.ToString() | Out-File -FilePath $WmiCodePath -Encoding UTF8
            if ($ShowTextFile.IsPresent) {
                notepad.exe $WmiCodePath
            }
            Return $WmiCodeString.ToString()
        }
    }
}