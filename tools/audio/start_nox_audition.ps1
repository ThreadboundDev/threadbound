param([int]$Port = 8876, [switch]$NoBrowser)
$ErrorActionPreference = 'Stop'
$taskRepo = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$taskPython = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
if (-not (Test-Path -LiteralPath $taskPython)) { throw 'Bundled Python runtime not found. Run serve_nox_audition.py with Python and NumPy installed.' }
$taskWork = Join-Path $taskRepo 'work\nox-sound-audition-2026-10-28'
if (-not (Test-Path -LiteralPath (Join-Path $taskWork 'catalog.json'))) {
    & $taskPython (Join-Path $PSScriptRoot 'build_nox_audition_catalog.py')
    if ($LASTEXITCODE -ne 0) { throw 'Catalog preparation failed.' }
}
$taskUrl = "http://127.0.0.1:$Port/"
$taskHealth = $null
try { $taskHealth = Invoke-RestMethod -Uri ($taskUrl + 'health') -TimeoutSec 2 } catch {}
if ($taskHealth -and $taskHealth.service -ne 'threadbound-nox-audition-v1') { throw "Port $Port is used by a different service." }
if (-not $taskHealth) {
    $taskProcess = Start-Process -FilePath $taskPython -ArgumentList @('tools/audio/serve_nox_audition.py','--port',"$Port") -WorkingDirectory $taskRepo -WindowStyle Hidden -RedirectStandardOutput (Join-Path $taskWork 'server.log') -RedirectStandardError (Join-Path $taskWork 'server_error.log') -PassThru
    for ($taskAttempt=0; $taskAttempt -lt 20; $taskAttempt++) {
        Start-Sleep -Milliseconds 250
        try { $taskHealth = Invoke-RestMethod -Uri ($taskUrl + 'health') -TimeoutSec 1; break } catch {}
        if ($taskProcess.HasExited) { throw "Audition server exited. See $taskWork\server_error.log" }
    }
    if (-not $taskHealth) { throw 'Server did not become ready; see the task logs.' }
    Write-Output "Audition server PID: $($taskProcess.Id)"
}
Write-Output $taskUrl
if (-not $NoBrowser) { Start-Process $taskUrl }
