param(
    [string]$Engine,
    [string]$Python,
    [switch]$BuildOnly
)
$ErrorActionPreference = 'Stop'
$studyRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$studyRaw = Join-Path $studyRoot 'tmp/scale-vfx-study'
New-Item -ItemType Directory -Force -Path $studyRaw | Out-Null
if (-not $Python) {
    $Python = Join-Path $env:USERPROFILE '.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
}
if (-not (Test-Path -LiteralPath $Python)) { throw 'Pass -Python with a Python 3 interpreter containing Pillow.' }
$studyPreviousAppData = $env:APPDATA
$studyPreviousOutput = $env:THREADBOUND_SCALE_OUT
Push-Location -LiteralPath $studyRoot
try {
    if (-not $BuildOnly) {
        if (-not $Engine) {
            $Engine = (Get-ChildItem -LiteralPath "${env:ProgramFiles(x86)}/Godot" -Recurse -Filter '*console.exe' |
                Sort-Object FullName -Descending | Select-Object -First 1).FullName
        }
        if (-not $Engine -or -not (Test-Path -LiteralPath $Engine)) { throw 'Pass -Engine with the Godot 4.7.2 console executable.' }
        # Isolate all progress/preferences/logs from Chase's normal user://.
        $env:APPDATA = Join-Path $studyRaw 'userdata'
        $env:THREADBOUND_SCALE_OUT = $studyRaw
        New-Item -ItemType Directory -Force -Path $env:APPDATA | Out-Null
        foreach ($studyMode in @('fixture','blue','demo')) {
            & $Engine --path $studyRoot --resolution 1920x1080 --fixed-fps 60 --disable-vsync --script res://work/scale-vfx-study-2026-10-30/capture_scale.gd -- $studyMode *> (Join-Path $studyRaw "$($studyMode)_capture.log")
            if ($LASTEXITCODE -ne 0) { throw "Scale capture failed: $studyMode" }
            Write-Output "Captured scale: $studyMode"
        }
        $studyTrial = Join-Path $studyRoot 'work/third-person-study-2026-10-28/project'
        & $Engine --path $studyTrial --resolution 1440x900 --fixed-fps 60 --disable-vsync --script (Join-Path $PSScriptRoot 'capture_trial_scale.gd') *> (Join-Path $studyRaw 'trial_capture.log')
        if ($LASTEXITCODE -ne 0) { throw 'Preserved 3D trial capture failed.' }
        $studyVariants = @(
            @{Name='baseline_right'; Args=@()},
            @{Name='candidate_right'; Args=@('--candidate')},
            @{Name='candidate_left'; Args=@('--candidate','--left')},
            @{Name='candidate_right_game_scale'; Args=@('--candidate','--game-scale')}
        )
        foreach ($studyVariant in $studyVariants) {
            $studyArguments = $studyVariant.Args
            & $Engine --path $studyRoot --resolution 1920x1080 --fixed-fps 60 --disable-vsync --script res://work/scale-vfx-study-2026-10-30/capture_vfx.gd -- @studyArguments *> (Join-Path $studyRaw "vfx_$($studyVariant.Name).log")
            if ($LASTEXITCODE -ne 0) { throw "VFX capture failed: $($studyVariant.Name)" }
            Write-Output "Captured VFX: $($studyVariant.Name)"
        }
    }
    & $Python (Join-Path $PSScriptRoot 'build_review.py')
    if ($LASTEXITCODE -ne 0) { throw 'Review packaging or matched-capture validation failed.' }
}
finally {
    $env:APPDATA = $studyPreviousAppData
    $env:THREADBOUND_SCALE_OUT = $studyPreviousOutput
    Pop-Location
}
