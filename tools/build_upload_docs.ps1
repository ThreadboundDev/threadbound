$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$docsRoot = Join-Path $repoRoot "docs"
$outputRoot = Join-Path $docsRoot "upload_versions"

$bundles = [ordered]@{
    "01_art_master.md" = @(
        "art/asset_standards.md"
        "art/environment_art_style.md"
        "art/visual_readability_art_pass.md"
    )
    "02_design_master.md" = @(
        "design/color_system.md"
        "design/enemy_design.md"
        "design/gameplay_philosophy.md"
        "design/identity_and_appearance.md"
        "design/level_design_guidelines.md"
        "design/progression_and_choices.md"
        "design/project_structure_and_naming.md"
    )
    "03_gameplay_master.md" = @(
        "gameplay/core_mechanics.md"
        "gameplay/combat_foundation.md"
        "gameplay/combat_system.md"
        "gameplay/equipment_slots.md"
        "gameplay/boss_mechanics.md"
    )
    "04_narrative_characters_master.md" = @(
        "narrative/CANON.md"
        "narrative/characters/Eryndor.md"
        "narrative/characters/mysterious_follower.md"
        "narrative/characters/reclaimers_revised_lore.md"
        "narrative/characters/thread_masters_revised_lore.md"
        "narrative/characters/threadborne_player.md"
        "narrative/characters/weaver_revised_lore.md"
    )
    "05_narrative_world_and_story_master.md" = @(
        "narrative/CANON.md"
        "narrative/cosmology/cosmology_and_origins_revised.md"
        "narrative/narrative_voice_and_lore_delivery.md"
        "narrative/story/threadbound_cosmology_timeline.md"
        "narrative/story/symbolism_and_motifs.md"
        "narrative/story/story_outline.md"
        "narrative/story/opening_cinematic_narration_revised.md"
        "narrative/story/five_answers_to_freedom.md"
        "narrative/story/endings.md"
    )
}

New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null

foreach ($bundle in $bundles.GetEnumerator()) {
    $title = [System.IO.Path]::GetFileNameWithoutExtension($bundle.Key) -replace '^\d+_', '' -replace '_', ' '
    $title = (Get-Culture).TextInfo.ToTitleCase($title)
    $sections = [System.Collections.Generic.List[string]]::new()
    $sections.Add("# Threadbound $title")
    $sections.Add("")
    $sections.Add("> Generated from the maintained source documents by ``tools/build_upload_docs.ps1``. Edit the source documents, then regenerate this file.")
    $sections.Add("")
    $sections.Add("## Included Sources")
    $sections.Add("")
    foreach ($relativePath in $bundle.Value) {
        $sections.Add("- ``docs/$relativePath``")
    }

    foreach ($relativePath in $bundle.Value) {
        $sourcePath = Join-Path $docsRoot $relativePath
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            throw "Missing source document: $sourcePath"
        }
        $content = Get-Content -LiteralPath $sourcePath -Raw -Encoding UTF8
        $sections.Add("")
        $sections.Add("---")
        $sections.Add("")
        $sections.Add("# Source: docs/$relativePath")
        $sections.Add("")
        $sections.Add($content.TrimEnd())
    }

    $destination = Join-Path $outputRoot $bundle.Key
    [System.IO.File]::WriteAllText($destination, (($sections -join "`n") + "`n"), [System.Text.UTF8Encoding]::new($false))
}

$readme = @"
# Threadbound Upload Versions

These generated master documents reduce the maintained documentation set to five uploadable files while preserving the full text of every active source document.

1. ``01_art_master.md`` - art direction, environment style, asset standards, and readability pass
2. ``02_design_master.md`` - design philosophy, identity, color, enemies, levels, progression, and project conventions
3. ``03_gameplay_master.md`` - mechanics, combat, equipment, and bosses
4. ``04_narrative_characters_master.md`` - narrative canon plus all character references
5. ``05_narrative_world_and_story_master.md`` - narrative canon, cosmology, voice, plot, symbolism, cinematic, and endings

``CANON.md`` intentionally appears in both narrative bundles so either upload has the project guardrails. Archived notes and image assets are intentionally excluded.

Do not edit generated master documents directly. Update the maintained source file and run:

``````powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\\tools\\build_upload_docs.ps1
``````
"@

[System.IO.File]::WriteAllText((Join-Path $outputRoot "README.md"), $readme, [System.Text.UTF8Encoding]::new($false))

Write-Output "Generated $($bundles.Count) upload master documents in $outputRoot"
