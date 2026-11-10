param(
    [Parameter(Mandatory=$true)][string]$Godot,
    [string]$BuildId = (Get-Date -Format 'yyyy-MM-dd-HHmm')
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$output = Join-Path $repo "Builds/current-$BuildId"
$stage = Join-Path $output 'source'
if (Test-Path $output) { throw "Build directory already exists: $output" }
New-Item -ItemType Directory -Path $stage -Force | Out-Null
Set-Content -LiteralPath (Join-Path $output '.gdignore') -Value ''

# Snapshot only runtime inputs. Never export private work, captures or editor tools.
foreach ($dir in @('Assets', 'Src', 'addons/phantom_camera', '.godot/imported')) {
    & robocopy (Join-Path $repo $dir) (Join-Path $stage $dir) /E /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "Snapshot failed: $dir" }
}
foreach ($file in @('project.godot', 'default_bus_layout.tres', 'icon.svg', 'icon.svg.import', 'threadbound_app_icon.ico')) {
    Copy-Item -LiteralPath (Join-Path $repo $file) -Destination $stage
}
foreach ($file in @('uid_cache.bin', 'global_script_class_cache.cfg')) {
    Copy-Item -LiteralPath (Join-Path $repo ".godot/$file") -Destination (Join-Path $stage '.godot')
}
git -C $repo rev-parse HEAD | Set-Content (Join-Path $output 'base-commit.txt')
git -C $repo status --porcelain | Set-Content (Join-Path $output 'source-status.txt')
$project = Get-Content -LiteralPath (Join-Path $stage 'project.godot') -Raw
$project = $project -replace '(?m)^_mcp_game_helper=.*\r?\n', ''
$project = $project -replace '(?m)^enabled=PackedStringArray\(.*\)', 'enabled=PackedStringArray()'
$project = $project.Replace('*uid://duq6jhf6unyis', '*res://addons/phantom_camera/scripts/managers/phantom_camera_manager.gd')
$presets = Get-Content -LiteralPath (Join-Path $repo 'export_presets.cfg') -Raw
$presets = $presets.Replace('shader_baker/enabled=true', 'shader_baker/enabled=false')
$presets = $presets.Replace('application/modify_resources=true', 'application/modify_resources=false')
Set-Content -LiteralPath (Join-Path $stage 'export_presets.cfg') -Value $presets -Encoding utf8NoBOM
$levels = [ordered]@{
    Demo = 'res://Src/Environment/World/Chamber Of The First Weave.tscn'
    Blue = 'res://Src/Environment/BlueBiome/blue_lakeside_test.tscn'
}
foreach ($level in $levels.Keys) {
    $name = "Threadbound_${level}_$BuildId"
    $folder = Join-Path $output $name
    New-Item -ItemType Directory -Path $folder | Out-Null
    $config = $project -replace '(?m)^run/main_scene=.*', ('run/main_scene="' + $levels[$level] + '"')
    $config = $config.Replace('config/name="Threadbound"', ('config/name="Threadbound ' + $level + ' Playtest"'))
    Set-Content -LiteralPath (Join-Path $stage 'project.godot') -Value $config -Encoding utf8NoBOM
    & (Join-Path $PSScriptRoot 'select_playtest_resources.ps1') -Project $stage
    & $Godot --headless --path $stage --export-release 'Windows Desktop' (Join-Path $folder "$name.exe") *> (Join-Path $output "export-$level.log")
    if ($LASTEXITCODE -ne 0) { throw "Export failed: $level. See export-$level.log" }
    $exportLog = Get-Content -LiteralPath (Join-Path $output "export-$level.log") -Raw
    if ($exportLog -match 'Could not create editor|tmpproject.binary|SCRIPT ERROR:') { throw "Invalid export: $level. Check Godot settings and temporary-directory access." }
    foreach ($extension in @('exe', 'pck')) {
        if (-not (Test-Path -LiteralPath (Join-Path $folder "$name.$extension"))) { throw "Missing exported $extension for $level" }
    }
    @"
Threadbound - $level playtest ($BuildId)
Windows x64. Extract the entire ZIP, then run $name.exe.
Keep the EXE and PCK together. No Godot installation is needed.
This build opens directly into the $level level. Each build has its own save folder.
Work in progress, exported from the current saved working tree.
"@ | Set-Content -LiteralPath (Join-Path $folder 'README.txt') -Encoding utf8NoBOM
    Write-Output "EXPORTED $folder"
}
Write-Output "BUILD_OUTPUT $output"
