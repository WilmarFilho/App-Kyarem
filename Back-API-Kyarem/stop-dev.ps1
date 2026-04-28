$ErrorActionPreference = "SilentlyContinue"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$patterns = @(
    ":api-core:bootRun",
    ":outbox-publisher:bootRun",
    ":projection-worker:bootRun",
    ":metrics-worker:bootRun",
    ":realtime-gateway:bootRun",
    "run-module.ps1 -Module 'api-core'",
    "run-module.ps1 -Module 'outbox-publisher'",
    "run-module.ps1 -Module 'projection-worker'",
    "run-module.ps1 -Module 'metrics-worker'",
    "run-module.ps1 -Module 'realtime-gateway'"
)

Get-CimInstance Win32_Process |
    Where-Object {
        $process = $_
        $matchesPattern = $patterns | Where-Object {
            $process.CommandLine -and $process.CommandLine -like "*$_*"
        }

        $process.Name -match "java|java\.exe|cmd\.exe|powershell\.exe|pwsh\.exe" -and $matchesPattern.Count -gt 0
    } |
    ForEach-Object {
        Stop-Process -Id $_.ProcessId -Force
    }

docker compose -f docker-compose.yml -f docker-compose.dev.yml stop back-api-kyarem-rabbitmq

Write-Host "Ambiente local encerrado."
