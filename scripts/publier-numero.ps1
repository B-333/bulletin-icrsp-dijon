<#
.SYNOPSIS
  Plomberie de publication d'un numéro du bulletin ICRSP Dijon.
.DESCRIPTION
  Phase 'prepare' : installe poppler si besoin, copie le PDF source vers _input.pdf.
  Phase 'publish' : copie le PDF sous le nom conventionnel, commit, push, vérifie les liens.
#>
param(
  [Parameter(Mandatory)][ValidateSet('prepare','publish')][string]$Phase,
  [string]$SourcePdfPath,
  [int]$Numero,
  [string]$MoisSlug
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

function Sync-Path {
  $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' +
              [Environment]::GetEnvironmentVariable('Path','User')
}

function Ensure-Poppler {
  Sync-Path
  if (Get-Command pdftoppm -ErrorAction SilentlyContinue) { return }
  Write-Host "Installation de poppler (pdftoppm) via winget..."
  winget install --id oschwartz10612.Poppler -e --accept-source-agreements --accept-package-agreements | Out-Null
  Sync-Path
  if (-not (Get-Command pdftoppm -ErrorAction SilentlyContinue)) {
    throw "pdftoppm introuvable apres installation. Installe poppler manuellement puis relance."
  }
}

if ($Phase -eq 'prepare') {
  if (-not $SourcePdfPath -or -not (Test-Path -LiteralPath $SourcePdfPath)) {
    throw "PDF source introuvable: $SourcePdfPath"
  }
  Ensure-Poppler
  Copy-Item -LiteralPath $SourcePdfPath -Destination (Join-Path $RepoRoot '_input.pdf') -Force
  $name = Split-Path $SourcePdfPath -Leaf
  $cand = if ($name -match '(\d+)') { $Matches[1] } else { '?' }
  $last = git log --oneline 2>$null | Select-String -Pattern 'Bulletin n.(\d+)' | Select-Object -First 1
  Write-Host "OK: _input.pdf pret."
  Write-Host "Numero candidat (nom de fichier): $cand"
  Write-Host "Dernier commit bulletin: $last"
  exit 0
}

# Phase publish
if (-not $Numero)    { throw "-Numero requis en phase publish" }
if (-not $MoisSlug)  { throw "-MoisSlug requis en phase publish" }
if (-not $SourcePdfPath -or -not (Test-Path -LiteralPath $SourcePdfPath)) {
  throw "PDF source introuvable: $SourcePdfPath"
}

$targetPdf = Join-Path $RepoRoot "bulletins/bulletin-icrsp-dijon-$MoisSlug.pdf"
Copy-Item -LiteralPath $SourcePdfPath -Destination $targetPdf -Force
Remove-Item (Join-Path $RepoRoot '_input.pdf') -ErrorAction SilentlyContinue

Sync-Path
git add -A
git commit -q -m "Bulletin n°$Numero — $MoisSlug"
git push -q

# Depot au format owner/name
$remote = git remote get-url origin
$repo = ($remote -replace '.*github\.com[:/]','') -replace '\.git$',''
$owner = ($repo -split '/')[0].ToLower()
$name  = ($repo -split '/')[1]
$base  = "https://$owner.github.io/$name"

Write-Host "Attente du build GitHub Pages..."
for ($i = 0; $i -lt 20; $i++) {
  $s = gh api "repos/$repo/pages" --jq '.status' 2>$null
  Write-Host "  build: $s"
  if ($s -eq 'built') { break }
  Start-Sleep -Seconds 15
}

$urls = @('/', '/archives.html',
          "/bulletins/bulletin-icrsp-dijon-$MoisSlug.html",
          "/bulletins/bulletin-icrsp-dijon-$MoisSlug.pdf")
$allOk = $true
foreach ($u in $urls) {
  try {
    $r = Invoke-WebRequest -Uri "$base$u" -Method Head -TimeoutSec 20
    Write-Host ("  {0,-50} {1}" -f $u, $r.StatusCode)
  } catch {
    $allOk = $false
    Write-Host ("  {0,-50} ERREUR {1}" -f $u, $_.Exception.Response.StatusCode.value__)
  }
}

if ($allOk) {
  Write-Host "`nPublie et verifie : $base/"
} else {
  Write-Host "`nATTENTION: au moins un lien ne repond pas 200."
  Write-Host "Revert possible: git revert HEAD  (puis git push)"
  exit 1
}
