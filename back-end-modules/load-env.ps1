param(
    [string]$EnvFile = ".env"
)

if (-not (Test-Path -LiteralPath $EnvFile)) {
    Write-Error "Arquivo de ambiente nao encontrado: $EnvFile"
    exit 1
}

Get-Content -LiteralPath $EnvFile | ForEach-Object {
    $line = $_.Trim()

    if (-not $line -or $line.StartsWith("#")) {
        return
    }

    $parts = $line -split "=", 2
    if ($parts.Count -ne 2) {
        return
    }

    $name = $parts[0].Trim()
    $value = $parts[1]

    [Environment]::SetEnvironmentVariable($name, $value, "Process")
}

# Defaults uteis para desenvolvimento fora do Docker.
if (-not $env:SPRING_RABBITMQ_HOST -and $env:RABBITMQ_HOST) {
    [Environment]::SetEnvironmentVariable("SPRING_RABBITMQ_HOST", $env:RABBITMQ_HOST, "Process")
}

if (-not $env:SPRING_RABBITMQ_PORT -and $env:RABBITMQ_PORT) {
    [Environment]::SetEnvironmentVariable("SPRING_RABBITMQ_PORT", $env:RABBITMQ_PORT, "Process")
}

if (-not $env:SPRING_RABBITMQ_USERNAME -and $env:RABBITMQ_USER) {
    [Environment]::SetEnvironmentVariable("SPRING_RABBITMQ_USERNAME", $env:RABBITMQ_USER, "Process")
}

if (-not $env:SPRING_RABBITMQ_PASSWORD -and $env:RABBITMQ_PASSWORD) {
    [Environment]::SetEnvironmentVariable("SPRING_RABBITMQ_PASSWORD", $env:RABBITMQ_PASSWORD, "Process")
}

if (-not $env:SPRING_RABBITMQ_VIRTUAL_HOST -and $env:RABBITMQ_VHOST) {
    [Environment]::SetEnvironmentVariable("SPRING_RABBITMQ_VIRTUAL_HOST", $env:RABBITMQ_VHOST, "Process")
}

Write-Host "Variaveis de ambiente carregadas de $EnvFile para a sessao atual."
