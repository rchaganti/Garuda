# Import Pester module
Import-Module -Name Pester -Force

# load test parameters
$testPath = 'C:\testLib'
$testParameters = Get-Content -Path "$testPath\testParameters.json" -Raw | ConvertFrom-Json

$tests = $testParameters.PSObject.Properties.Name.Where({$_ -ne 'GroupName'})
$testGroup = $testParameters.GroupName

$testResults = [Ordered]@{
    TestGroup = $testParameters.GroupName
    Timestamp = (Get-Date -Format 'MM-dd-yyyyHHmmss')
}

foreach ($test in $tests)
{
    $testScript = "${testPath}\${test}.tests.ps1"
    
    # retireve parameters for test
    $tmpParameters = $testParameters.$test
    $parameters = @{}
    foreach ($param in $tmpParameters.PSObject.Properties.Name)
    {
        $parameters.Add($param, $tmpParameters.$param)
    }

    # invoke test script
    $tmpResults = Invoke-Pester @{
                    Path = $testScript
                    Parameters = $parameters
                } -PassThru

    # add to the results object
    $testResults.Add($test, $tmpResults)
}

# Export the results to JSON; rename current to time-stamped json and save as current.json
$resultPath = "$env:ProgramData\Chakra"
if (-not (Test-Path -Path $resultPath))
{
    $null = New-Item -Path $resultPath -ItemType Directory -Force
}


if (Test-Path -Path "${resultPath}\${testGroup}.current.json")
{
    # load the current json and read its timestamp
    $tmpResultObject = Get-Content -Path "${resultPath}\${testGroup}.current.json" -Raw | ConvertFrom-Json
    $tmpTimeStamp = $tmpResultObject.Timestamp
       
    # rename current.JSON to <timestamp>.json
    Rename-Item -Path "${resultPath}\${testGroup}.current.json" -NewName "${resultPath}\${testGroup}.${tmpTimeStamp}.json"
}

# save the current results to current.json
$testResults | ConvertTo-Json -Depth 100 | Out-File -FilePath "${resultPath}\${testGroup}.current.json" -Force