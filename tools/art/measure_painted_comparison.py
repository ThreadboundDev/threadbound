"""Read generated alpha bounds and record AtlasTexture regions; never alter pixels."""
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "Assets/BlueBiome/Art/PaintedComparison"
LAYOUTS = {
    "fisher_house": (2, 1), "workshop": (2, 1), "tower": (2, 1),
    "boat_slip": (1, 1), "lantern": (1, 1),
    "net_mender": (3, 1), "boatwright": (3, 1),
    "tide_duelist": (3, 2), "reedhook": (3, 2), "bellstriker": (3, 2),
    "eave_runner": (3, 2), "loom_heron": (3, 2), "water_bulb": (3, 2),
}

# Atlas-only regions preserve outstretched wings/weapons from generated layouts
# that do not follow equal cells. Original PNG pixels remain untouched.
REGIONS = {
    "water_bulb": [[0,0,512,560],[512,0,512,560],[1024,0,512,560],[0,560,512,464],[512,560,512,464],[1024,560,512,464]],
    "bellstriker": [[0,0,512,512],[512,0,512,512],[1024,0,512,512],[0,512,550,512],[560,512,464,512],[1024,512,512,512]],
    "eave_runner": [[0,0,418,627],[418,0,418,627],[836,0,418,627],[0,627,550,627],[550,627,320,627],[875,627,379,627]],
    "loom_heron": [[0,0,548,560],[548,0,522,560],[1070,0,466,560],[0,560,640,464],[640,560,440,464],[1080,560,456,464]],
    "tide_duelist": [[0,0,525,512],[525,0,530,512],[1055,0,481,512],[0,512,600,512],[600,512,500,512],[1100,512,436,512]],
    "reedhook": [[0,0,512,512],[512,0,512,512],[1024,0,512,512],[0,512,620,512],[620,512,440,512],[1060,512,476,512]],
}
ANCHORS = {
    "loom_heron": [[337,300],[290,298],[215,303],[336,243],[200,243],[200,240]],
    "tide_duelist": [[242,260],[247,266],[218,260],[245,249],[228,250],[205,250]],
}

def measure():
    manifest = {}
    for key, (columns, rows) in LAYOUTS.items():
        path = ASSETS / f"{key}.png"
        if not path.exists():
            continue
        with Image.open(path) as image:
            assert image.mode == "RGBA", f"{key}: actual alpha required"
            alpha = image.getchannel("A")
            minimum, maximum = alpha.getextrema()
            assert minimum == 0 and maximum >= 240, f"{key}: empty or opaque asset"
            width, height = image.size
            cell = (width / columns, height / rows)
            regions = REGIONS.get(key, [[round(i%columns*cell[0]),round(i//columns*cell[1]),round(cell[0]),round(cell[1])] for i in range(columns*rows)])
            bounds = []
            for index in range(columns * rows):
                x,y,w,h = regions[index]
                box = (x,y,x+w,y+h)
                # Ignore very faint antialias debris for registration; retain all
                # actual pixels in the untouched original image / atlas resource.
                used = alpha.crop(box).point(lambda value: 255 if value >= 16 else 0).getbbox()
                assert used, f"{key}: missing frame {index}"
                bounds.append(used)
            # All poses use ONE registration taken from the initial complete
            # silhouette. Missing roof / spent state must not enlarge remaining art.
            left, top, right, bottom = bounds[0]
            if key in ("net_mender", "boatwright", "tide_duelist", "reedhook", "bellstriker", "eave_runner", "loom_heron", "water_bulb"):
                # Preserve the full pose cell so extended weapons/wings fit.
                frames = regions
            else:
                # Cutaways can shift horizontally within their generated cell.
                # Measure each actual silhouette instead of reusing the exterior
                # crop (the tower's old crop displaced its cutaway by ~97px).
                # Retain exterior Y/height: a missing roof must remain empty.
                frames = [[round(i*cell[0])+used[0],top,used[2]-used[0],bottom-top]
                          for i,used in enumerate(bounds)]
            offsets = [[0,0] for _ in bounds]
            if key == "water_bulb":
                offsets = [[0,0],[0,0],[0,0],[0,12],[0,12],[0,12]]
            if key in ANCHORS:
                anchor = ANCHORS[key][0]
                offsets = [[anchor[0]-p[0],anchor[1]-p[1]] for p in ANCHORS[key]]
            elif key == "bellstriker":
                centers = []
                for x,y,w,h in regions:
                    pose = alpha.crop((x,y,x+w,y+h))
                    weights = [sum(pose.getpixel((xx,yy)) for yy in range(pose.height)) for xx in range(pose.width)]
                    centers.append(sum(xx*weight for xx,weight in enumerate(weights))/max(sum(weights),1))
                offsets = [[centers[0]-center,bottom-used[3]] for center,used in zip(centers,bounds)]
            elif key in ("eave_runner","reedhook","net_mender","boatwright"):
                # Keep the foot registration fixed while poses crouch/recoil.
                centers = []
                for region, used in zip(regions,bounds):
                    x,y,w,h = region
                    a,b,c,d = used
                    band = alpha.crop((x,y+d-8,x+w,y+d))
                    weights = [sum(band.getpixel((xx,yy)) for yy in range(band.height)) for xx in range(band.width)]
                    centers.append(sum(xx*weight for xx,weight in enumerate(weights))/max(sum(weights),1))
                offsets = [[centers[0]-center,bottom-used[3]] for center,used in zip(centers,bounds)]
            manifest[key] = {"pixels":[width,height],"grid":[columns,rows],"frames":frames,"initial_alpha_bounds":[left,top,right-left,bottom-top],"pose_alpha_bounds":[[a,b,c-a,d-b] for a,b,c,d in bounds],"pose_offsets":offsets,"source":"built-in imagegen; original pixels retained"}
    (ASSETS/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8",newline="\n")
    print("Measured", len(manifest), "painted sheets:", ", ".join(manifest))

if __name__ == "__main__":
    measure()
