function Get-TestParameter
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ScriptPath
    )

    $scriptContent = Get-Content $ScriptPath -Raw

    $tokens = $null
    $errors = $null

    $ast = [Management.Automation.Language.Parser]::ParseInput($scriptContent, [ref]$tokens, [ref]$errors)
    $parameters = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.ParameterAst] }, $true)

    $paramterMetaData = @()
    foreach ($parameter in $parameters)
    {
        $parameterHash = @{
            Name = $parameter.Name.VariablePath.UserPath
            Type = $parameter.StaticType.Name
            DefaultValue = $parameter.DefaultValue.Value
            HelpMessage = $parameter.Attributes.NamedArguments.Where({$_.ArgumentName -eq 'HelpMessage'}).Argument.Value | Select -First 1
            ParameterSet = @($parameter.Attributes.NamedArguments.Where({$_.ArgumentName -eq 'ParameterSetName'}).Argument.Value)
            IsMandatory = [bool]($parameter.Attributes.NamedArguments.Where({$_.ArgumentName -eq 'Mandatory'}).Argument.Extent.text)
        }

        $paramterMetaData += $parameterHash
    }

    return $paramterMetaData
}
