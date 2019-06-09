function Get-GarudaTestGroupResult
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ComputerName,

        [Parameter()]
        [String]
        $TestGroupName
    )

    $url = "http://${ComputerName}:8080/results/"

    if ($TestGroupName)
    {
        $url += "$TestGroupName"
    }

    $results = Invoke-RestMethod -Uri $url -UseBasicParsing -Verbose
    return $results
}