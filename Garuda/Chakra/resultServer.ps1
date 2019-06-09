$chakraPath = 'C:\testlib\chakra'

Import-Module Polaris -Force

# load routes
. "$chakraPath\results.ps1"

Start-Polaris -Port 8080 -HostName $env:computername