[CmdletBinding()]
param(
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

$textExtensions = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]@(
        ".cfg", ".csv", ".fnt", ".gd", ".gdshader", ".godot", ".json",
        ".md", ".ps1", ".py", ".shader", ".tres", ".tscn", ".txt"
    ),
    [System.StringComparer]::OrdinalIgnoreCase
)
$assetExtensions = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]@(
        ".bmp", ".fnt", ".gif", ".ico", ".jpeg", ".jpg", ".kra", ".mp3",
        ".ogg", ".otf", ".png", ".svg", ".tga", ".ttf", ".tres", ".wav",
        ".webp"
    ),
    [System.StringComparer]::OrdinalIgnoreCase
)

$protectedPrefixes = @(
    "Assets/chamber_of_first_weave/Blue Wing/blue_wing_decor_atlas.",
    "Assets/chamber_of_first_weave/Red Wing/red_wing_decor_atlas.",
    "Assets/chamber_of_first_weave/Yellow Wing/yellow_wing_decor_atlas.",
    "Assets/chamber_of_first_weave/Red Wing/red_brazier_sprite_sheet.",
    "Assets/chamber_of_first_weave/Red Wing/red_wing_brazier_source.",
    "docs/art/concept_art/Idle right first.png",
    "docs/art/concept_art/Weapon Model Bronze Long Handle.png",
    "Assets/UI/controller/Controller Glyphs and Images/Xelu_Free_Controller&Key_Prompts/Keyboard & Mouse/Dark/",
    "Assets/UI/controller/Controller Glyphs and Images/Xelu_Free_Controller&Key_Prompts/PS5/",
    "Assets/UI/controller/Controller Glyphs and Images/Xelu_Free_Controller&Key_Prompts/Xbox Series/",
    "Assets/UI/controller/Controller Glyphs and Images/Xelu_Free_Controller&Key_Prompts/Switch/",
    "Assets/UI/controller/Controller Glyphs and Images/Xelu_Free_Controller&Key_Prompts/Steam Deck/"
)

$explicitPrefixes = @(
    "addons/phantom_camera/examples/",
    "addons/soupik/",
    "Assets/UI/controller/Controller Glyphs and Images/Xelu_Free_Controller&Key_Prompts/Keyboard & Mouse/Light/",
    "Assets/UI/controller/Controller Glyphs and Images/Xelu_Free_Controller&Key_Prompts/Others/",
    "Assets/UI/controller/Controller Glyphs and Images/Xelu_Free_Controller&Key_Prompts/PS3/",
    "Assets/UI/controller/Controller Glyphs and Images/Xelu_Free_Controller&Key_Prompts/PS4/",
    "Assets/UI/controller/Controller Glyphs and Images/Xelu_Free_Controller&Key_Prompts/Xbox 360/",
    "Assets/UI/controller/Controller Glyphs and Images/Xelu_Free_Controller&Key_Prompts/Xbox One/",
    "cleanup_reports/delete_candidates_20260702/",
    "docs/archive/2026-06-06_obsolete_archetype_reference/",
    "docs/archive/2026-06-07_experimental_rigging_scene/",
    "docs/art/concept_art/"
)

$explicitFiles = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]@(
        "Src/Characters/Player/rig_editor_handle.gd",
        "Src/Characters/Player/rig_editor_handle.gd.uid",
        "Src/Characters/Player/threadborne_deform_rig.tscn",
        "Assets/Threadborne/Equipment/Weavers_Shuttle_Club_Smear.png",
        "Assets/UI/Momentum+Action Points.png"
    ),
    [System.StringComparer]::OrdinalIgnoreCase
)

