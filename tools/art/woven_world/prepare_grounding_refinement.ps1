$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$delivery = Join-Path $repositoryRoot 'ArtSource/Deliveries/WovenWorldChunks/grounding_refinement'
$runtime = Join-Path $repositoryRoot 'Assets/BlueBiome/Art/WovenWorldChunks/GroundingRefinement'
$manifest = Get-Content (Join-Path $delivery 'generation_manifest.json') -Raw | ConvertFrom-Json
$drawingReferences = @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Rectangle].Assembly.Location)
$drawingReferences += @(Get-ChildItem -LiteralPath $PSHOME -Filter 'System.Private.Windows.*.dll' | ForEach-Object FullName)
Add-Type -ReferencedAssemblies $drawingReferences -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
public static class GroundingStamp {
 public static Rectangle Bounds(Bitmap image) {
  int x0=image.Width,y0=image.Height,x1=-1,y1=-1;
  for(int y=0;y<image.Height;y++)for(int x=0;x<image.Width;x++)if(image.GetPixel(x,y).A>8){x0=Math.Min(x0,x);y0=Math.Min(y0,y);x1=Math.Max(x1,x);y1=Math.Max(y1,y);}
  if(x1<0)throw new Exception("Empty image");
  return Rectangle.FromLTRB(Math.Max(0,x0-3),Math.Max(0,y0-3),Math.Min(image.Width,x1+4),Math.Min(image.Height,y1+4));
 }
 public static Bitmap Resize(Bitmap image,Rectangle source,int width) {
  int height=(int)Math.Round((double)source.Height/source.Width*width);
  var result=new Bitmap(width,height,PixelFormat.Format32bppArgb);
  using(var g=Graphics.FromImage(result)){
   g.CompositingMode=CompositingMode.SourceCopy;g.InterpolationMode=InterpolationMode.HighQualityBicubic;
   using(var a=new ImageAttributes()){a.SetWrapMode(WrapMode.TileFlipXY);g.DrawImage(image,new Rectangle(0,0,width,height),source.X,source.Y,source.Width,source.Height,GraphicsUnit.Pixel,a);}
  }
  return result;
 }
}
'@
$records = [ordered]@{}
foreach ($asset in $manifest.assets) {
    $source = [System.Drawing.Bitmap]::FromFile((Join-Path $delivery ('sources/'+$asset.id+'.png')))
    $bounds = [GroundingStamp]::Bounds($source)
    $image = [GroundingStamp]::Resize($source,$bounds,$asset.width)
    $record = [ordered]@{width=$image.Width;height=$image.Height;source_alpha_bounds=@($bounds.X,$bounds.Y,$bounds.Width,$bounds.Height)}
    if ($asset.id -eq 'platform_integrated_top') {
        # Artist-annotated geometry after visual review, independent of material
        # hue. The collision datum lies inside the continuous rock top plane.
        $record['standing_back_y'] = $asset.standing_back_y
        $record['standing_front_y'] = $asset.standing_front_y
        $record['anchor_y'] = $asset.anchor_y
    } else { $record['anchor_y'] = [int]($image.Height*$asset.anchor) }
    $image.Save((Join-Path $runtime ($asset.id+'.png')),[System.Drawing.Imaging.ImageFormat]::Png)
    $records[$asset.id] = $record
    $source.Dispose()
    $image.Dispose()
}
$records | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $runtime 'asset_metadata.json') -Encoding utf8
$records | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $delivery 'asset_checks.json') -Encoding utf8
foreach ($id in @('foliage_soft_base','foliage_rim')) {
    $a = $records[$id]
    $scene = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Texture2D" path="res://Assets/BlueBiome/Art/WovenWorldChunks/GroundingRefinement/ID.png" id="1"]

[node name="Foliage" type="Node2D"]

[node name="Art" type="Sprite2D" parent="."]
centered = false
position = Vector2(X, Y)
texture = ExtResource("1")
'@
    $scene = $scene.Replace('ID',$id).Replace('X',(-$a.width/2.0).ToString([System.Globalization.CultureInfo]::InvariantCulture)).Replace('Y',(-$a.anchor_y).ToString([System.Globalization.CultureInfo]::InvariantCulture))
    [System.IO.File]::WriteAllText((Join-Path $runtime ($id+'.tscn')),$scene.Replace("`r`n","`n")+"`n",[System.Text.UTF8Encoding]::new($false))
}
$platformScene = @'
[gd_scene load_steps=3 format=3]

[ext_resource type="Texture2D" path="res://Assets/BlueBiome/Art/WovenWorldChunks/GroundingRefinement/platform_integrated_top.png" id="1"]

[sub_resource type="RectangleShape2D" id="Shape"]
size = Vector2(425, 14)

[node name="PlatformIntegratedTop" type="Node2D"]
metadata/asset_id = "platform_medium"
metadata/kind = "platform"

[node name="Art" type="Sprite2D" parent="."]
centered = false
position = Vector2(0, Y)
texture = ExtResource("1")

[node name="Body" type="StaticBody2D" parent="."]
position = Vector2(223.5, 7)
collision_layer = 1
collision_mask = 0

[node name="Shape" type="CollisionShape2D" parent="Body"]
shape = SubResource("Shape")
one_way_collision = true
one_way_collision_margin = 8.0
'@
$platformScene = $platformScene.Replace('Y',(-$records.platform_integrated_top.anchor_y).ToString([System.Globalization.CultureInfo]::InvariantCulture))
[System.IO.File]::WriteAllText((Join-Path $runtime 'platform_integrated_top.tscn'),$platformScene.Replace("`r`n","`n")+"`n",[System.Text.UTF8Encoding]::new($false))
Write-Output ($records | ConvertTo-Json -Depth 5)
