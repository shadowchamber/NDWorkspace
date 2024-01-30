Import-Module $PSScriptRoot\PSModules\d365f.dev\d365f.dev.psm1   

Test-VSRunning
Import-D365Tools

Write-Host "Stopping D365FO environment"
Stop-D365Environment

Mount-D365Modules

Write-Host "Starting D365FO environment"
Start-D365Environment