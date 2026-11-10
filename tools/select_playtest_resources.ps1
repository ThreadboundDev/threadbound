param([Parameter(Mandatory=$true)][string]$Project, [switch]$ListOnly)
$ErrorActionPreference = 'Stop'
$Project = (Resolve-Path -LiteralPath $Project).Path
$pending = [System.Collections.Generic.Queue[string]]::new()
$selected = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
$pending.Enqueue('res://project.godot')
$pending.Enqueue('res://default_bus_layout.tres')
foreach ($texture in Get-ChildItem (Join-Path $Project 'Assets/BlueBiome') -Recurse -File | Where-Object { $_.Extension -in @('.png', '.jpg', '.jpeg', '.webp') -and ($_.FullName -match 'Textures|SharedTextures') }) {
    $pending.Enqueue('res://' + [IO.Path]::GetRelativePath($Project, $texture.FullName).Replace('\', '/'))
}
# Global script classes can be referenced by type name rather than file path.
foreach ($file in Get-ChildItem (Join-Path $Project 'Src'), (Join-Path $Project 'addons/phantom_camera') -Recurse -File -Filter '*.gd') {
    if (Select-String -LiteralPath $file.FullName -Pattern '^class_name ' -Quiet) {
        $pending.Enqueue('res://' + [IO.Path]::GetRelativePath($Project, $file.FullName).Replace('\', '/'))
    }
}
# Include string-based loads as well as ordinary Godot resource dependencies.
# A directory or filename prefix is expanded to cover dynamically composed paths.
while ($pending.Count) {
    $resource = $pending.Dequeue()
    $disk = Join-Path $Project $resource.Substring(6)
    if (Test-Path -LiteralPath $disk -PathType Container) {
        foreach ($file in Get-ChildItem -LiteralPath $disk -File -Recurse) {
            if ($file.Extension -notin @('.import', '.uid')) {
                $pending.Enqueue('res://' + [IO.Path]::GetRelativePath($Project, $file.FullName).Replace('\', '/'))
            }
        }
        continue
    }
    if (-not (Test-Path -LiteralPath $disk -PathType Leaf)) {
        $parent = Split-Path $disk -Parent
        if (Test-Path -LiteralPath $parent -PathType Container) {
            $prefix = Split-Path $disk -Leaf
            foreach ($file in Get-ChildItem -LiteralPath $parent -File | Where-Object { $_.Name.StartsWith($prefix) -and $_.Extension -notin @('.import', '.uid') }) {
                $pending.Enqueue('res://' + [IO.Path]::GetRelativePath($Project, $file.FullName).Replace('\', '/'))
            }
        }
        continue
    }
    if (-not $selected.Add($resource)) { continue }
    if ([IO.Path]::GetExtension($disk) -eq '.glb') {
        foreach ($texture in Get-ChildItem -LiteralPath (Split-Path $disk -Parent) -File | Where-Object { $_.Extension -in @('.png', '.jpg', '.jpeg', '.webp') }) {
            $pending.Enqueue('res://' + [IO.Path]::GetRelativePath($Project, $texture.FullName).Replace('\', '/'))
        }
    }
    if ([IO.Path]::GetExtension($disk) -in @('.godot', '.gd', '.tscn', '.tres', '.gdshader', '.gdshaderinc')) {
        $content = Get-Content -LiteralPath $disk -Raw
        foreach ($match in [regex]::Matches($content, '["'']\*?(res://[^"''\r\n]+)["'']')) {
            $pending.Enqueue($match.Groups[1].Value)
        }
    }
}
$resources = @($selected | Where-Object { $_ -ne 'res://project.godot' } | Sort-Object)
$resources | Set-Content -LiteralPath (Join-Path $Project 'selected-resources.txt') -Encoding utf8NoBOM
if ($ListOnly) { Write-Output "Selected $($resources.Count) runtime resources"; return }
$presetPath = Join-Path $Project 'export_presets.cfg'
$preset = Get-Content -LiteralPath $presetPath -Raw
$preset = $preset -replace '(?m)^export_filter=.*', 'export_filter="resources"'
$preset = $preset -replace '(?m)^export_files=.*\r?\n', ''
$files = 'export_files=PackedStringArray(' + (($resources | ForEach-Object { '"' + $_ + '"' }) -join ', ') + ')'
$preset = $preset -replace '(?m)^include_filter=.*', ($files + "`n" + 'include_filter="*.json"')
Set-Content -LiteralPath $presetPath -Value $preset -Encoding utf8NoBOM
Write-Output "Selected $($resources.Count) runtime resources"
