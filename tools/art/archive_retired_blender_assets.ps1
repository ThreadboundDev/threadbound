param([switch]$Execute)
$ErrorActionPreference='Stop'
$workspace=[IO.Path]::GetFullPath('C:/Users/chase/Documents/threadbound')
$archive=[IO.Path]::GetFullPath('C:/Users/chase/Documents/Threadborne_Art_Archive/2026-09-05-retired-blender')
$archiveParent=[IO.Path]::GetFullPath('C:/Users/chase/Documents/Threadborne_Art_Archive')
if (-not $archive.StartsWith($archiveParent+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {throw 'Archive outside approved target'}
$relativePaths=@(
'ArtSource/Player/Blender/threadborne_v3_style_proof.blend'
'ArtSource/Player/Blender/threadborne_v3_style_proof.blend1'
'ArtSource/Player/Blender/threadborne_v4_refined.blend'
'ArtSource/Player/Blender/threadborne_v4_refined.blend1'
'ArtSource/Player/Blender/threadborne_v5_worn.blend'
'ArtSource/Player/Blender/threadborne_v5_worn.blend1'
'ArtSource/Player/Blender/threadborne_v6_reference_materials.blend'
'ArtSource/Player/Blender/threadborne_v6_reference_materials.blend1'
'ArtSource/Player/Blender/threadborne_v7_proportion_straps.blend'
'ArtSource/Player/Blender/threadborne_v8_pelvis_study.blend'
'ArtSource/Player/Blender/threadborne_v8_pelvis_study.blend1'
'ArtSource/Player/Blender/Untitled.blend'
'ArtSource/Player/Blender/render_manifest.json'
'ArtSource/Player/Blender/renders'
'ArtSource/Player/Blender/imported_character/Threadborne_2D_Starter_Rig.blend'
'ArtSource/Player/Blender/imported_character/Threadborne_2D_Starter_Rig.blend1'
'ArtSource/Player/Blender/imported_character/Threadborne_2D_Shoulder_Refinement.blend1'
'ArtSource/Player/Blender/imported_character/shoulder_review_source.blend'
'ArtSource/Player/Blender/imported_character/shoulder_review_live_state.json'
'ArtSource/Player/Blender/imported_character/import_inspection.json'
'ArtSource/Player/Blender/imported_character/rig_setup_report.json'
'ArtSource/Player/Blender/imported_character/rig_validation.json'
'ArtSource/Player/Blender/imported_character/view_minus_x.png'
'ArtSource/Player/Blender/imported_character/view_plus_x.png'
'ArtSource/Player/Blender/imported_character/rig_preview'
'ArtSource/Player/Blender/imported_character/README.md'
'ArtSource/Player/Blender/imported_character/shoulder_preview/before_a60.png'
'ArtSource/Player/Blender/imported_character/shoulder_preview/after_a45.png'
'ArtSource/Player/Blender/imported_character/shoulder_preview/after_a60_three_quarter.png'
'ArtSource/Player/Blender/shield_revision/Threadborne_Sword_Shield_Rear_Fix.blend1'
'ArtSource/Player/Blender/shield_revision/minus_x.png'
'ArtSource/Player/Blender/shield_revision/minus_y.png'
'ArtSource/Player/Blender/shield_revision/plus_x.png'
'tools/art/build_threadborne_blender_proof.py'
'tools/art/build_threadborne_refined.py'
'tools/art/correct_threadborne_pelvis.py'
'tools/art/correct_threadborne_proportions.py'
'tools/art/texture_threadborne_study.py'
'tools/art/inspect_imported_character_offline.py'
'tools/art/render_threadborne_trouser_check.py'
'tools/art/snapshot_imported_character.py'
'tools/art/snapshot_shoulder_review.py'
'tools/art/prepare_imported_character_rig.py'
'tools/art/refine_threadborne_shoulders.py'
'tools/art/validate_imported_character_rig.py'
'tools/art/validate_threadborne_shoulders.py'
'tools/player_animation/blender_style_preview.gd'
'tools/player_animation/blender_style_preview.gd.uid'
'tools/player_animation/blender_style_preview.tscn'
'tools/player_animation/blender_refined_preview.tscn'
'tools/player_animation/blender_worn_preview.tscn'
'tools/player_animation/blender_reference_materials_preview.tscn'
'tools/player_animation/blender_proportion_straps_preview.tscn'
'docs/art/player_blender_pipeline.md'
)
$plan=@()
foreach ($relative in $relativePaths) {
 $source=[IO.Path]::GetFullPath((Join-Path $workspace $relative))
 $destination=[IO.Path]::GetFullPath((Join-Path $archive $relative))
 if (-not $source.StartsWith($workspace+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {throw 'Invalid source'}
 if (-not $destination.StartsWith($archive+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {throw 'Invalid destination'}
 if (-not (Test-Path -LiteralPath $source)) {throw "Missing expected source: $source"}
 if (Test-Path -LiteralPath $destination) {throw "Archive collision: $destination"}
 $item=Get-Item -LiteralPath $source
 if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {throw "Refusing reparse point: $source"}
 $files=if($item.PSIsContainer){@(Get-ChildItem -LiteralPath $source -Recurse -File)}else{@($item)}
 $links=@(Get-ChildItem -LiteralPath $source -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {$_.Attributes -band [IO.FileAttributes]::ReparsePoint})
 if($links.Count){throw 'Refusing nested reparse points'}
 $plan+= [pscustomobject]@{Source=$source;Destination=$destination;Files=$files.Count;Bytes=($files | Measure-Object Length -Sum).Sum}
}
$plan | Select-Object Source,Files,Bytes | Format-Table -AutoSize
"TOTAL FILES: $(($plan | Measure-Object Files -Sum).Sum)"
"TOTAL BYTES: $(($plan | Measure-Object Bytes -Sum).Sum)"
if ($Execute) {
 foreach ($entry in $plan) {
  $parent=Split-Path -Parent $entry.Destination
  New-Item -ItemType Directory -Path $parent -Force | Out-Null
  Move-Item -LiteralPath $entry.Source -Destination $entry.Destination
  if((Test-Path -LiteralPath $entry.Source) -or -not (Test-Path -LiteralPath $entry.Destination)){throw 'Move verification failed'}
 }
 "ARCHIVED SUCCESSFULLY: $archive"
}
