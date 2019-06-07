function New-DscConfigurationScript
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory = $true)]
        [String[]]
        $ComputerName,

        [Parameter(Mandatory = $true)]
        [String]
        $ParameterManifestPath,

        [Parameter(Mandatory = $true)]
        [String]
        $ModuleRepositoryPath,

        [Parameter(Mandatory = $true)]
        [String]
        $ModuleRepositoryName,

        [Parameter(Mandatory = $true)]
        [String]
        $SharePath,

        [Parameter(Mandatory = $true)]
        [String]
        $TestGroupName
    )

    [System.Text.StringBuilder] $sb = new-object System.Text.StringBuilder
    $testLibPath = "$(Split-Path -Path $PSScriptRoot -Parent)\TestLib"    
    $testParametersJson = Get-Content -Path "$testLibPath\Tests.Parameters.json" -Raw | ConvertFrom-Json

    #Add configuration block - Start
    $null = $sb.AppendFormat('{0} "{1}"', 'Configuration', 'GarudaConfiguration')
    $null = $sb.AppendLine()
    $null = $sb.AppendLine('{')

    $null = $sb.AppendLine('param')
    $null = $sb.AppendLine('(')

    # iterate and add all pscredential parameters if available
    $testParameters = Get-Content -Path $ParameterManifestPath -Raw | ConvertFrom-Json
    $tests = $testParameters.PSObject.Properties.Name

    $allCredParams = @()
    $allCredHash = @{}
    foreach ($test in $tests)
    {
        foreach ($param in $testParameters.$test.PSObject.Properties.Name)
        {
            $parameterType = "[$($testParametersJson.$test.Where({$_.Name -eq $param}).Type)]"
            if ($parameterType -eq '[psCredential]')
            {
                if ($allCredParams -notcontains $param)
                {
                    $allCredParams += $param
                    $allCredHash.Add($param, $testParameters.$test.$param)
                }
            }
        }
    }

    $addedParams = @()

    foreach ($param in $allCredParams)
    {
        if ($addedParams -notcontains $param)
        {
            $addedParams += $param
            $parameterName = $param

            $null = $sb.AppendLine('[Parameter(Mandatory = $true)]')
            $null = $sb.AppendLine($parameterType)
            $null = $sb.AppendFormat('${0}', $parameterName)

            if ($addedParams.Count -lt $allCredParams.count)
            {
                $null = $sb.Append(',')
                $null = $sb.AppendLine()
                $null = $sb.AppendLine()
            }
            else
            {
                $null = $sb.AppendLine()
            }
        }
    }

    $null = $sb.AppendLine(')')
    $null = $sb.AppendLine()

    #Add Import-DscResource commands
    $null = $sb.AppendLine('Import-DscResource -ModuleName PowerShellGet -ModuleVersion 2.1.4')
    $null = $sb.AppendLine('Import-DscResource -ModuleName GraniResource -ModuleVersion 3.7.11.0')
    $null = $sb.AppendLine('Import-DscResource -ModuleName ComputerManagementDsc -ModuleVersion 6.4.0.0')
    $null = $sb.AppendLine('Import-DscResource -ModuleName PSDesiredStateConfiguration')
    $null = $sb.AppendLine()

    # Add nodes
    $null = $sb.AppendLine('Node $AllNodes.NodeName {')

    # Add PowerShell Repository
    $null = $sb.AppendFormat("PSRepository {0}",$ModuleRepositoryName)
    $null = $sb.AppendLine()
    $null = $sb.AppendLine('{')
    $null = $sb.AppendFormat("Name = '{0}'",$ModuleRepositoryName)
    $null = $sb.AppendLine()
    $null = $sb.AppendFormat("PublishLocation = '{0}'",$ModuleRepositoryPath)
    $null = $sb.AppendLine()
    $null = $sb.AppendFormat("SourceLocation = '{0}'",$ModuleRepositoryPath)
    $null = $sb.AppendLine()
    $null = $sb.AppendLine("InstallationPolicy = 'Trusted'")
    $null = $sb.AppendLine('}')
    $null = $sb.AppendLine()

    # Add Pester module
    $null = $sb.AppendFormat("PSModule {0}",'Pester')
    $null = $sb.AppendLine()
    $null = $sb.AppendLine('{')
    $null = $sb.AppendFormat("Name = '{0}'",'Pester')
    $null = $sb.AppendLine()
    $null = $sb.AppendFormat("Repository = '{0}'",$ModuleRepositoryName)
    $null = $sb.AppendLine()
    $null = $sb.AppendFormat("SkipPublisherCheck = {0}",'$true')
    $null = $sb.AppendLine()
    $null = $sb.AppendFormat("Force = {0}",'$true')
    $null = $sb.AppendLine()
    $null = $sb.AppendLine('}')
    $null = $sb.AppendLine()

    # Add Polaris module
    $null = $sb.AppendFormat("PSModule {0}",'Polaris')
    $null = $sb.AppendLine()
    $null = $sb.AppendLine('{')
    $null = $sb.AppendFormat("Name = '{0}'",'Polaris')
    $null = $sb.AppendLine()
    $null = $sb.AppendFormat("Repository = '{0}'",$ModuleRepositoryName)
    $null = $sb.AppendLine()
    $null = $sb.AppendFormat("SkipPublisherCheck = {0}",'$true')
    $null = $sb.AppendLine()
    $null = $sb.AppendFormat("Force = {0}",'$true')
    $null = $sb.AppendLine()
    $null = $sb.AppendLine('}')
    $null = $sb.AppendLine()

    # Copy the test library, configuration file, and 
    $null = $sb.AppendFormat("File {0}",'TestLibrary')
    $null = $sb.AppendLine()
    $null = $sb.AppendLine('{')
    $null = $sb.AppendFormat("SourcePath = '{0}'", "$SharePath\TestLib")
    $null = $sb.AppendLine()
    $null = $sb.AppendFormat("DestinationPath = '{0}'", "C:\TestLib")
    $null = $sb.AppendLine()
    $null = $sb.AppendFormat("Recurse = {0}", '$true')
    $null = $sb.AppendLine()
    $null = $sb.AppendFormat("Type = '{0}'", 'Directory')
    $null = $sb.AppendLine()
    $null = $sb.AppendFormat("Force = {0}", '$true')
    $null = $sb.AppendLine()
    $null = $sb.AppendLine('}')

    # Add Credential Vault entries
    foreach ($cred in $allCredParams)
    {
        $null = $sb.AppendFormat("cCredentialManager {0}", $cred)
        $null = $sb.AppendLine()
        $null = $sb.AppendLine('{')
        $null = $sb.AppendFormat("InstanceIdentifier = '{0}'",$cred)
        $null = $sb.AppendLine()
        $null = $sb.AppendFormat("Target = '{0}'",$cred)
        $null = $sb.AppendLine()
        $null = $sb.AppendFormat('Credential = ${0}',$cred)
        $null = $sb.AppendLine()
        $null = $sb.AppendLine("Ensure = 'Present'")
        $null = $sb.AppendLine('}')
        $null = $sb.AppendLine()
    }

    #Add Scheduled Task to invoke Chakra Engine
    $null = $sb.AppendFormat("ScheduledTask '{0}'",$TestGroupName)
    $null = $sb.AppendLine()
    $null = $sb.AppendLine('{')
    $null = $sb.AppendFormat("TaskName = '{0}'", $TestGroupName)
    $null = $sb.AppendLine()
    $null = $sb.AppendFormat("ActionExecutable = '{0}'", 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe')
    $null = $sb.AppendLine()
    $null = $sb.AppendFormat("ActionArguments = '{0}'", "-File `"C:\TestLib\Chakra\chakra.ps1`"")
    $null = $sb.AppendLine()
    $null = $sb.AppendFormat("ScheduleType = '{0}'", 'Daily')
    $null = $sb.AppendLine()
    $null = $sb.AppendFormat("RepetitionDuration = '{0}'", 'Indefinitely')
    $null = $sb.AppendLine()
    $null = $sb.AppendLine('}')    

    # Close Node block
    $null = $sb.AppendLine('}')

    #Close Configuration Block 
    $null = $sb.AppendLine('}')

    # Add Configuration Data
    $null = $sb.AppendLine()
    $null = $sb.AppendLine('$configData = @{')
    $null = $sb.AppendLine('AllNodes = @(')
    $null = $sb.AppendLine('@{')
    $null = $sb.AppendLine("NodeName = '*'")
    $null = $sb.AppendFormat('PSDscAllowPlainTextPassword = {0}','$true')
    $null = $sb.AppendLine()
    $null = $sb.AppendLine('},')

    $nodeCount = 1
    foreach ($node in $ComputerName)
    {
        $null = $sb.AppendLine('@{')
        $null = $sb.AppendFormat('NodeName = "{0}"', $node)
        $null = $sb.AppendLine()    
        if ($nodeCount -lt $ComputerName.Count)
        {
            $null = $sb.AppendLine('},')
            $nodeCount += 1
        }
        else
        {
            $null = $sb.AppendLine('}')    
        }
    }
    $null = $sb.AppendLine(')')
    $null = $sb.AppendLine('}')

    # Add the credentials
    $credentialString = ''
    foreach ($cred in $allCredHash.keys)
    {
        $null = $sb.AppendLine()
        $null = $sb.AppendFormat("`${0}pwd = ConvertTo-SecureString '{1}' -AsPlainText -Force",$cred,$allCredHash.$cred.Password)
        $null = $sb.AppendLine()
        $null = $sb.AppendFormat('${0} = New-Object System.Management.Automation.PSCredential ("{1}", ${2}pwd)',$cred, $allCredHash.$cred.UserName,$cred)
        $null = $sb.AppendLine()

        $credentialString += "-{0} `${1} " -f $cred, $cred
    }

    # Add configuraton compile command
    $null = $sb.AppendLine()
    $null = $sb.AppendFormat('GarudaConfiguration -ConfigurationData $configData -OutputPath "$env:Temp\GarudaConfiguration" ')
    if ($credentialString)
    {
        $null = $sb.AppendLine($credentialString)
    }
    else
    {
        $null = $sb.AppendLine()
    }

    return $sb.ToString()
}
