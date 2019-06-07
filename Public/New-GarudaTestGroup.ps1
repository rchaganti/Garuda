function New-GarudaTestGroup
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory = $true)]
        [string]
        $GroupName,

        [Parameter(Mandatory = $true)]
        [string]
        $GroupDescription
    )

    DynamicParam
    {
        $testLibPath = "$(Split-Path -Path $PSScriptRoot -Parent)\TestLib"
        $testCollection = Get-ChildItem -Recurse $testLibPath *.Tests.PS1 | 
                    Select-Object -ExpandProperty BaseName | ForEach-Object { $_.replace('.Tests','') }
    
        $attribute = New-Object System.Management.Automation.ParameterAttribute
        $attribute.Position = 3
        $attribute.Mandatory = $true
        $attribute.HelpMessage = "Select the tests that you want to be in the Chakra group"

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

    Process {
        $existingGroups = Get-GarudaTestGroup
        if ($existingGroups.Name -notcontains $GroupName)
        {
            $testGroupObject = [PSCustomObject]@{
                Name = $GroupName
                Description = $GroupDescription
                Tests = $PSBoundParameters['tests']
            }

            $testGroupJsonPath = "$testLibPath\testGroup.json"
            if (Test-Path -Path $testGroupJsonPath)
            {
                $groupJsonObj = Get-Content -Path $testGroupJsonPath -raw | ConvertFrom-Json
                $groupJsonObj += $testGroupObject
            }
            else
            {
                $groupJsonObj = @(
                    $testGroupObject
                )    
            }

            ConvertTo-Json -InputObject $groupJsonObj | Out-File -FilePath $testGroupJsonPath -Force
            return $groupJsonObj
        }
        else
        {
            throw 'A test group with specified name already exists.'    
        }

        # Generate the test group parameters
        # $testGroupParameterJsonPath = "$testLibPath\$GroupName.parameters.json"
        # $testGroupParameter = Get-GarudaTestGroupParameter -GroupName $GroupName

        #ConvertTo-Json -InputObject $testGroupParameter | Out-File -FilePath $testGroupParameterJsonPath -Force
    }
}
