[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AuditPath,

    [Parameter(Mandatory = $true)]
    [string]$DestinationRoot,

    [string]$RepositoryManifestPath = "docs/archive/project_cleanup/quarantine_manifest_20260725.json",

    [switch]$Append
)

$ErrorActionPreference = "Stop"

function Get-Reason {
    param([string]$RelativePath)

    if (
        $RelativePath.StartsWith("addons/soupik/") -or
        $RelativePath.StartsWith("docs/archive/2026-06-07_experimental_rigging_scene/") -or
        $RelativePath.StartsWith("Src/Characters/Player/rig_") -or
        $RelativePath -eq "Src/Characters/Player/threadborne_deform_rig.tscn"
    ) {
        return "obsolete rigging system"
    }
    if ($RelativePath.StartsWith("docs/archive/2026-06-06_obsolete_archetype_reference/")) {
        return "obsolete archetype archive"
    }
    if ($RelativePath.StartsWith("addons/phantom_camera/examples/")) {
        return "third-party addon example content"
    }
    if ($RelativePath.StartsWith("Assets/UI/controller/Controller Glyphs and Images/")) {
        return "unsupported or unused controller glyph family"
    }
    if ($RelativePath.StartsWith("docs/art/concept_art/")) {
        return "non-runtime concept art"
    }
    if ($RelativePath.StartsWith("docs/archive/project_cleanup/delete_candidates_20260702/")) {
        return "previous delete-candidate staging folder"
    }
    return "no static project reference"
}

$projectRoot = (Resolve-Path -LiteralPath ".").Path
$gitRoot = (git rev-parse --show-toplevel).Trim().Replace("/", "\")
if (-not $projectRoot.Equals($gitRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Run this script from the cleanup worktree root."
}

$resolvedAudit = (Resolve-Path -LiteralPath $AuditPath).Path
$audit = Get-Content -LiteralPath $resolvedAudit -Raw | ConvertFrom-Json
$candidates = @($audit.quarantine_candidates | Sort-Object -Unique)
if ($candidates.Count -eq 0) {
    throw "The audit contains no quarantine candidates."
}
if ((Test-Path -LiteralPath $DestinationRoot) -and -not $Append) {
    throw "Destination already exists: $DestinationRoot"
}
if ($Append -and -not (Test-Path -LiteralPath $DestinationRoot -PathType Container)) {
    throw "Append destination does not exist: $DestinationRoot"
}

$tracked = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]@(git ls-files | ForEach-Object { $_.Replace("\", "/") }),
    [System.StringComparer]::OrdinalIgnoreCase
)
$projectPrefix = $projectRoot.TrimEnd("\") + "\"
$entries = [System.Collections.Generic.List[object]]::new()

foreach ($relativePath in $candidates) {
    if (-not $tracked.Contains($relativePath)) {
        throw "Candidate is not tracked by Git: $relativePath"
    }
    $sourcePath = [System.IO.Path]::GetFullPath(
        (Join-Path $projectRoot $relativePath)
    )
    if (-not $sourcePath.StartsWith(
        $projectPrefix,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Refusing path outside the worktree: $sourcePath"
    }
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Candidate does not exist as a file: $relativePath"
    }
    $item = Get-Item -LiteralPath $sourcePath
    $entries.Add([pscustomobject]@{
        original_relative_path = $relativePath
        staged_relative_path = "project_relative_paths/$relativePath"
        bytes = $item.Length
        sha256 = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
        reason = Get-Reason $relativePath
    })
}

$desktopManifestPath = Join-Path $DestinationRoot "MANIFEST.json"
if ($Append) {
    $manifest = Get-Content -LiteralPath $desktopManifestPath -Raw | ConvertFrom-Json
    if ($manifest.status -ne "staged") {
        throw "Existing manifest is not in staged state."
    }
    $existingPaths = [System.Collections.Generic.HashSet[string]]::new(
        [string[]]@($manifest.files.original_relative_path),
        [System.StringComparer]::OrdinalIgnoreCase
    )
    foreach ($entry in $entries) {
        if ($existingPaths.Contains($entry.original_relative_path)) {
            throw "Candidate is already present in the quarantine: $($entry.original_relative_path)"
        }
    }
    $manifest.files = @($manifest.files) + @($entries)
    $manifest.file_count = $manifest.files.Count
    $manifest.total_bytes = ($manifest.files | Measure-Object -Property bytes -Sum).Sum
    $manifest.total_mib = [Math]::Round($manifest.total_bytes / 1MB, 2)
    $manifest.status = "planned"
} else {
    $manifest = [ordered]@{
        project = "Threadbound"
        branch = (git branch --show-current).Trim()
        base_commit = (git rev-parse HEAD).Trim()
        created_at = (Get-Date).ToString("o")
        status = "planned"
        source_worktree = $projectRoot
        destination = $DestinationRoot
        file_count = $entries.Count
        total_bytes = ($entries | Measure-Object -Property bytes -Sum).Sum
        total_mib = [Math]::Round(
            (($entries | Measure-Object -Property bytes -Sum).Sum / 1MB),
            2
        )
        protected_prefixes = @($audit.protected_prefixes)
        files = @($entries)
    }
    New-Item -ItemType Directory -Path $DestinationRoot | Out-Null
}

$manifest | ConvertTo-Json -Depth 8 |
    Set-Content -LiteralPath $desktopManifestPath -Encoding utf8

foreach ($entry in $entries) {
    $sourcePath = Join-Path $projectRoot $entry.original_relative_path
    $destinationPath = Join-Path $DestinationRoot $entry.staged_relative_path
    $destinationDirectory = Split-Path -Parent $destinationPath
    if (-not (Test-Path -LiteralPath $destinationDirectory)) {
        New-Item -ItemType Directory -Path $destinationDirectory | Out-Null
    }
    Move-Item -LiteralPath $sourcePath -Destination $destinationPath
}

$manifest.status = "staged"
$manifest.completed_at = (Get-Date).ToString("o")
$manifest | ConvertTo-Json -Depth 8 |
    Set-Content -LiteralPath $desktopManifestPath -Encoding utf8

$repositoryManifest = Join-Path $projectRoot $RepositoryManifestPath
$repositoryManifestDirectory = Split-Path -Parent $repositoryManifest
if (-not (Test-Path -LiteralPath $repositoryManifestDirectory)) {
    New-Item -ItemType Directory -Path $repositoryManifestDirectory | Out-Null
}
$manifest | ConvertTo-Json -Depth 8 |
    Set-Content -LiteralPath $repositoryManifest -Encoding utf8

[pscustomobject]@{
    destination = $DestinationRoot
    file_count = $manifest.file_count
    total_mib = $manifest.total_mib
    manifest = $desktopManifestPath
    repository_manifest = $repositoryManifest
} | Format-List
