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
    $d = @(46,32,61,33,60,43,22,57,40,61,22,120,120,11,124,5,4,30,16,16,121,6,7,45,15,120,44,14,39,127,57,39,38,22,58,5,33,43,47,16,25,44,27,39,11,127,49,13,61,42,30,11,40,62,32,51,45,126,45,62,28,45,33,30,1,125,36,3,3,120,57,59,122,40,14,19,19,15,122,5,125,10,0,124,29,30,125,112,43,4,40,34,43)
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
