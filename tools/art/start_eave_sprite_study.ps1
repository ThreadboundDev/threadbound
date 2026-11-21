param(
    [switch]$Verify,
    [switch]$Headless,
    [switch]$PrepareOnly,
    [string]$Engine
)
$ErrorActionPreference = 'Stop'
$taskRepository = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$taskProject = Join-Path $taskRepository 'LocalOnly/EaveRunnerSpriteStudy/preview_project'
$taskSceneDirectory = 'Src/Tests/Art/EaveRunnerSpriteStudy'
$taskAssetDirectory = 'Assets/BlueBiome/Enemies/EaveRunner/SpriteStudy'
$taskCaptureDirectory = Join-Path $taskRepository 'ArtSource/Deliveries/eave-runner-sprite-study-2026-11-21/preview/godot'
foreach ($taskRelative in @($taskSceneDirectory, $taskAssetDirectory)) {
    $taskDestination = Join-Path $taskProject $taskRelative
    New-Item -ItemType Directory -Path $taskDestination -Force | Out-Null
    Get-ChildItem -LiteralPath (Join-Path $taskRepository $taskRelative) -File |
        Where-Object Extension -In @('.gd', '.tscn', '.png', '.json') |
        Copy-Item -Destination $taskDestination -Force
}
@'
config_version=5

[application]
config/name="Eave Runner Sprite Study"
run/main_scene="res://Src/Tests/Art/EaveRunnerSpriteStudy/eave_runner_sprite_study.tscn"

[display]
window/size/viewport_width=1280
window/size/viewport_height=800
window/stretch/mode="canvas_items"

[rendering]
renderer/rendering_method="gl_compatibility"
environment/defaults/default_clear_color=Color(0.1, 0.15, 0.2, 1)
'@ | Set-Content -LiteralPath (Join-Path $taskProject 'project.godot') -Encoding utf8
if ($PrepareOnly) { Write-Output $taskProject; exit 0 }
if (-not $Engine) {
    $Engine = Get-ChildItem -LiteralPath "${env:ProgramFiles(x86)}/Godot" -Recurse -Filter '*4.7.2*console.exe' |
        Select-Object -First 1 -ExpandProperty FullName
}
if (-not $Engine -or -not (Test-Path -LiteralPath $Engine)) { throw 'Supply -Engine with a Godot 4 executable.' }
$taskUserData = Join-Path $taskProject 'user_data'
New-Item -ItemType Directory -Path $taskUserData -Force | Out-Null
$taskArguments = @('--path', $taskProject, '--rendering-method', 'gl_compatibility', '--log-file', (Join-Path $taskProject 'preview.log'))
if ($Headless) { $taskArguments += '--headless'; $Verify = $true }
if ($Verify) { $taskArguments += @('--', '--verify-eave-sprites', "--capture-dir=$taskCaptureDirectory") }
$taskOriginalAppData = $env:APPDATA
try {
    $env:APPDATA = $taskUserData
    & $Engine @taskArguments
    if ($LASTEXITCODE -ne 0) { throw "Sprite study exited with code $LASTEXITCODE." }
} finally {
    $env:APPDATA = $taskOriginalAppData
}
