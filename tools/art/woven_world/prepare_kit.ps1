$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$sourceDirectory = Join-Path $repositoryRoot 'ArtSource/Deliveries/WovenWorldTestKit/sources'
$assetDirectory = Join-Path $repositoryRoot 'Assets/BlueBiome/Art/WovenWorldTestKit'
$deliveryDirectory = Join-Path $repositoryRoot 'ArtSource/Deliveries/WovenWorldTestKit'

# Asset preparation only: preserve generated artwork, trim alpha and slice terrain.
# The shared terrain borders are constructed and measured, rather than prompted.
$drawingReferences = @([System.Drawing.Bitmap].Assembly.Location, [System.Drawing.Rectangle].Assembly.Location)
$drawingReferences += @(Get-ChildItem -LiteralPath $PSHOME -Filter 'System.Private.Windows.*.dll' | ForEach-Object FullName)
Add-Type -ReferencedAssemblies $drawingReferences -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
public static class WovenKitImages {
 public static Rectangle Bounds(Bitmap image) {
  int x0=image.Width,y0=image.Height,x1=-1,y1=-1;
  for(int y=0;y<image.Height;y++) for(int x=0;x<image.Width;x++)
   if(image.GetPixel(x,y).A>8){x0=Math.Min(x0,x);y0=Math.Min(y0,y);x1=Math.Max(x1,x);y1=Math.Max(y1,y);}
  if(x1<0)throw new Exception("Empty alpha image");
  return Rectangle.FromLTRB(x0,y0,x1+1,y1+1);
 }
 public static Bitmap Resize(Bitmap image,Rectangle source,int width,int height) {
  var output=new Bitmap(width,height,PixelFormat.Format32bppArgb);
  using(var g=Graphics.FromImage(output)) {
   g.CompositingMode=CompositingMode.SourceCopy;
   g.InterpolationMode=InterpolationMode.HighQualityBicubic;
   using(var attributes=new ImageAttributes()) {
    attributes.SetWrapMode(WrapMode.TileFlipXY);
    g.DrawImage(image,new Rectangle(0,0,width,height),source.X,source.Y,source.Width,source.Height,GraphicsUnit.Pixel,attributes);
   }
  }
  return output;
 }
 public static Bitmap Crop(Bitmap image,Rectangle source) {
  return image.Clone(source,PixelFormat.Format32bppArgb);
 }
 static Color Blend(Color a,Color b,double weight) {
  return Color.FromArgb((int)Math.Round(a.A+(b.A-a.A)*weight),(int)Math.Round(a.R+(b.R-a.R)*weight),(int)Math.Round(a.G+(b.G-a.G)*weight),(int)Math.Round(a.B+(b.B-a.B)*weight));
 }
 public static void HorizontalBorder(Bitmap tile,Bitmap reference,int sourceX,int startY,int band) {
  for(int y=0;y<tile.Height;y++) {
   Color shared=reference.GetPixel(sourceX,startY+y);
   for(int distance=0;distance<band;distance++) {
    double w=Math.Pow(1.0-(double)distance/band,2);
    tile.SetPixel(distance,y,Blend(tile.GetPixel(distance,y),shared,w));
    int right=tile.Width-1-distance;
    tile.SetPixel(right,y,Blend(tile.GetPixel(right,y),shared,w));
   }
  }
 }
 public static void VerticalBorder(Bitmap tile,Bitmap reference,int sourceY,int band,bool top,bool bottom) {
  // Uniform common boundary color is sampled once. This also keeps the corner
  // pixels shared between horizontal and vertical neighbors.
  Color shared=reference.GetPixel(reference.Width/2,sourceY);
  for(int x=0;x<tile.Width;x++) for(int d=0;d<band;d++) {
   double w=Math.Pow(1.0-(double)d/band,2);
   if(top) tile.SetPixel(x,d,Blend(tile.GetPixel(x,d),shared,w));
   if(bottom) {int y=tile.Height-1-d;tile.SetPixel(x,y,Blend(tile.GetPixel(x,y),shared,w));}
  }
 }
 public static int HorizontalError(Bitmap a,Bitmap b) {
  int error=0;
  for(int y=0;y<a.Height;y++) {var l=a.GetPixel(a.Width-1,y);var r=b.GetPixel(0,y);error=Math.Max(error,Math.Abs(l.A-r.A));error=Math.Max(error,Math.Abs(l.R-r.R));error=Math.Max(error,Math.Abs(l.G-r.G));error=Math.Max(error,Math.Abs(l.B-r.B));}
  return error;
 }
 public static int VerticalError(Bitmap a,Bitmap b) {
  int error=0;
  for(int x=0;x<a.Width;x++) {var l=a.GetPixel(x,a.Height-1);var r=b.GetPixel(x,0);error=Math.Max(error,Math.Abs(l.A-r.A));error=Math.Max(error,Math.Abs(l.R-r.R));error=Math.Max(error,Math.Abs(l.G-r.G));error=Math.Max(error,Math.Abs(l.B-r.B));}
  return error;
 }
}
'@

