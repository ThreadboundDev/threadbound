$ErrorActionPreference = 'Stop'
$studyRoot = $PSScriptRoot
$repoRoot = (Resolve-Path (Join-Path $studyRoot '../..')).Path
$previewRoot = Join-Path $studyRoot 'import_project'
New-Item -ItemType Directory -Path $previewRoot -Force | Out-Null
foreach ($folder in @('Assets', 'Src', 'addons', 'tools')) {
    $linkPath = Join-Path $previewRoot $folder
    if (!(Test-Path -LiteralPath $linkPath)) {
        New-Item -ItemType Junction -Path $linkPath -Target (Join-Path $repoRoot $folder) | Out-Null
    }
}
$reviewLink = Join-Path $previewRoot 'review'
if (!(Test-Path -LiteralPath $reviewLink)) {
    New-Item -ItemType Junction -Path $reviewLink -Target $studyRoot | Out-Null
}
$cacheRoot = Join-Path $previewRoot '.godot'
New-Item -ItemType Directory -Path $cacheRoot -Force | Out-Null
$importLink = Join-Path $cacheRoot 'imported'
if (!(Test-Path -LiteralPath $importLink)) {
    New-Item -ItemType Junction -Path $importLink -Target (Join-Path $repoRoot '.godot/imported') | Out-Null
}
foreach ($cache in @('global_script_class_cache.cfg', 'uid_cache.bin')) {
    Copy-Item -LiteralPath (Join-Path $repoRoot ".godot/$cache") -Destination (Join-Path $cacheRoot $cache)
}
$project = [IO.File]::ReadAllText((Join-Path $repoRoot 'project.godot'))
$project = $project.Replace('config/name="Threadbound"', 'config/name="Threadbound Sprite Study 2026-11-10"')
if ($project.Contains('config/name="Threadbound"')) { throw 'Preview must use a separate save directory.' }
[IO.File]::WriteAllText((Join-Path $previewRoot 'project.godot'), $project)
Write-Output "Prepared isolated review project: $previewRoot"
