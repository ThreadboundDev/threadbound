"""Extract the approved Woven Shore layout into registered stamps and a Krita canvas."""

from io import BytesIO
import json
from pathlib import Path
from xml.etree import ElementTree as ET
from zipfile import ZIP_DEFLATED, ZipFile

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[3]
DELIVERY = ROOT / "ArtSource/Deliveries/WovenShoreConcept"
TEXTURES = ROOT / "Assets/BlueBiome/Art/WovenWorldChunks/ConceptLayout"
SCALE = 2.5
WATERLINE = 486

# Coordinates on the approved 2172 x 724 painting. The terrain is cut out from
# that painting so the silhouettes and distances survive the move to Godot.
STAMPS = {
    "chamber": [(0,0),(681,0),(679,24),(638,31),(615,23),(578,36),(541,23),(520,49),
        (472,43),(441,61),(412,40),(371,61),(350,70),(331,91),(299,84),(288,130),
        (281,174),(307,195),(302,223),(286,253),(267,270),(250,253),(249,323),
        (269,358),(279,404),(306,418),(338,429),(334,452),(316,482),(310,501),
        (244,559),(199,586),(158,638),(0,648)],
    "tree_island": [(377,406),(380,391),(414,386),(443,387),(461,381),(466,360),
        (446,354),(425,351),(402,347),(410,332),(420,323),(432,316),(426,306),
        (453,297),(469,285),(499,282),(522,291),(532,300),(561,316),(570,329),
        (553,339),(532,340),(517,352),(508,365),(516,382),(550,383),(578,390),
        (600,398),(598,430),(597,481),(585,507),(546,529),(485,539),(425,562),
        (408,540),(399,511),(375,485),(373,450)],
    "swim_up_island": [(730,476),(753,408),(751,390),(748,369),(772,355),(779,347),
        (777,332),(800,317),(817,313),(829,323),(854,336),(870,343),(881,338),
        (907,333),(920,346),(945,358),(1035,359),(1059,370),(1054,409),(1040,448),
        (1038,480),(1023,522),(997,566),(969,584),(947,589),(924,569),(884,571),
        (862,592),(821,589),(787,568),(751,535),(735,500)],
    "floating_west_step": [(546,278),(554,268),(573,265),(580,253),(598,251),(609,260),
        (628,268),(635,279),(630,292),(614,299),(605,310),(581,310),(561,302),(550,292)],
    "floating_west_shelf": [(644,218),(655,208),(677,204),(690,194),(709,194),
        (732,207),(810,207),(823,201),(839,217),(832,239),(802,248),(770,263),
        (750,266),(703,251),(677,250),(659,238)],
    "floating_high_west": [(858,172),(867,166),(886,159),(896,152),(916,152),
        (925,162),(939,171),(938,183),(921,194),(907,204),(890,203),(874,191)],
    "floating_center": [(893,255),(907,248),(924,246),(941,238),(956,241),(973,239),
        (986,234),(1003,240),(1018,252),(1018,264),(1002,276),(975,285),(950,290),
        (925,280),(904,275)],
    "floating_east_step": [(1016,211),(1025,202),(1041,194),(1053,195),(1063,202),
        (1079,208),(1076,224),(1063,234),(1049,239),(1032,234),(1019,224)],
    "floating_east_shelf": [(1078,170),(1085,162),(1110,157),(1130,156),(1143,148),
        (1164,148),(1172,155),(1191,162),(1195,172),(1192,181),(1164,197),
        (1140,207),(1113,198),(1096,188),(1083,181)],
    "floating_gate_step": [(1202,140),(1213,128),(1227,123),(1236,116),(1253,115),
        (1266,124),(1292,126),(1318,133),(1333,146),(1331,155),(1305,162),
        (1281,170),(1254,164),(1226,154),(1207,152)],
    "village_bank": [(1108,463),(1125,450),(1146,442),(1153,431),(1172,419),(1178,392),
        (1184,369),(1191,339),(1229,340),(1259,314),(1280,291),(1288,273),(1313,266),
        (1334,250),(1352,244),(1370,230),(1398,224),(1420,227),(1434,237),(1478,241),
        (1510,240),(1544,237),(1581,225),(1639,221),(1662,228),(1705,219),(1746,220),
        (1811,217),(1839,208),(1891,213),(1919,203),(1965,195),(2002,169),(2016,147),
        (2045,133),(2033,111),(2010,80),(2003,64),(2031,40),(2043,19),(2056,10),
        (2073,28),(2098,29),(2116,9),(2117,0),(2172,0),(2172,485),(1986,485),
        (1938,505),(1818,511),(1666,513),(1495,530),(1327,566),(1259,567),
        (1202,549),(1166,511),(1123,495)],
    "irrigation_walk": [(1315,144),(1350,139),(1399,132),(1407,112),(1431,113),
        (1445,123),(1480,122),(1503,113),(1513,126),(1541,127),(1574,111),(1587,123),
        (1640,124),(1663,108),(1672,123),(1721,124),(1741,113),(1751,123),(1810,119),
        (1837,108),(1849,118),(1897,114),(1924,105),(1939,113),(1958,106),(1994,106),
        (2005,117),(2005,159),(1979,168),(1934,195),(1882,220),(1808,241),(1642,249),
        (1529,251),(1394,257),(1364,230),(1335,267),(1329,181),(1311,175)],
    "irrigation_latch": [(1310,87),(1318,85),(1319,79),(1336,79),(1336,84),(1345,84),
        (1347,79),(1360,80),(1361,86),(1370,86),(1371,82),(1385,81),(1385,85),
        (1390,85),(1392,81),(1400,82),(1401,101),(1406,109),(1405,140),(1397,152),
        (1396,165),(1316,166),(1316,150),(1310,145)],
    "aqueduct": [(1235,641),(1251,609),(1277,610),(1300,573),(1324,542),(1346,518),
        (1372,506),(1400,505),(1437,506),(1459,516),(1641,516),(1805,515),(1967,514),
        (2037,515),(2041,544),(2016,547),(2002,575),(2004,611),(2031,634),(2172,636),
        (2172,724),(1206,724),(1229,691),(1242,665)],
    "dock": [(1974,351),(1983,345),(1996,345),(1997,359),(2013,357),(2028,344),(2042,348),
        (2043,359),(2058,356),(2077,343),(2091,342),(2091,357),(2114,353),(2122,345),
        (2138,343),(2140,351),(2172,350),(2172,641),(2149,641),(2147,455),(2137,453),
        (2129,628),(2117,628),(2119,450),(2104,450),(2102,631),(2088,628),(2087,447),
        (2073,447),(2071,501),(2059,503),(2059,455),(2033,449),(2009,500),(1995,502),
        (1994,465),(1986,487),(1977,484),(1983,433),(1974,403)],
}

