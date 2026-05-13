param(
    [Parameter(Mandatory = $true)]
    [string]$Module,

    [string]$JavaHome = "C:\Program Files\Java\jdk-21.0.11"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

if (-not (Test-Path -LiteralPath $JavaHome)) {
    throw "JAVA_HOME nao encontrado em $JavaHome"
}

$env:JAVA_HOME = $JavaHome
$env:Path = "$JavaHome\bin;$env:Path"

. .\load-env.ps1
$env:RABBITMQ_HOST = "localhost"
$env:SPRING_RABBITMQ_HOST = "localhost"

switch ($Module) {
    "api-core" { $env:APP_PORT = "8080" }
    "realtime-gateway" { $env:APP_PORT = "9000" }
}

Write-Host "Subindo modulo $Module na porta APP_PORT=$env:APP_PORT"
.\gradlew.bat ":$Module`:bootRun"