$assets = @(
    @{id='tree'; height=1200},
    @{id='foliage_green'; height=280},
    @{id='foliage_blossom'; height=400},
    @{id='rock_low'; height=300},
    @{id='rock_wide'; height=240},
    @{id='rock_tall'; height=500}
)
$records = @()
foreach ($asset in $assets) {
    $inputImage = [System.Drawing.Bitmap]::FromFile((Join-Path $sourceDirectory ($asset.id + '.png')))
    $bounds = [WovenKitImages]::Bounds($inputImage)
    $targetWidth = [int]([double]$bounds.Width / $bounds.Height * $asset.height)
    $outputImage = [WovenKitImages]::Resize($inputImage,$bounds,$targetWidth,$asset.height)
    $outputImage.Save((Join-Path $assetDirectory ($asset.id + '.png')),[System.Drawing.Imaging.ImageFormat]::Png)
    $records += @{id=$asset.id; width=$outputImage.Width; height=$outputImage.Height; source_alpha_bounds=@($bounds.X,$bounds.Y,$bounds.Width,$bounds.Height); corner_alpha=$inputImage.GetPixel(0,0).A}
    $outputImage.Dispose()
    $inputImage.Dispose()
}

$terrainInput = [System.Drawing.Bitmap]::FromFile((Join-Path $sourceDirectory 'terrain_source.png'))
$terrainBounds = [WovenKitImages]::Bounds($terrainInput)
$master = [WovenKitImages]::Resize($terrainInput,$terrainBounds,1024,384)
$tileA = [WovenKitImages]::Crop($master,[System.Drawing.Rectangle]::new(128,0,256,256))
$tileB = [WovenKitImages]::Crop($master,[System.Drawing.Rectangle]::new(640,0,256,256))
$fill = [WovenKitImages]::Crop($master,[System.Drawing.Rectangle]::new(384,128,256,256))
foreach ($tile in @($tileA,$tileB)) {
    [WovenKitImages]::HorizontalBorder($tile,$master,512,0,24)
    [WovenKitImages]::VerticalBorder($tile,$master,256,20,$false,$true)
}
[WovenKitImages]::HorizontalBorder($fill,$master,512,128,24)
[WovenKitImages]::VerticalBorder($fill,$master,256,20,$true,$true)
$atlas = [System.Drawing.Bitmap]::new(768,256,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$atlasGraphics = [System.Drawing.Graphics]::FromImage($atlas)
$atlasGraphics.DrawImageUnscaled($tileA,0,0)
$atlasGraphics.DrawImageUnscaled($tileB,256,0)
$atlasGraphics.DrawImageUnscaled($fill,512,0)
$atlas.Save((Join-Path $assetDirectory 'terrain_atlas.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$seams = @{
    top_a_to_a=[WovenKitImages]::HorizontalError($tileA,$tileA)
    top_a_to_b=[WovenKitImages]::HorizontalError($tileA,$tileB)
    top_b_to_a=[WovenKitImages]::HorizontalError($tileB,$tileA)
    top_b_to_b=[WovenKitImages]::HorizontalError($tileB,$tileB)
    fill_to_fill=[WovenKitImages]::HorizontalError($fill,$fill)
    top_a_to_fill=[WovenKitImages]::VerticalError($tileA,$fill)
    top_b_to_fill=[WovenKitImages]::VerticalError($tileB,$fill)
    fill_below_fill=[WovenKitImages]::VerticalError($fill,$fill)
}
if (@($seams.Values | Where-Object { $_ -ne 0 }).Count -gt 0) { throw ('Terrain border mismatch: ' + ($seams | ConvertTo-Json -Compress)) }
@{assets=$records; terrain=@{cell=256; atlas=@(768,256); border_max_channel_difference=$seams; source_alpha_bounds=@($terrainBounds.X,$terrainBounds.Y,$terrainBounds.Width,$terrainBounds.Height)}} | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $deliveryDirectory 'asset_checks.json') -Encoding utf8

# Compact contact sheet for visual QA of silhouettes and style.
$sheet = [System.Drawing.Bitmap]::new(1600,1100)
$sheetGraphics = [System.Drawing.Graphics]::FromImage($sheet)
$sheetGraphics.Clear([System.Drawing.Color]::FromArgb(231,237,237))
$sheetGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$font = [System.Drawing.Font]::new('Segoe UI',18)
$brush = [System.Drawing.Brushes]::DarkSlateGray
$index = 0
foreach ($id in @('tree','foliage_green','foliage_blossom','rock_low','rock_wide','rock_tall','terrain_atlas')) {
    $image = [System.Drawing.Bitmap]::FromFile((Join-Path $assetDirectory ($id + '.png')))
    $column = $index % 4
    $row = [int][Math]::Floor($index / 4)
    $ratio = [Math]::Min(360.0/$image.Width,440.0/$image.Height)
    $width = [int]($image.Width*$ratio)
    $height = [int]($image.Height*$ratio)
    $x = $column*400 + (400-$width)/2
    $y = $row*550 + 30 + (440-$height)/2
    $sheetGraphics.DrawImage($image,[System.Drawing.Rectangle]::new($x,$y,$width,$height))
    $sheetGraphics.DrawString($id,$font,$brush,[single]($column*400+20),[single]($row*550+495))
    $image.Dispose()
    $index++
}
$sheet.Save((Join-Path $deliveryDirectory 'kit_contact_sheet.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$sheetGraphics.Dispose()
$font.Dispose()
$sheet.Dispose()
$atlasGraphics.Dispose()
foreach ($image in @($atlas,$tileA,$tileB,$fill,$master,$terrainInput)) { $image.Dispose() }
Write-Output ('Prepared six stamps and a three-cell terrain atlas. All eight measured border joins have zero RGBA difference.')
