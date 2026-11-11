param([switch]$Verify)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$project = Join-Path $repo 'work/player-sprite-lookdev-2026-11-10/import_project'
$asset = Join-Path $repo 'LocalOnly/OG_Export_Trial/OG_Base_Trial.glb'
$engine = Get-ChildItem -LiteralPath "${env:ProgramFiles(x86)}/Godot" -Recurse -Filter '*4.7.2*console.exe' |
    Select-Object -First 1 -ExpandProperty FullName
if (-not $engine) { throw 'Godot 4.7.2 was not found.' }
if (-not (Test-Path -LiteralPath $asset)) { throw 'Run tools/art/fit_og_base_trial.py in Blender first.' }
if (-not (Test-Path -LiteralPath (Join-Path $project 'project.godot'))) {
    throw 'Prepare the local Sprite Study project before launching the Chamber comparison.'
}

$argsForGame = @('--path', $project, '--script', 'res://tools/player_animation/og_base_trial.gd', '--rendering-method', 'forward_plus')
if ($Verify) { $argsForGame += @('--', '--verify') }
& $engine @argsForGame
exit $LASTEXITCODE
