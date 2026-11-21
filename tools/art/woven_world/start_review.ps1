param(
    [switch]$Verify,
    [switch]$Headless,
    [string]$Engine
)
$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
if (-not $Engine) {
    $Engine = Get-ChildItem -LiteralPath "${env:ProgramFiles(x86)}\Godot" -Recurse -Filter '*4.7.2*console.exe' |
        Select-Object -First 1 -ExpandProperty FullName
}
if (-not $Engine -or -not (Test-Path -LiteralPath $Engine)) { throw 'Supply -Engine with the path to Godot 4.7.2.' }
$engineArguments = @('--path',$repositoryRoot,'--log-file',(Join-Path $repositoryRoot 'ArtSource/Deliveries/WovenWorldTestKit/review_engine.log'))
if ($Headless) { $engineArguments += '--headless'; $Verify = $true }
$engineArguments += 'res://Src/Tests/Art/WovenWorld/woven_world_review.tscn'
if ($Verify) { $engineArguments += @('--','--verify-woven-kit') }
& $Engine @engineArguments
if ($LASTEXITCODE -ne 0) { throw "Godot exited with code $LASTEXITCODE. See the review log." }
