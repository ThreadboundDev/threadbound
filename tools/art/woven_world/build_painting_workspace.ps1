param([string]$Kit = (Join-Path $PSScriptRoot '../../../ArtSource/Deliveries/WovenPaintingKit'))

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression
$kitPath = (Resolve-Path -LiteralPath $Kit).Path
$catalog = Get-Content -LiteralPath (Join-Path $kitPath 'manifest.json') -Raw | ConvertFrom-Json
$utf8 = [Text.UTF8Encoding]::new($false)

function New-Bitmap([int]$width, [int]$height) {
    [Drawing.Bitmap]::new($width, $height, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
}

function Add-Png($archive, [string]$name, [Drawing.Bitmap]$bitmap) {
    $entry = $archive.CreateEntry($name, [IO.Compression.CompressionLevel]::NoCompression)
    $stream = $entry.Open()
    $buffer = [IO.MemoryStream]::new()
    try {
        $bitmap.Save($buffer, [Drawing.Imaging.ImageFormat]::Png)
        $buffer.Position = 0
        $buffer.CopyTo($stream)
    } finally { $buffer.Dispose(); $stream.Dispose() }
}

function Add-Text($archive, [string]$name, [string]$content) {
    $entry = $archive.CreateEntry($name, [IO.Compression.CompressionLevel]::NoCompression)
    $stream = $entry.Open()
    try {
        $bytes = $utf8.GetBytes($content)
        $stream.Write($bytes,0,$bytes.Length)
    } finally { $stream.Dispose() }
}

function New-Layer($name, $bitmap, [int]$x = 0, [int]$y = 0, [bool]$visible = $true) {
    @{ name=$name; bitmap=$bitmap; x=$x; y=$y; visible=$visible }
}

function Write-OpenRaster([string]$filename, [string]$title, [int]$width, [int]$height, $layers) {
    $merged = New-Bitmap $width $height
    $graph = [Drawing.Graphics]::FromImage($merged)
    $file = [IO.File]::Create((Join-Path $kitPath $filename))
    $zip = [IO.Compression.ZipArchive]::new($file, [IO.Compression.ZipArchiveMode]::Create)
    try {
        Add-Text $zip 'mimetype' 'image/openraster'
        $escapedTitle = [Security.SecurityElement]::Escape($title)
        $xml = [Text.StringBuilder]::new()
        [void]$xml.AppendLine("<image w='$width' h='$height' name='$escapedTitle' xres='72' yres='72' version='0.0.3'><stack>")
        for ($index = $layers.Count-1; $index -ge 0; $index--) {
            $layer = $layers[$index]
            $name = [Security.SecurityElement]::Escape($layer.name)
            $source = "data/layer$index.png"
            $show = if ($layer.visible) { 'visible' } else { 'hidden' }
            [void]$xml.AppendLine("<layer name='$name' src='$source' x='$($layer.x)' y='$($layer.y)' opacity='1.0' visibility='$show' composite-op='svg:src-over'/>")
            Add-Png $zip $source $layer.bitmap
        }
        [void]$xml.AppendLine('</stack></image>')
        Add-Text $zip 'stack.xml' $xml.ToString()
        foreach ($layer in $layers) {
            if ($layer.visible) { $graph.DrawImageUnscaled($layer.bitmap,$layer.x,$layer.y) }
        }
        $graph.Flush()
        Add-Png $zip 'mergedimage.png' $merged
        $thumb = [Drawing.Bitmap]::new($merged,256,[math]::Max(1,[int](256.0*$height/$width)))
        try { Add-Png $zip 'Thumbnails/thumbnail.png' $thumb } finally { $thumb.Dispose() }
        if ($filename -like '*Atlas*') {
            $preview = [Drawing.Bitmap]::new($merged,1500,[int](1500.0*$height/$width))
            try { $preview.Save((Join-Path $kitPath 'Atlas_preview.jpg'),[Drawing.Imaging.ImageFormat]::Jpeg) }
            finally { $preview.Dispose() }
        }
    } finally {
        $zip.Dispose()
        $file.Dispose()
        $graph.Dispose()
        $merged.Dispose()
    }
}

$ink = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(230,235,243,245))
$muted = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(205,174,216,224))
$dark = [Drawing.Color]::FromArgb(255,36,49,55)
$font = [Drawing.Font]::new('Segoe UI',24,[Drawing.FontStyle]::Regular,[Drawing.GraphicsUnit]::Pixel)
$header = [Drawing.Font]::new('Segoe UI',54,[Drawing.FontStyle]::Bold,[Drawing.GraphicsUnit]::Pixel)
$scalePen = [Drawing.Pen]::new([Drawing.Color]::FromArgb(180,113,189,204),3)
$gridPen = [Drawing.Pen]::new([Drawing.Color]::FromArgb(55,141,209,224),2)