# Apertures whose center really contains sky or lake from the separate backdrop.
OPENINGS = {
    "irrigation_walk": [
        [(1435,235),(1448,206),(1477,184),(1500,177),(1529,187),(1552,210),(1558,229),(1538,238),(1509,234),(1482,231)],
        [(1613,223),(1624,196),(1649,179),(1673,174),(1703,183),(1722,203),(1728,219),(1704,224),(1665,219)],
        [(1791,217),(1798,196),(1821,179),(1846,175),(1870,185),(1877,200),(1871,212),(1834,214)],
        [(1327,93),(1336,93),(1336,137),(1327,137)],
    ],
}


def png_bytes(image):
    output = BytesIO()
    image.save(output, format="PNG")
    return output.getvalue()


def stamp(source, outline, holes):
    mask = Image.new("L", source.size)
    draw = ImageDraw.Draw(mask)
    draw.polygon(outline, fill=255)
    for hole in holes:
        draw.polygon(hole, fill=0)
    mask = mask.filter(ImageFilter.GaussianBlur(0.8))
    bounds = mask.getbbox()
    result = source.crop(bounds).convert("RGBA")
    result.putalpha(mask.crop(bounds))
    return result, bounds[:2]


def make_passes(landscape, lakebed):
    width, height = landscape.size
    far = landscape.copy().convert("RGBA")
    near = lakebed.crop((0, 240, width, lakebed.height)).resize(
        (width, height - WATERLINE), Image.Resampling.LANCZOS).convert("RGBA")
    # Keep the lakebed visible while letting the generated far-lake color show
    # through at the shared surface, avoiding a hard horizontal join.
    alpha = Image.new("L", near.size, 255)
    draw = ImageDraw.Draw(alpha)
    for y in range(45):
        draw.line((0, y, width, y), fill=round(y * 255 / 45))
    near.putalpha(alpha)
    return [("far_lake", far, (0, 0)), ("lakebed", near, (0, WATERLINE))]


