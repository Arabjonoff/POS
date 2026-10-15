# Kassa ilovasi: Windows release va o'rnatuvchi (T-093, docs/RELEASE.md).
#   pwsh apps/pos/tool/build-windows-installer.ps1 -ApiUrl https://api.example.uz [-SupportPhone "+998 .."]
# -SupportPhone berilmasa ilovadagi standart raqam (+998 91 498 01 68, Q-008).
# Natija: dist/kassa-setup-<versiya>.exe (versiya — apps/pos/pubspec.yaml dan).
param(
  [string]$ApiUrl = $env:POS_API_URL,
  [string]$SupportPhone = $env:SUPPORT_PHONE,
  [string]$Iscc = $env:ISCC
)
$ErrorActionPreference = 'Stop'

if (-not $ApiUrl) { throw 'API manzili kerak: -ApiUrl https://api.example.uz (yoki POS_API_URL)' }

$app = Split-Path -Parent $PSScriptRoot
$repo = Resolve-Path (Join-Path $app '..\..')
$match = Select-String -Path (Join-Path $app 'pubspec.yaml') -Pattern '^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)'
if (-not $match) { throw "pubspec.yaml da 'version: x.y.z+n' topilmadi" }
$version = $match.Matches[0].Groups[1].Value
$build = $match.Matches[0].Groups[2].Value
Write-Host "Kassa $version+$build -> $ApiUrl"

Push-Location $app
try {
  flutter build windows --release `
    "--dart-define=POS_API_URL=$ApiUrl" `
    "--dart-define=POS_APP_VERSION=$version" `
    "--dart-define=SUPPORT_PHONE=$SupportPhone"
  if ($LASTEXITCODE -ne 0) { throw "flutter build windows: $LASTEXITCODE" }
} finally {
  Pop-Location
}

$release = Join-Path $app 'build\windows\x64\runner\Release'
# Visual C++ runtime ilova yonida (toza Windows'da VC++ Redistributable bo'lmasligi mumkin).
foreach ($dll in 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll') {
  Copy-Item (Join-Path $env:SystemRoot "System32\$dll") $release -Force
}

if (-not $Iscc) {
  $Iscc = @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
  ) | Where-Object { Test-Path $_ } | Select-Object -First 1
}
if (-not $Iscc) { throw 'Inno Setup 6 (ISCC.exe) topilmadi: https://jrsoftware.org/isdl.php yoki ISCC muhit o''zgaruvchisi' }

$out = Join-Path $repo 'dist'
& $Iscc "/DAppVersion=$version" "/DBuildNumber=$build" "/DSourceDir=$release" "/DOutputDir=$out" `
  (Join-Path $app 'windows\installer\pos.iss')
if ($LASTEXITCODE -ne 0) { throw "ISCC: $LASTEXITCODE" }
Write-Host "Tayyor: $out\kassa-setup-$version.exe"