# The painting canvas starts blank. Guides supply scale while keeping the
# composition in the artist's hands. Each empty layer is independently editable.
$width = 12800
$height = 4608
$guides = New-Bitmap $width $height
$g = [Drawing.Graphics]::FromImage($guides)
$g.TextRenderingHint = [Drawing.Text.TextRenderingHint]::AntiAliasGridFit
for ($x = 0; $x -lt $width; $x += 1024) {
    $g.DrawLine($gridPen,$x,0,$x,$height)
    $g.DrawString("$x px",$font,$muted,$x+14,12)
}
for ($y = 0; $y -lt $height; $y += 512) { $g.DrawLine($gridPen,0,$y,$width,$y) }
$g.DrawString('WOVEN SHORE  /  GAME SCALE 1:1', $header, $ink, 180, 100)
$g.DrawString('Example camera frame at 1x zoom', $font, $muted, 180, 245)
$g.DrawRectangle($scalePen,180,290,1920,1080)
$g.DrawLine($scalePen,320,1150,320,1342)
$g.DrawLine($scalePen,307,1150,333,1150)
$g.DrawLine($scalePen,307,1342,333,1342)
$g.DrawString('192 px actor scale reference', $font, $ink, 350, 1232)
$g.DrawString('Hide the Scale guides layer before exporting your backgrounds.', $font, $muted, 180, 1410)
$g.Dispose()
$previewBase = New-Bitmap $width $height
$g = [Drawing.Graphics]::FromImage($previewBase)
$g.Clear($dark)
$g.Dispose()
$paint = [Collections.Generic.List[object]]::new()
$paint.Add((New-Layer 'Preview matte (hide before export)' $previewBase))
foreach ($name in @('01 Far backdrop','02 Rear cave and cliffs','03 Land and platform paint','04 Underwater backdrop','05 Near accents')) {
    $paint.Add((New-Layer $name (New-Bitmap 1 1)))
}
$paint.Add((New-Layer 'Scale guides (hide before export)' $guides))
Write-OpenRaster 'Woven_Shore_Painting.ora' 'Woven Shore Painting' $width $height $paint
foreach ($layer in $paint) { $layer.bitmap.Dispose() }

# Lay each stamp out at its delivered scale so copy/paste stays 1:1.
$atlasWidth = 6400
$cellWidth = 2090
$margin = 65
$top = 166
$rows = @()
foreach ($family in @('ground','floating','pieces','openings','backdrop')) {
    $items = @($catalog | Where-Object family -eq $family)
    if ($items.Count -eq 0) { continue }
    $rowHeight = [int](($items | ForEach-Object { $_.size[1] } | Measure-Object -Maximum).Maximum + 124)
    $rows += @{ family=$family; items=$items; y=$top; height=$rowHeight }
    $top += $rowHeight
}
$atlasHeight = $top + 30
$base = New-Bitmap $atlasWidth $atlasHeight
$g = [Drawing.Graphics]::FromImage($base)
$g.Clear($dark)
$g.Dispose()
$labels = New-Bitmap $atlasWidth $atlasHeight
$g = [Drawing.Graphics]::FromImage($labels)
$g.TextRenderingHint = [Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$g.DrawString('WOVEN SHORE  /  STAMP ATLAS', $header, $ink, $margin, 28)
$g.DrawString('Separate layers at game scale. Copy a stamp layer into Woven Shore Painting.', $font, $muted, $margin, 105)
$atlas = [Collections.Generic.List[object]]::new()
$atlas.Add((New-Layer 'Preview matte (hide for transparency)' $base))
foreach ($row in $rows) {
    $g.DrawString($row.family.ToUpperInvariant(), $font, $muted, $margin, $row.y)
    for ($i=0; $i -lt $row.items.Count; $i++) {
        $entry=$row.items[$i]
        $x = $margin+$i*$cellWidth
        $y = $row.y+45
        $bitmap = [Drawing.Bitmap]::FromFile((Join-Path $kitPath $entry.file))
        $atlas.Add((New-Layer ($entry.name.Replace('_',' ')) $bitmap $x $y))
        $g.DrawString("$($entry.name.Replace('_',' '))   |   $($entry.size[0]) x $($entry.size[1])", $font, $ink, $x, ($row.y+$row.height-63))
        $g.DrawLine($gridPen,$x,($row.y+$row.height-20),($x+$cellWidth-36),($row.y+$row.height-20))
    }
}
$g.Dispose()
$atlas.Add((New-Layer 'Labels (hide for clean exports)' $labels))
Write-OpenRaster 'Woven_Shore_Atlas.ora' 'Woven Shore Stamp Atlas' $atlasWidth $atlasHeight $atlas
foreach ($layer in $atlas) { $layer.bitmap.Dispose() }
$header.Dispose()
$font.Dispose()
$scalePen.Dispose()
$gridPen.Dispose()
$ink.Dispose()
$muted.Dispose()
