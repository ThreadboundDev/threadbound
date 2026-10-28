param([switch]$Editor, [switch]$RepositoryCopy)
$ErrorActionPreference = 'Stop'
$studyProject = Join-Path $env:USERPROFILE 'Documents\Threadbound 3D Study'
if ($RepositoryCopy) {
    $studyProject = Join-Path $PSScriptRoot '..\..\work\third-person-study-2026-10-28\project'
}
if (-not (Test-Path -LiteralPath (Join-Path $studyProject 'project.godot'))) {
    throw "Study not installed at $studyProject. Run install_third_person_study.py first."
}
$studyEngine = Get-ChildItem -LiteralPath "${env:ProgramFiles(x86)}\Godot" -Recurse -Filter 'Godot*.exe' |
    Where-Object { $_.Name -notmatch 'console' } | Sort-Object FullName -Descending | Select-Object -First 1
if (-not $studyEngine) { throw 'Godot executable not found.' }
$studyArguments = @('--path', ('"' + (Resolve-Path -LiteralPath $studyProject).Path + '"'))
if ($Editor) { $studyArguments += '--editor' }
Start-Process -FilePath $studyEngine.FullName -ArgumentList $studyArguments -WindowStyle Normal
