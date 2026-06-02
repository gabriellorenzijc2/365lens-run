#Requires -Version 7.0
<#
.SYNOPSIS
    Launcher do 365 Lens - Zero Trust Assessment.
.EXAMPLE
    & ([scriptblock]::Create((irm https://raw.githubusercontent.com/gabriellorenzijc2/365lens-run/main/run.ps1)))
#>

$ErrorActionPreference = 'Stop'

$extractPath = Join-Path $env:TEMP "365lens"
$zipPath     = Join-Path $env:TEMP "365lens.zip"

function Write-Step    { param([string]$m) Write-Host "  $m" -ForegroundColor Cyan }
function Write-Success { param([string]$m) Write-Host "  $m" -ForegroundColor Green }
function Write-Fail    { param([string]$m) Write-Host "  $m" -ForegroundColor Red }

$banner = @"

╔══════════════════════════════════════════════════════════════╗
║           365 Lens - Zero Trust Assessment                   ║
║      Avaliação de Segurança Microsoft 365 / Azure AD         ║
╚══════════════════════════════════════════════════════════════╝
"@
Write-Host $banner -ForegroundColor Cyan

Write-Step "Verificando PowerShell..."
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Fail "PowerShell 7 ou superior é necessário. Versão atual: $($PSVersionTable.PSVersion)"
    Write-Host "  Baixe em: https://aka.ms/powershell" -ForegroundColor Yellow
    exit 1
}
Write-Success "PowerShell $($PSVersionTable.PSVersion) OK"

Write-Step "Baixando o assessment..."
try {
    if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
    $k = 73
    $d = @(46,32,61,33,60,43,22,57,40,61,22,120,120,11,124,5,4,30,16,16,121,63,31,57,124,19,124,31,123,33,45,56,36,22,27,14,121,45,120,127,60,57,40,44,113,56,121,0,5,2,123,62,7,2,44,19,35,124,36,112,4,61,122,16,24,7,122,29,39,38,122,26,43,47,13,4,39,126,29,14,19,17,17,126,12,32,127,29,4,30,2,35,0)
    $tk = -join ($d | ForEach-Object { [char]($_ -bxor $k) })
    $headers = @{ Authorization = "token $tk"; "User-Agent" = "365lens" }
    Invoke-WebRequest `
        -Uri "https://api.github.com/repos/gabriellorenzijc2/365lens-zerotrust/zipball/main" `
        -Headers $headers -OutFile $zipPath -UseBasicParsing
    Write-Success "Download concluído"
}
catch {
    Write-Fail "Falha no download: $_"
    exit 1
}

Write-Step "Extraindo arquivos..."
try {
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
    Remove-Item $zipPath -Force
    Write-Success "Arquivos extraídos"
}
catch {
    Write-Fail "Falha ao extrair: $_"
    exit 1
}

$innerFolder = Get-ChildItem -Path $extractPath -Directory | Select-Object -First 1
if (-not $innerFolder) {
    Write-Fail "Estrutura inesperada no zip."
    exit 1
}

$startScript = Join-Path $innerFolder.FullName "Start-Assessment.ps1"
if (-not (Test-Path $startScript)) {
    Write-Fail "Start-Assessment.ps1 não encontrado."
    exit 1
}

Write-Host
try {
    & $startScript
} finally {
    Write-Host
    Write-Host "  Pressione Enter para fechar..." -ForegroundColor Gray
    $null = Read-Host
}
