param([string]$Kit = (Join-Path $PSScriptRoot '../../../ArtSource/Deliveries/WovenPaintingKit'))

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$references = @([Drawing.Bitmap].Assembly.Location, [Drawing.Rectangle].Assembly.Location)
$references += @(Get-ChildItem -LiteralPath $PSHOME -Filter 'System.Private.Windows.*.dll' | ForEach-Object FullName)
Add-Type -ReferencedAssemblies $references -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public static class WovenPaintingKit {
    public static Rectangle Bounds(Bitmap image, int alpha) {
        int left=image.Width, top=image.Height, right=-1, bottom=-1;
        for (int y=0; y<image.Height; y++) for (int x=0; x<image.Width; x++) {
            if (image.GetPixel(x,y).A <= alpha) continue;
            left=Math.Min(left,x); top=Math.Min(top,y); right=Math.Max(right,x); bottom=Math.Max(bottom,y);
        }
        if (right<left) throw new Exception("No visible art in stamp");
        return Rectangle.FromLTRB(left,top,right+1,bottom+1);
    }

    public static Bitmap Prepare(Bitmap source, int gameWidth, bool background) {
        Rectangle bounds = background ? new Rectangle(0,0,source.Width,source.Height) : Bounds(source,12);
        int gameHeight = Math.Max(1,(int)Math.Round(gameWidth * (double)bounds.Height / bounds.Width));
        int pad = background ? 0 : 8;
        var output = new Bitmap(gameWidth+pad*2,gameHeight+pad*2,PixelFormat.Format32bppArgb);
        using(var g=Graphics.FromImage(output))
        using(var attributes=new ImageAttributes()) {
            g.CompositingMode=CompositingMode.SourceCopy;
            g.InterpolationMode=InterpolationMode.HighQualityBicubic;
            attributes.SetWrapMode(WrapMode.TileFlipXY);
            g.DrawImage(source,new Rectangle(pad,pad,gameWidth,gameHeight),
                        bounds.X,bounds.Y,bounds.Width,bounds.Height,GraphicsUnit.Pixel,attributes);
        }
        return output;
    }
}
'@

$kitPath = (Resolve-Path -LiteralPath $Kit).Path
$spec = Get-Content -LiteralPath (Join-Path $kitPath 'stamp_spec.json') -Raw | ConvertFrom-Json
$pngFolder = Join-Path $kitPath 'stamps'
New-Item -ItemType Directory -Path $pngFolder -Force | Out-Null
$records = foreach ($record in $spec) {
    $raw = Join-Path $kitPath ('sources/' + $record.name + '.png')
    $inputImage = [Drawing.Bitmap]::FromFile($raw)
    try {
        $isBackground = $record.family -eq 'backdrop'
        if (-not $isBackground) {
            $bounds = [WovenPaintingKit]::Bounds($inputImage, 48)
            if ($bounds.Width -eq $inputImage.Width -and $bounds.Height -eq $inputImage.Height) {
                throw "Transparent stamp fills the entire source: $($record.name)"
            }
        }
        $stamp = [WovenPaintingKit]::Prepare($inputImage, $record.game_width, $isBackground)
        try {
            $name = "$($record.name).png"
            $output = Join-Path $pngFolder $name
            $stamp.Save($output,[Drawing.Imaging.ImageFormat]::Png)
            [ordered]@{
                name=$record.name; family=$record.family; file="stamps/$name"
                source_size=@($inputImage.Width,$inputImage.Height)
                size=@($stamp.Width,$stamp.Height); game_width=$record.game_width
                opaque_backdrop=$isBackground; sha256=(Get-FileHash -LiteralPath $output).Hash.ToLowerInvariant()
                style_reference=$record.reference; prompt=$record.prompt
            }
        } finally { $stamp.Dispose() }
    } finally { $inputImage.Dispose() }
}
$records | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $kitPath 'manifest.json') -Encoding utf8
