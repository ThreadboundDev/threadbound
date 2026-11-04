# Lay out actual Blender captures using Windows' built-in drawing library.
Add-Type -AssemblyName System.Drawing
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$outputFolder = Join-Path $repoRoot 'LocalOnly/Equipment/Masks'

function Write-ReviewSheet($filename, $views, $subtitle) {
    $canvas = [System.Drawing.Bitmap]::new(1460, 1110)
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#1f272e'))
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $heading = [System.Drawing.Font]::new('Segoe UI', 30, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $label = [System.Drawing.Font]::new('Segoe UI', 25, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $text = [System.Drawing.Font]::new('Segoe UI', 18, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $cream = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml('#eadfc9'))
    $muted = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml('#b8c2ca'))
    try {
        $graphics.DrawString('THREADBOUND  /  SHARED PORCELAIN SHELL', $heading, $cream, 40, 22)
        $graphics.DrawString($subtitle, $text, $muted, 40, 67)
        for ($i = 0; $i -lt $views.Count; $i++) {
            $view = $views[$i]
            $x = 40 + $i * 720
            $graphics.DrawString($view[0].ToUpper(), $label, $cream, $x, 112)
            $graphics.DrawString($view[2], $text, $muted, $x, 153)
            $portrait = [System.Drawing.Image]::FromFile((Join-Path $outputFolder ($view[1] + '.png')))
            $strip = [System.Drawing.Image]::FromFile((Join-Path $outputFolder ($view[0].ToLower() + '_embroidery_repeat.png')))
            try {
                $graphics.DrawImage($portrait, $x, 187, 680, 779)
                $graphics.DrawImage($strip, $x, 979, 680, 113)
            } finally {
                $portrait.Dispose()
                $strip.Dispose()
            }
        }
        $canvas.Save((Join-Path $outputFolder $filename), [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $heading.Dispose(); $label.Dispose(); $text.Dispose()
        $cream.Dispose(); $muted.Dispose(); $graphics.Dispose(); $canvas.Dispose()
    }
}

Write-ReviewSheet 'fitted_review.png' @(
    @('Loomed', 'loomed_base_fit', 'Base cowl / knotwork / long diagonal gold repair'),
    @('Hermit', 'hermit_blue_fit', 'Hermit brim / waves / lower-cheek gold repair')
) 'One linked Blender mesh fitted around the actual doll and both outfit heads. Art review, November 4, 2026.'
Write-ReviewSheet 'finish_review.png' @(
    @('Loomed', 'loomed_front', 'Black wing-and-tear paint / interlocking brow knot'),
    @('Hermit', 'hermit_front', 'Black swept eye paint / slate-indigo wave')
) 'Two painted finishes on one 2.4 mm shell. Gold repairs and eye lips remain separate editable meshes.'
