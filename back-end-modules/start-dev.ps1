param(
    [string]$JavaHome = "C:\Program Files\Java\jdk-21.0.11"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

function Get-ShellExecutable {
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwsh) {
        return $pwsh.Source
    }

    $powershell = Get-Command powershell -ErrorAction SilentlyContinue
    if ($powershell) {
        return $powershell.Source
    }

    throw "Nao foi possivel localizar pwsh.exe ou powershell.exe."
}

function Start-ModuleWindow {
    param(
        [string]$Module,
        [string]$ShellExecutable
    )

    $command = @"
Set-Location '$root'
`$host.UI.RawUI.WindowTitle = 'kyarem-$Module'
.\run-module.ps1 -Module '$Module' -JavaHome '$JavaHome'
"@

    Start-Process -FilePath $ShellExecutable -ArgumentList @("-NoExit", "-Command", $command) -WorkingDirectory $root
}

if (-not (Test-Path -LiteralPath $JavaHome)) {
    throw "JAVA_HOME nao encontrado em $JavaHome"
}

$env:JAVA_HOME = $JavaHome
$env:Path = "$JavaHome\bin;$env:Path"

. .\load-env.ps1
$env:RABBITMQ_HOST = "localhost"
$env:SPRING_RABBITMQ_HOST = "localhost"

Write-Host "Subindo RabbitMQ local..."
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d back-api-kyarem-rabbitmq

Write-Host "Aguardando RabbitMQ ficar healthy..."
for ($i = 1; $i -le 30; $i++) {
    $status = docker inspect -f "{{.State.Health.Status}}" back-api-kyarem-rabbitmq 2>$null
    if ($status -eq "healthy") {
        Write-Host "RabbitMQ healthy."
        break
    }

    Start-Sleep -Seconds 2

    if ($i -eq 30) {
        throw "RabbitMQ nao ficou healthy a tempo."
    }
}

$shell = Get-ShellExecutable
$modules = @(
    "api-core",
    "outbox-publisher",
    "projection-worker",
    "metrics-worker",
    "realtime-gateway"
)

foreach ($module in $modules) {
    Write-Host "Abrindo janela para $module..."
    Start-ModuleWindow -Module $module -ShellExecutable $shell
    Start-Sleep -Seconds 1
}

Write-Host ""
Write-Host "Ambiente de desenvolvimento iniciado."
Write-Host "URLs:"
Write-Host "  API health:        http://127.0.0.1:8080/actuator/health"
Write-Host "  Swagger UI:        http://127.0.0.1:8080/swagger-ui"
Write-Host "  Realtime health:   http://127.0.0.1:9000/events/health"
Write-Host "  RabbitMQ UI:       http://127.0.0.1:15672"
