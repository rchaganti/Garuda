New-PolarisGetRoute -Path "/results/:groupName?" -Scriptblock {
    $chakraResultPath = "$env:ProgramData\Chakra"

    $Response.SetContentType('application/json')
    
    if ($Request.Parameters.groupName)
    {
        $groupName = $Request.Parameters.groupName
        $resultPath = "${chakraResultPath}\${groupName}.current.json"
        $resultJson = Get-Content -Path $resultPath
    }
    else 
    {
        $tmpResultJson = @()
        $allCurrentResultFiles = Get-ChildItem -Path $chakraResultPath *.current.json

        foreach ($resultFile in $allCurrentResultFiles)
        {
            $result = Get-Content -Path $resultFile.FullName -Raw | ConvertFrom-Json
            $tmpResultJson += $result
        }

        $resultJson = $tmpResultJson | ConvertTo-Json
    }

    $Response.Send($resultJson)
}