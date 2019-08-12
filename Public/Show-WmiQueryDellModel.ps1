function Show-WmiQueryDellModel {
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline = $true)]
        [Object[]]$InputObject,
        [switch]$ShowTxt
    )

    BEGIN {
        $DellModels = @()
    }

    PROCESS {
        if ($InputObject) {
            $DellModelPack += $InputObject
            $DellModels = foreach ($DellModel in $DellModelPack) {
                foreach ($item in $DellModel.Model) {
                    $ObjectProperties = @{
                        Model = $item
                    }
                    New-Object -TypeName PSObject -Property $ObjectProperties
                }
            }
        } else {
            $DellModelPack = @()
            $DellModelPack = Get-DellModelPack | Sort-Object Model -Unique
            $DellModels = foreach ($DellModel in $DellModelPack) {
                foreach ($item in $DellModel.Model) {
                    $ObjectProperties = @{
                        Manufacturer = $DellModel.Make
                        Model = $item
                        Generation = $DellModel.Generation
                    }
                    New-Object -TypeName PSObject -Property $ObjectProperties
                }
            }
        
            $DellModels = $DellModels | Select-Object Manufacturer, Model, Generation | Out-GridView -PassThru -Title 'Select Dell Models to Generate a WMI Query'
        }
    }

    END {
        if ($DellModels) {
            $DellModels = $DellModels | Sort-Object Model -Unique
            $WmiCodePath = Join-Path -Path $env:TEMP -ChildPath "WmiQueryDellModel.txt"
            
            $WmiCodeString = [System.Text.StringBuilder]::new()
            [void]$WmiCodeString.AppendLine('SELECT Model FROM Win32_ComputerSystem WHERE')
        
            foreach ($DellModel in $DellModels) {
                [void]$WmiCodeString.AppendLine("Model = '$($DellModel.Model)'")
                if ($DellModel -eq $DellModels[-1]){
                    #"last item in array is $Item"
                } else {
                    [void]$WmiCodeString.Append('OR ')
                }
            }
            $WmiCodeString.ToString() | Out-File -FilePath $WmiCodePath -Encoding UTF8
            if ($ShowTxt.IsPresent) {
                notepad.exe $WmiCodePath
            }
            Return $WmiCodeString.ToString()
        }
    }
}