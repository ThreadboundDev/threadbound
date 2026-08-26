param(
    [string]$SourcePath = "",
    [string]$OutputPath = ""
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
if (-not $SourcePath) {
    $SourcePath = Join-Path $projectRoot "Assets\Threadborne\Player\Normalized_V2\attacks\pogo_attack_v1_source.png"
}
if (-not $OutputPath) {
    $OutputPath = Join-Path $projectRoot "Assets\Threadborne\Player\Normalized_V2\attacks\pogo_attack_v1.png"
}

$columns = 6
$rows = 2
$frameCount = 11
$targetCell = 416
$contentScale = 0.83

$source = [System.Drawing.Bitmap]::FromFile((Resolve-Path $SourcePath).Path)
$output = New-Object System.Drawing.Bitmap ($columns * $targetCell), ($rows * $targetCell), ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($output)
try {
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    $sourceCellWidth = [Math]::Floor($source.Width / $columns)
    $sourceCellHeight = [Math]::Floor($source.Height / $rows)
    $uniformScale = [Math]::Min(
        $targetCell / $sourceCellWidth,
        $targetCell / $sourceCellHeight
    ) * $contentScale
    $drawWidth = [Math]::Round($sourceCellWidth * $uniformScale)
    $drawHeight = [Math]::Round($sourceCellHeight * $uniformScale)

    for ($index = 0; $index -lt $frameCount; $index++) {
        $column = $index % $columns
        $row = [Math]::Floor($index / $columns)
        $sourceRect = [System.Drawing.Rectangle]::new(
            $column * $sourceCellWidth,
            $row * $sourceCellHeight,
            $sourceCellWidth,
            $sourceCellHeight
        )
        $targetRect = [System.Drawing.Rectangle]::new(
            $column * $targetCell + [Math]::Floor(($targetCell - $drawWidth) / 2),
            $row * $targetCell + [Math]::Floor(($targetCell - $drawHeight) / 2),
            $drawWidth,
            $drawHeight
        )
        $graphics.DrawImage($source, $targetRect, $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
    }

    $output.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
}
finally {
    $graphics.Dispose()
    $output.Dispose()
    $source.Dispose()
}

Write-Output "Built 11-frame pogo sheet: $OutputPath"
