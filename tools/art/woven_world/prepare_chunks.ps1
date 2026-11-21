$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$sourceDirectory = Join-Path $repositoryRoot 'ArtSource/Deliveries/WovenWorldChunks/sources'
$assetDirectory = Join-Path $repositoryRoot 'Assets/BlueBiome/Art/WovenWorldChunks'
$deliveryDirectory = Join-Path $repositoryRoot 'ArtSource/Deliveries/WovenWorldChunks'
$manifest = Get-Content (Join-Path $deliveryDirectory 'generation_manifest.json') -Raw | ConvertFrom-Json
$drawingReferences = @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Rectangle].Assembly.Location)
$drawingReferences += @(Get-ChildItem -LiteralPath $PSHOME -Filter 'System.Private.Windows.*.dll' | ForEach-Object FullName)
Add-Type -ReferencedAssemblies $drawingReferences -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
public static class WovenChunkImages {
 public static Rectangle Bounds(Bitmap image) {
  int x0=image.Width,y0=image.Height,x1=-1,y1=-1;
  for(int y=0;y<image.Height;y++) for(int x=0;x<image.Width;x++)
   if(image.GetPixel(x,y).A>8){x0=Math.Min(x0,x);y0=Math.Min(y0,y);x1=Math.Max(x1,x);y1=Math.Max(y1,y);}
  if(x1<0)throw new Exception("Empty image");
  return Rectangle.FromLTRB(Math.Max(0,x0-3),Math.Max(0,y0-3),Math.Min(image.Width,x1+4),Math.Min(image.Height,y1+4));
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
 public static int[] Surface(Bitmap image) {
  // Find a substantially opaque horizontal cap. Use multiple adjacent rows
  // so isolated tufts do not become the collision plane.
  int surface=-1;
  int maxY=Math.Min(image.Height-5,image.Height/3);
  for(int y=0;y<maxY;y++) {
   bool solid=true;
   for(int row=0;row<4;row++) {
    int count=0;
    for(int x=0;x<image.Width;x++) if(image.GetPixel(x,y+row).A>=224)count++;
    if((double)count/image.Width<0.90){solid=false;break;}
   }
   if(solid){surface=y+2;break;}
  }
  if(surface<0)throw new Exception("No level walkable cap with 90% coverage");
  int bestStart=0,bestLength=0,start=0,length=0;
  for(int x=0;x<image.Width;x++) {
   if(image.GetPixel(x,surface).A>=224){if(length==0)start=x;length++;}
   else length=0;
   if(length>bestLength){bestLength=length;bestStart=start;}
  }
  return new int[]{surface,bestStart+2,bestStart+bestLength-2};
 }
 public static double OpaqueBodyFraction(Bitmap image,int surface) {
  int count=0,total=0;
  for(int y=surface+20;y<image.Height-8;y+=4)for(int x=image.Width/10;x<image.Width*9/10;x+=4){total++;if(image.GetPixel(x,y).A>224)count++;}
  return total>0?(double)count/total:0;
 }
}
'@

$records = [ordered]@{}
foreach ($asset in $manifest.assets) {
    $inputImage = [System.Drawing.Bitmap]::FromFile((Join-Path $sourceDirectory ($asset.id + '.png')))
    $bounds = [WovenChunkImages]::Bounds($inputImage)
    $targetHeight = [int]([double]$bounds.Height / $bounds.Width * $asset.width)
    $outputImage = [WovenChunkImages]::Resize($inputImage,$bounds,$asset.width,$targetHeight)
    $record = [ordered]@{kind=$asset.kind;width=$outputImage.Width;height=$outputImage.Height;source_alpha_bounds=@($bounds.X,$bounds.Y,$bounds.Width,$bounds.Height);source_corner_alpha=$inputImage.GetPixel(0,0).A}
    if ($asset.kind -ne 'decoration') {
        $surface = [WovenChunkImages]::Surface($outputImage)
        $record['surface_y'] = $surface[0]
        $record['surface_left'] = $surface[1]
        $record['surface_right'] = $surface[2]
        if ($asset.kind -eq 'ground') {
            $record['depth_below_surface'] = $outputImage.Height - $surface[0]
            $record['opaque_body_fraction'] = [WovenChunkImages]::OpaqueBodyFraction($outputImage,$surface[0])
            if ($record.depth_below_surface -lt 800 -or $record.opaque_body_fraction -lt 0.95) { throw ('Ground piece is too shallow or has holes: ' + $asset.id) }
        }
    }
    $outputImage.Save((Join-Path $assetDirectory ($asset.id + '.png')),[System.Drawing.Imaging.ImageFormat]::Png)
    $records[$asset.id] = $record
    $inputImage.Dispose()
    $outputImage.Dispose()
}
$metadata = @{assets=$records;preparation='Whole-source alpha trim and proportional resize only; no tiles, repeated fill, seam blending or image redrawing.'}
$metadata | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $assetDirectory 'asset_metadata.json') -Encoding utf8
$metadata | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $deliveryDirectory 'asset_checks.json') -Encoding utf8

