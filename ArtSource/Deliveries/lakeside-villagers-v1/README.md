# Lakeside villagers — first model pass

The approved net mender and boatwright concepts now have rigged 3D models,
separate workstations and four-second WorkIdle / TalkIdle loops. The net mender
works a wooden shuttle at a net frame. The boatwright planes a timber blank at
a trestle bench. Both lower their hands, turn toward the player during a greeting,
and return to work. This is the first modeled interpretation of the concept art;
faces, garments and hair can still receive an art polish pass.

## Try them

Run `res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn`
with F6. Click **Net mender** or **Boatwright** in the bottom landmark controls.
Use the displayed interaction binding (E with the current keyboard defaults).
The worker faces the player's side for six seconds; interact again or walk away
to resume work sooner. Furniture stays in place while the character turns.
The existing player interaction callbacks and remappable prompts are reused.
Walls block prompts and interaction. The greeting emits an `interacted` signal
for later dialogue work; no new dialogue or lore has been written.

The net mender is inside the fisher house at (430, -128); the boatwright is in
the workshop at (2820, -1024). Coordinates anchor their feet to the house floor.

## Reuse

All prefabs are under `res://Src/Environment/BlueBiome/Villagers/`:

| Prefab | Use |
| --- | --- |
| `net_mender_2d.tscn` | Interactable net mender with station |
| `boatwright_2d.tscn` | Interactable boatwright with station |
| `net_mending_station_2d.tscn` | Furniture only |
| `boatwright_bench_2d.tscn` | Furniture only |
| `net_mender_3d.tscn` | Native 3D worker and separate station |
| `boatwright_3d.tscn` | Native 3D worker and separate station |

The 2D prefabs use the existing shared lakeside 3D art stage. Add
`lakeside_art_stage_2d.tscn` to a different room before using them there. Position
the marker at the desired floor. **Asset Scale** defaults to 0.78: approximately
165px / 174px body height, using the stage's 128px per meter, fitted to the player's
visible sprite size. **Show Workstation**
can be turned off to use a worker separately. Furniture is nonblocking interior
dressing, with no new movement collision or 3D physics. All scene instances
share imported meshes and textures; each instance gets its own animation clock.

## Editable art

`ArtSource/BlueBiome/Villagers/LakesideVillagers_v1.blend` contains
`NetMender_WorkshopReview` and `Boatwright_WorkshopReview`. Select a scene in
Blender's scene dropdown. The workstation and rigged actor are separate objects.
The actor's named material slots, vertex groups, 163-bone humanoid/finger skeleton
and animation actions remain editable. Actor parts are joined into one skinned
mesh for export. Review cameras/lights do not export. All file images are packed
inside the saved Blender file.

Each character has about 40k triangles (39,390 net mender; 40,146 boatwright).
Stations have 9,656 and 3,172 triangles. Runtime models are GLB with shared external
textures, mipmaps, high-quality VRAM compression and normal maps. Workwear and
apron color images are 1254px square; existing village walnut maps are 4096px,
and shared pavilion fabric detail maps are 1024px. No subdivision modifier is
required at runtime.

`tools/art/build_lakeside_villagers.py` reproduces the source from the saved
reference assets and fabric images. `tools/art/import_lakeside_villagers.py`
packages the GLBs and imports only these new assets in an isolated project.
It explicitly preserves material tints that Blender's glTF exporter omits from
the preview's multiply nodes. The worker prefab enables skin vertex color on
the first imported surface, which this engine import left disabled.

## Sources

Human topology, target shapes, eyes, skeleton and skin weights use the MakeHuman
CC0 asset base. See `CC0_Source/LICENSE.ASSETS.md`, original asset headers and
`CC0_Source/download_manifest.json` for source URLs and checksums. The official
[MakeHuman asset license](https://static.makehumancommunity.org/about/license.html)
documents the asset/program licensing distinction. No MakeHuman program code
was incorporated. Clothes, hair, tools, stations and animation were authored in
the Blender builder. Wood and fabric detail maps reuse the village materials.
The two workwear color maps were generated with the built-in image generation
tool using the approved villager image. Exact prompts and mode are saved in
`fabric_generation_prompts.json`; runtime hashes are in
`Assets/BlueBiome/Villagers/provenance.json`.

## Wall-hunter cloth direction — proposal

Keep one or two short scarf/waist tails, roughly forearm length, clear of the
hands and feet. Two or three bones per tail can trail during a leap, tuck close
on a wall brace and settle during recovery. Author the motion into the attack
and idle clips; cloth simulation is unnecessary for this first enemy. Short
tails retain the silhouette without hiding projectile or jump-attack tells.
Enemy models and combat changes are outside this villager pass.
