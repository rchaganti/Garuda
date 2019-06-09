function Get-GarudaTestGroup
{
    [CmdletBinding(DefaultParameterSetName = 'Group')]
    param 
    (
        [Parameter(ParameterSetName = 'Group')]
        [Parameter(Mandatory = $true,ParameterSetName = 'Copy')]
        [String]
        $GroupName,

        [Parameter(Mandatory = $true,ParameterSetName = 'Copy')]
        [String]
        $ParameterManifestPath
    )

    $testLibPath = "$(Split-Path -Path $PSScriptRoot -Parent)\TestLib"
    $testGroupJson = "$testLibPath\testGroup.json"
    if (Test-Path -Path $testGroupJson)
    {
        $testGroups = Get-Content -Path $testGroupJson -Raw | ConvertFrom-Json

        if ($PSCmdlet.ParameterSetName -eq 'Copy')
        {
            $testGroupParameterJson = Get-GarudaTestGroupParameter -GroupName $GroupName | ConvertTo-Json -Depth 99
            $testGroupParameterJson | Out-File -FilePath $ParameterManifestPath -Force
        }
        else 
        {
            if ($GroupName)
            {
                return $testGroups.Where({$_.Name -eq $GroupName})
            }
            else
            {
                return $testGroups    
            }
        }
    }
    else
    {
        Write-Warning -Message "$testGroupJson does not exist."    
    }
}
