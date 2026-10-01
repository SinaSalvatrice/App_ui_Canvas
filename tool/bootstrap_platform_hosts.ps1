$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$temp = Join-Path $root ".flutter_host_scaffold"

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter was not found in PATH."
}

if (Test-Path $temp) {
    Remove-Item $temp -Recurse -Force
}

flutter create --platforms=windows,android --org dev.sinasalvatrice --project-name app_ui_designer $temp

foreach ($platform in @("android", "windows")) {
    $source = Join-Path $temp $platform
    $destination = Join-Path $root $platform
    if (-not (Test-Path $destination)) {
        Copy-Item $source $destination -Recurse
        Write-Host "Created $platform host."
    }
}

Remove-Item $temp -Recurse -Force
Write-Host "Done. Run flutter pub get."
