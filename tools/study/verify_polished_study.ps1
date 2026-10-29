param([switch]$RepositoryCopy, [switch]$Capture)
$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$projectFolder = if ($RepositoryCopy) { Join-Path $repositoryRoot 'work/third-person-study-2026-10-28/project' } else { Join-Path $env:USERPROFILE 'Documents/Threadbound 3D Study' }
$logFolder = Join-Path $repositoryRoot 'work/third-person-study-2026-10-28/temp/polish'
$engineExe = 'C:\Program Files (x86)\Godot\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe'
$prefix = if ($RepositoryCopy) { 'final_source' } else { 'final_installed' }
foreach ($test in @('verify_polished_demo', 'verify_combat_playtest', 'verify_study', 'verify_demo_feel')) {
    $logPath = Join-Path $logFolder ($prefix+'_'+$test+'.log')
    & $engineExe --headless --path $projectFolder --fixed-fps 60 --script ('tests/'+$test+'.gd') *> $logPath
    if ($LASTEXITCODE -ne 0) { throw "Godot check failed: $test. See $logPath" }
    Get-Content -LiteralPath $logPath -Tail 1
}
if ($Capture) {
    foreach ($script in @('capture_chamber', 'capture_3d_feel')) {
        $logPath = Join-Path $logFolder ($prefix+'_'+$script+'.log')
        & $engineExe --path $projectFolder --script ('tests/'+$script+'.gd') *> $logPath
        if ($LASTEXITCODE -ne 0) { throw "Godot capture failed: $script. See $logPath" }
        Get-Content -LiteralPath $logPath -Tail 1
    }
}