def fade_base(sprite, offset, start, end):
    fade = Image.new("L", sprite.size, 255)
    draw = ImageDraw.Draw(fade)
    for row in range(max(0, start - offset[1]), sprite.height):
        strength = max(0, round(255 * (end - offset[1] - row) / (end - start)))
        draw.line((0, row, sprite.width, row), fill=strength)
    sprite.putalpha(ImageChops.multiply(sprite.getchannel("A"), fade))


def save_openraster(layers, size):
    path = DELIVERY / "Woven_Shore_Layout.ora"
    canvas = Image.new("RGBA", size)
    image = ET.Element("image", {"w": str(size[0]), "h": str(size[1]), "name": "Woven Shore", "version": "0.0.3"})
    stack = ET.SubElement(image, "stack")
    with ZipFile(path, "w") as archive:
        archive.writestr("mimetype", "image/openraster")
        for index, (name, layer, offset) in enumerate(layers):
            size_at_scale = tuple(round(edge * SCALE) for edge in layer.size)
            scaled = layer.resize(size_at_scale, Image.Resampling.LANCZOS)
            xy = tuple(round(edge * SCALE) for edge in offset)
            canvas.alpha_composite(scaled, xy)
            src = f"data/layer{index:02d}.png"
            archive.writestr(src, png_bytes(scaled))
            stack.insert(0, ET.Element("layer", {"name": name.replace("_", " ").title(), "src": src,
                "x": str(xy[0]), "y": str(xy[1]), "opacity": "1.0", "visibility": "visible", "composite-op": "svg:src-over"}))
        archive.writestr("stack.xml", ET.tostring(image, encoding="utf-8"), compress_type=ZIP_DEFLATED)
        archive.writestr("mergedimage.png", png_bytes(canvas))
        canvas.thumbnail((1280, 720), Image.Resampling.LANCZOS)
        archive.writestr("Thumbnails/thumbnail.png", png_bytes(ImageOps.contain(canvas, (256, 256))))
    canvas.convert("RGB").save(DELIVERY / "layout_preview.jpg", quality=95)


def main():
    sources = DELIVERY / "sources"
    source = Image.open(sources / "approved_layout.png")
    landscape = Image.open(sources / "landscape_plate.png")
    lakebed = Image.open(sources / "lakebed_plate.png")
    layers = make_passes(landscape, lakebed)
    # Mask the gate separately to let the real gate open in Godot.
    clean = source.copy()
    latch, latch_offset = stamp(source, STAMPS["irrigation_latch"], [])
    clean.paste(landscape.crop((*latch_offset, latch_offset[0] + latch.width,
        latch_offset[1] + latch.height)), latch_offset, latch.getchannel("A"))
    deck = source.crop((1410, 139, 1490, 168)).resize((103, 29))
    clean.paste(deck, (1308, 139))
    barred_opening = [(1322,557),(1334,548),(1351,537),(1370,532),(1391,532),
        (1414,536),(1416,655),(1391,654),(1379,660),(1324,649)]
    grate, grate_offset = stamp(source, barred_opening, [])
    open_intake = source.copy()
    water = source.crop((1513, 546, 1592, 651)).resize(grate.size)
    open_intake.paste(water, grate_offset, grate.getchannel("A"))
    base_fades = {"chamber": (571, 646), "tree_island": (492, 556),
        "village_bank": (516, 566)}
    for name, outline in STAMPS.items():
        if name == "irrigation_latch":
            layers.append((name, latch, latch_offset))
        else:
            plate = {"irrigation_walk": clean, "aqueduct": open_intake}.get(name, source)
            sprite, offset = stamp(plate, outline, OPENINGS.get(name, []))
            if name in base_fades:
                fade_base(sprite, offset, *base_fades[name])
            layers.append((name, sprite, offset))
    layers.append(("aqueduct_grate", grate, grate_offset))
    TEXTURES.mkdir(parents=True, exist_ok=True)
    for name, image, _ in layers:
        image.save(TEXTURES / f"{name}.png")
    registration = {"scale": SCALE, "canvas": source.size, "waterline": WATERLINE,
        "layers": {name: {"origin": offset, "size": image.size} for name, image, offset in layers}}
    (DELIVERY / "registration.json").write_text(json.dumps(registration, indent=2) + "\n", encoding="utf-8")
    save_openraster(layers, (round(source.width * SCALE), round(source.height * SCALE)))


if __name__ == "__main__":
    main()
