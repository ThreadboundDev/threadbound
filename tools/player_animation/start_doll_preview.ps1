param([switch]$Blue)
$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$engine = Get-ChildItem -LiteralPath "${env:ProgramFiles(x86)}\Godot" -Recurse -Filter '*console.exe' |
    Where-Object Name -Like '*4.7.2*' | Select-Object -First 1 -ExpandProperty FullName
if (-not $engine) { throw 'Godot 4.7.2 was not found.' }
$model = Join-Path $repositoryRoot 'Assets/Threadborne/Player/LocalDoll/threadborne_doll_equipped.glb'
if (-not (Test-Path -LiteralPath $model)) {
    throw 'Build the local doll first with Blender and tools/art/prepare_doll_game_model.py.'
}
$scene = if ($Blue) { 'res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn' } else { 'res://Src/Environment/World/Chamber Of The First Weave.tscn' }
& $engine --path $repositoryRoot $scene -- --doll-preview