function Test-Prefix {
    param(
        [string]$Path,
        [string[]]$Prefixes
    )
    foreach ($prefix in $Prefixes) {
        if ($Path.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

function Get-SourcePath {
    param([string]$Path)
    if ($Path.EndsWith(".import", [System.StringComparison]::OrdinalIgnoreCase)) {
        return $Path.Substring(0, $Path.Length - ".import".Length)
    }
    return $Path
}

function Get-Text {
    param([string]$RelativePath)
    return [System.IO.File]::ReadAllText(
        (Join-Path $script:projectRoot $RelativePath)
    )
}

function Get-References {
    param(
        [string]$Text,
        [hashtable]$UidMap
    )
    $results = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    foreach ($match in [regex]::Matches($Text, '["'']\*?(res://[^"''\r\n]+)["'']')) {
        [void]$results.Add(
            $match.Groups[1].Value.Substring("res://".Length).Replace("\", "/")
        )
    }
    foreach ($match in [regex]::Matches($Text, 'uid://[a-z0-9]+')) {
        $uid = $match.Value
        if ($UidMap.ContainsKey($uid)) {
            [void]$results.Add([string]$UidMap[$uid])
        }
    }
    return @($results)
}

$projectRoot = (Resolve-Path -LiteralPath ".").Path
$allTrackedFiles = @(
    git ls-files | ForEach-Object { $_.Replace("\", "/") }
)
$trackedFiles = @(
    $allTrackedFiles | Where-Object {
        Test-Path -LiteralPath (Join-Path $projectRoot $_) -PathType Leaf
    }
)
$fileSet = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]$trackedFiles,
    [System.StringComparer]::OrdinalIgnoreCase
)

$uidMap = @{}
foreach ($relativePath in $trackedFiles) {
    if ($relativePath.EndsWith(".uid", [System.StringComparison]::OrdinalIgnoreCase)) {
        $uid = (Get-Text $relativePath).Trim()
        if ($uid -match '^uid://[a-z0-9]+$') {
            $uidMap[$uid] = $relativePath.Substring(0, $relativePath.Length - 4)
        }
        continue
    }
    if ($relativePath.EndsWith(".import", [System.StringComparison]::OrdinalIgnoreCase)) {
        $match = [regex]::Match((Get-Text $relativePath), '\buid\s*=\s*"?((?:uid://)[a-z0-9]+)')
        if ($match.Success) {
            $uidMap[$match.Groups[1].Value] = Get-SourcePath $relativePath
        }
        continue
    }
    $extension = [System.IO.Path]::GetExtension($relativePath)
    if ($extension -in @(".tscn", ".tres")) {
        $text = Get-Text $relativePath
        $prefixLength = [Math]::Min(512, $text.Length)
        $match = [regex]::Match(
            $text.Substring(0, $prefixLength),
            '\buid\s*=\s*"?((?:uid://)[a-z0-9]+)'
        )
        if ($match.Success) {
            $uidMap[$match.Groups[1].Value] = $relativePath
        }
    }
}

$graph = @{}
$reverseReferences = @{}
$referenceText = [System.Text.StringBuilder]::new()
foreach ($relativePath in $trackedFiles) {
    if ($relativePath.EndsWith(".import", [System.StringComparison]::OrdinalIgnoreCase)) {
        continue
    }
    $extension = [System.IO.Path]::GetExtension($relativePath)
    if (-not $textExtensions.Contains($extension)) {
        continue
    }
    $text = Get-Text $relativePath
    $references = @(
        Get-References -Text $text -UidMap $uidMap |
            Where-Object {
                $fileSet.Contains($_) -or $fileSet.Contains("$_.import")
            }
    )
    $graph[$relativePath] = $references
    foreach ($reference in $references) {
        if (-not $reverseReferences.ContainsKey($reference)) {
            $reverseReferences[$reference] = [System.Collections.Generic.List[string]]::new()
        }
        $reverseReferences[$reference].Add($relativePath)
    }
    if (
        -not $relativePath.StartsWith("cleanup_reports/") -and
        -not $relativePath.StartsWith(".godot/")
    ) {
        [void]$referenceText.AppendLine($text.Replace("\", "/").ToLowerInvariant())
    }
}

$runtimeRoots = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase
)
[void]$runtimeRoots.Add("project.godot")
[void]$runtimeRoots.Add("default_bus_layout.tres")
[void]$runtimeRoots.Add("export_presets.cfg")
$section = ""
foreach ($rawLine in (Get-Text "project.godot").Split([Environment]::NewLine)) {
    $line = $rawLine.Trim()
    if ($line.StartsWith("[") -and $line.EndsWith("]")) {
        $section = $line
        continue
    }
    if ($section -eq "[editor_plugins]") {
        continue
    }
    foreach ($reference in (Get-References -Text $line -UidMap $uidMap)) {
        [void]$runtimeRoots.Add($reference)
    }
}

$reachable = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase
)
$queue = [System.Collections.Generic.Queue[string]]::new()
foreach ($rootPath in $runtimeRoots) {
    $queue.Enqueue($rootPath)
}
while ($queue.Count -gt 0) {
    $relativePath = $queue.Dequeue()
    if (-not $reachable.Add($relativePath)) {
        continue
    }
    if ($graph.ContainsKey($relativePath)) {
        foreach ($dependency in $graph[$relativePath]) {
            if (-not $reachable.Contains($dependency)) {
                $queue.Enqueue($dependency)
            }
        }
    }
}

$deadExternalResources = [System.Collections.Generic.List[object]]::new()
foreach ($relativePath in $trackedFiles) {
    $extension = [System.IO.Path]::GetExtension($relativePath)
    if ($extension -notin @(".tscn", ".tres")) {
        continue
    }
    $text = Get-Text $relativePath
    $lines = $text -split '\r?\n'
    for ($index = 0; $index -lt $lines.Count; $index++) {
        $match = [regex]::Match(
            $lines[$index],
            '^\[ext_resource\b.*?\bpath="(res://[^"]+)".*?\bid="([^"]+)"\]\s*$'
        )
        if (-not $match.Success) {
            continue
        }
        $resourceId = $match.Groups[2].Value
        if (-not $text.Contains("ExtResource(`"$resourceId`")")) {
            $deadExternalResources.Add([pscustomobject]@{
                file = $relativePath
                line = $index + 1
                id = $resourceId
                resource = $match.Groups[1].Value.Substring("res://".Length)
            })
        }
    }
}

$allReferenceText = $referenceText.ToString()
$assets = [System.Collections.Generic.List[string]]::new()
$runtimeUnreachableAssets = [System.Collections.Generic.List[string]]::new()
$staticUnreferencedAssets = [System.Collections.Generic.List[string]]::new()
$explicitCandidates = [System.Collections.Generic.List[string]]::new()

foreach ($relativePath in $trackedFiles) {
    if ($relativePath.EndsWith(".import", [System.StringComparison]::OrdinalIgnoreCase)) {
        continue
    }
    $sourcePath = Get-SourcePath $relativePath
    $extension = [System.IO.Path]::GetExtension($sourcePath)
    if (-not $assetExtensions.Contains($extension)) {
        continue
    }
    if (
        -not $sourcePath.StartsWith("Assets/") -and
        -not $sourcePath.StartsWith("docs/art/") -and
        $sourcePath -notin @("icon.svg", "threadbound_app_icon.ico")
    ) {
        continue
    }
    $assets.Add($sourcePath)
    if (-not $reachable.Contains($sourcePath)) {
        $runtimeUnreachableAssets.Add($sourcePath)
    }
    $normalized = $sourcePath.ToLowerInvariant()
    if (
        -not $allReferenceText.Contains($normalized) -and
        -not $allReferenceText.Contains("res://$normalized") -and
        -not (Test-Prefix -Path $sourcePath -Prefixes $protectedPrefixes)
    ) {
        $staticUnreferencedAssets.Add($sourcePath)
    }
    if (
        (Test-Prefix -Path $sourcePath -Prefixes $explicitPrefixes) -and
        -not (Test-Prefix -Path $sourcePath -Prefixes $protectedPrefixes)
    ) {
        $explicitCandidates.Add($sourcePath)
    }
}

$candidateSet = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase
)
foreach ($path in $staticUnreferencedAssets) {
    [void]$candidateSet.Add($path)
}
foreach ($path in $explicitCandidates) {
    [void]$candidateSet.Add($path)
}
foreach ($relativePath in $trackedFiles) {
    if (
        $explicitFiles.Contains($relativePath) -or
        (
            (Test-Prefix -Path $relativePath -Prefixes $explicitPrefixes) -and
            -not (Test-Prefix -Path $relativePath -Prefixes $protectedPrefixes)
        )
    ) {
        [void]$candidateSet.Add($relativePath)
    }
}
foreach ($sourcePath in @($candidateSet)) {
    $importPath = "$sourcePath.import"
    if ($fileSet.Contains($importPath)) {
        [void]$candidateSet.Add($importPath)
    }
}
$quarantineCandidates = @($candidateSet | Sort-Object)

$candidateBytes = 0L
foreach ($relativePath in $quarantineCandidates) {
    $fullPath = Join-Path $projectRoot $relativePath
    if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
        $candidateBytes += (Get-Item -LiteralPath $fullPath).Length
    }
}

$candidateReferences = [ordered]@{}
foreach ($candidate in $quarantineCandidates) {
    if ($reverseReferences.ContainsKey($candidate)) {
        $candidateReferences[$candidate] = @(
            $reverseReferences[$candidate] | Sort-Object -Unique
        )
    }
}

$report = [ordered]@{
    root = $projectRoot.Replace("\", "/")
    tracked_file_count = $allTrackedFiles.Count
    tracked_present_file_count = $trackedFiles.Count
    tracked_missing_file_count = $allTrackedFiles.Count - $trackedFiles.Count
    asset_count = $assets.Count
    runtime_reachable_count = $reachable.Count
    runtime_reachable_resources = @($reachable | Sort-Object)
    runtime_unreachable_assets = @($runtimeUnreachableAssets | Sort-Object -Unique)
    static_unreferenced_assets = @($staticUnreferencedAssets | Sort-Object -Unique)
    explicit_candidates = @($explicitCandidates | Sort-Object -Unique)
    dead_ext_resources = @($deadExternalResources)
    protected_prefixes = $protectedPrefixes
    quarantine_candidates = $quarantineCandidates
    quarantine_candidate_count = $quarantineCandidates.Count
    quarantine_candidate_bytes = $candidateBytes
    quarantine_candidate_mib = [Math]::Round($candidateBytes / 1MB, 2)
    references_to_candidates = $candidateReferences
}

if ($OutputPath) {
    $resolvedOutput = Join-Path $projectRoot $OutputPath
    $outputDirectory = Split-Path -Parent $resolvedOutput
    if (-not (Test-Path -LiteralPath $outputDirectory)) {
        New-Item -ItemType Directory -Path $outputDirectory | Out-Null
    }
    $report | ConvertTo-Json -Depth 8 |
        Set-Content -LiteralPath $resolvedOutput -Encoding utf8
}

[pscustomobject]@{
    tracked_file_count = $report.tracked_file_count
    tracked_present_file_count = $report.tracked_present_file_count
    tracked_missing_file_count = $report.tracked_missing_file_count
    asset_count = $report.asset_count
    runtime_reachable_count = $report.runtime_reachable_count
    runtime_unreachable_asset_count = $report.runtime_unreachable_assets.Count
    static_unreferenced_asset_count = $report.static_unreferenced_assets.Count
    dead_ext_resource_count = $report.dead_ext_resources.Count
    quarantine_candidate_count = $report.quarantine_candidate_count
    quarantine_candidate_mib = $report.quarantine_candidate_mib
} | Format-List
