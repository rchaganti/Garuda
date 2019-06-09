function Get-TestParameterJson
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $TestLibPath
    )
    
    $testParameterJsonPath = "${testLibPath}\Tests.Parameters.Json"    
    
    if (Test-Path -Path $testLibPath)
    {
        $testParametersHash = [Ordered]@{}
        $allTestScripts = Get-ChildItem -Path $testLibPath *.tests.ps1
        foreach ($testScript in $allTestScripts)
        {
            $scriptName = $testScript.BaseName -replace '.Tests'
            $scriptParameters = Get-TestParameter -ScriptPath $testScript.FullName
            $testParametersHash.Add($scriptName, $scriptParameters)
        }
        $testParametersHash | ConvertTo-Json -Depth 100 | Out-File -FilePath $TestParameterJsonPath -Force
    }
}
