function Update-GarudaTestParameter
{
    [CmdletBinding()]
    param 
    (

    )

    $testLibPath = "$(Split-Path -Path $PSScriptRoot -Parent)\TestLib"
    Get-TestParameterJson -TestLibPath $testLibPath
}