# Native placeables keep the whole texture and its measured cap together.
# Their roots anchor to the walkable surface (or planting base for decoration).
$placeableDirectory = Join-Path $assetDirectory 'placeables'
New-Item -ItemType Directory -Path $placeableDirectory -Force | Out-Null
foreach ($asset in $manifest.assets) {
    $record = $records[$asset.id]
    $texturePath = 'res://Assets/BlueBiome/Art/WovenWorldChunks/' + $asset.id + '.png'
    $lines = [System.Collections.Generic.List[string]]::new()
    if ($asset.kind -eq 'decoration') {
        $lines.Add('[gd_scene load_steps=2 format=3]')
    } else { $lines.Add('[gd_scene load_steps=3 format=3]') }
    $lines.Add('')
    $lines.Add('[ext_resource type="Texture2D" path="' + $texturePath + '" id="1"]')
    $lines.Add('')
    if ($asset.kind -ne 'decoration') {
        $depth = if ($asset.kind -eq 'ground') { $record.depth_below_surface } else { 14 }
        $bodyWidth = $record.surface_right - $record.surface_left
        $bodyX = ($record.surface_left + $record.surface_right) / 2.0
        $lines.Add('[sub_resource type="RectangleShape2D" id="Shape"]')
        $lines.Add(('size = Vector2({0}, {1})' -f $bodyWidth,$depth))
        $lines.Add('')
    }
    $lines.Add('[node name="' + $asset.id + '" type="Node2D"]')
    $lines.Add('metadata/asset_id = "' + $asset.id + '"')
    $lines.Add('metadata/kind = "' + $asset.kind + '"')
    $lines.Add('')
    $lines.Add('[node name="Art" type="Sprite2D" parent="."]')
    $lines.Add('centered = false')
    if ($asset.kind -eq 'decoration') {
        $lines.Add(('position = Vector2({0}, {1})' -f (-$record.width/2.0),(-$record.height)))
    } else { $lines.Add(('position = Vector2(0, {0})' -f (-$record.surface_y))) }
    $lines.Add('texture = ExtResource("1")')
    if ($asset.kind -ne 'decoration') {
        $lines.Add('')
        $lines.Add('[node name="Body" type="StaticBody2D" parent="."]')
        $lines.Add(('position = Vector2({0}, {1})' -f $bodyX,($depth/2.0)))
        $lines.Add('collision_layer = 1')
        $lines.Add('collision_mask = 0')
        $lines.Add('')
        $lines.Add('[node name="Shape" type="CollisionShape2D" parent="Body"]')
        $lines.Add('shape = SubResource("Shape")')
        if ($asset.kind -eq 'platform') {
            $lines.Add('one_way_collision = true')
            $lines.Add('one_way_collision_margin = 8.0')
        }
    }
    [System.IO.File]::WriteAllText((Join-Path $placeableDirectory ($asset.id+'.tscn')),($lines -join "`n")+"`n",[System.Text.UTF8Encoding]::new($false))
}

$sheet = [System.Drawing.Bitmap]::new(1600,1500)
$graphics = [System.Drawing.Graphics]::FromImage($sheet)
$graphics.Clear([System.Drawing.Color]::FromArgb(225,235,236))
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$font = [System.Drawing.Font]::new('Segoe UI',17)
$index=0
foreach ($asset in $manifest.assets) {
    $image=[System.Drawing.Bitmap]::FromFile((Join-Path $assetDirectory ($asset.id+'.png')))
    $column=$index%4
    $row=[int][Math]::Floor($index/4)
    $ratio=[Math]::Min(360.0/$image.Width,400.0/$image.Height)
    $width=[int]($image.Width*$ratio)
    $height=[int]($image.Height*$ratio)
    $graphics.DrawImage($image,[System.Drawing.Rectangle]::new(($column*400+(400-$width)/2),($row*500+20+(400-$height)/2),$width,$height))
    $graphics.DrawString(($asset.id+'  '+$image.Width+'px'),$font,[System.Drawing.Brushes]::DarkSlateGray,[single]($column*400+15),[single]($row*500+450))
    $image.Dispose()
    $index++
}
$sheet.Save((Join-Path $deliveryDirectory 'chunk_kit_contact_sheet.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$font.Dispose()
$graphics.Dispose()
$sheet.Dispose()
Write-Output ('Prepared '+$records.Count+' whole-image stamps with measured walkable cap positions.')
