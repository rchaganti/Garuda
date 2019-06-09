function Publish-GarudaTestPackage
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory = $true)]
        [String[]]
        $ComputerName,

        [Parameter(Mandatory = $true)]
        [String]
        $SharePath,

        [Parameter(Mandatory = $true)]
        [String]
        $TestGroupName,

        [Parameter(Mandatory = $true)]
        [String]
        $ParameterManifestPath,

        [Parameter(Mandatory = $true)]
        [String]
        $ModuleRepositoryPath,

        [Parameter(Mandatory = $true)]
        [String]
        $ModuleRepositoryName,

        [Parameter()]
        [Switch]
        $DoNotEnact
    )
    
    Process {
        $testLibPath = "$(Split-Path -Path $PSScriptRoot -Parent)\TestLib"

        # Copy the tests scripts
        $tests = (Get-GarudaTestGroup -GroupName $TestGroupName).Tests
        if (-not (Test-Path -Path "$SharePath\TestLib"))
        {
            $null = New-Item -Path "$SharePath\TestLib" -ItemType Directory -Force
        }

        # Copy Chakra script
        Copy-Item -Path "$(Split-Path -Path $PSScriptRoot -Parent)\Chakra" -Recurse -Destination "$SharePath\TestLib" -Force
        
        foreach ($test in $tests)
        {
            Copy-Item -Path "$testLibPath\${test}.Tests.ps1" -Destination "$SharePath\TestLib" -Force
        }

        # Copy the test parameter manifest
        Copy-Item -Path $ParameterManifestPath -Destination "$SharePath\TestLib\testParameters.json" -Force

        # Generate Config.ps1
        # Contains configuration data and all resource configuration
        $configurationScript = New-DscConfigurationScript -ComputerName $ComputerName -ParameterManifestPath $ParameterManifestPath -ModuleRepositoryPath $ModuleRepositoryPath -ModuleRepositoryName $ModuleRepositoryName -SharePath $SharePath -TestGroupName $TestGroupName

        if ($DoNotEnact)
        {
            # return configuration script text
            return $configurationScript
        }
        else
        {
            # compile and enact the configuration script
            # save the file to a temporary location
            Out-File -InputObject $configurationScript -FilePath "$env:Temp\config.ps1" -Force
            . "$env:Temp\config.ps1"

            Start-DscConfiguration -Path "$env:Temp\GarudaConfiguration" -Verbose -Wait -Force
        }
    }
}
