function Get-GarudaTestGroupParameter
{
    [CmdletBinding(DefaultParameterSetName = 'TestGroup')]
    param
    (
        [Parameter(ParameterSetName = 'TestGroup',Mandatory = $true)]
        [Parameter(ParameterSetName = 'Tests')]
        [string]
        $GroupName,

        [Parameter(ParameterSetName = 'TestGroup',Mandatory = $true)]
        [Parameter(ParameterSetName = 'Tests',Mandatory = $true)]
        [string]
        $SaveAs
    )

    DynamicParam
    {
        $testLibPath = "$(Split-Path -Path $PSScriptRoot -Parent)\TestLib"
        $testCollection = Get-ChildItem -Recurse $testLibPath *.Tests.PS1 | 
                    Select-Object -ExpandProperty BaseName | ForEach-Object { $_.replace('.Tests','') }
    
        $attribute = New-Object System.Management.Automation.ParameterAttribute
        $attribute.Position = 3
        $attribute.Mandatory = $false
        $attribute.ParameterSetName = 'Tests'
        $attribute.HelpMessage = "Select the tests for which the configuration data needs to be generated"

        $attributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        $attributeCollection.Add($attribute)

        $validateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($testCollection)
        $attributeCollection.Add($validateSetAttribute)

        #add our paramater specifying the attribute collection
        $param = New-Object System.Management.Automation.RuntimeDefinedParameter('Tests', [String[]], $attributeCollection)

        #expose the name of our parameter
        $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $paramDictionary.Add('Tests', $param)
        return $paramDictionary
    }
    
    process {
        switch ($PSCmdlet.ParameterSetName)
        {
            "TestGroup" {
                # Get all tests for the group
                $testGroupJsonPath = "$testLibPath\testGroup.json"
                if (Test-Path -Path $testGroupJsonPath)
                {
                    $testGroupJson = Get-Content -Path $testGroupJsonPath -Raw | ConvertFrom-Json
                    if ($testGroupJson.where({$_.Name -eq $GroupName}))
                    {
                        $selectedTests = $testGroupJson.where({$_.Name -eq $GroupName}).Tests
                    }
                }
            }

            "Tests" {
                $selectedTests = $PSBoundParameters['tests']
            }
        }

        $testParameters = [Ordered]@{
            GroupName = $GroupName
        }
        
        $testParametersJson = Get-Content -Path "$testLibPath\Tests.Parameters.Json" -Raw | ConvertFrom-Json
        foreach ($test in $selectedTests)
        {
            # Get the test parameters and create the object 
            $parameters = [Ordered]@{}           
            $requiredParameters = $testParametersJson.$test
            foreach ($parameter in $requiredParameters)
            {
                if ($parameter.Type -eq 'String[]' -or $parameter.Type -eq 'int32[]')
                {
                    if ($null -ne $param.DefaultValue)
                    {
                        $defaultValue = @($parameter.DefaultValue)
                    }
                    else
                    {
                        $defaultValue = @()
                    }
                }
                elseif ($parameter.Type -eq 'psCredential')
                {
                    $defaultValue = [Ordered]@{
                        UserName = ''
                        Password = ''
                    }    
                }
                else
                {
                    if ($null -ne $parameter.DefaultValue)
                    {
                        $defaultValue = $parameter.DefaultValue
                    }
                    else
                    {
                        $defaultValue = ''
                    }
                }
                $parameters.Add($parameter.Name,$defaultValue)
            }
            $testParameters.Add($test, $parameters)
        }
        
        $testParameters | ConvertTo-Json | Out-File -FilePath $SaveAs -Force
    }    
}
