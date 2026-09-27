"""Generate the human-facing animation usage inventory from the canonical CSV."""

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "ArtSource/Player/Blender/imported_character/mixamo_library/animation_inventory.csv"
OUTPUT = ROOT / "docs/art/player_animation_inventory.md"

ACTIVE = {
    "idle_1": "Timed idle variation: look around.",
    "idle_2": "Timed idle variation: sword flourish.",
    "idle_3": "Timed idle variation: flourish/battle cry.",
    "idle_4": "Primary idle loop.",
    "run_1": "Normal ground locomotion.",
    "run_2": "Shielded backpedal.",
    "jump_1": "Running jump and ordinary airborne pose.",
    "jump_2": "Double jump.",
    "crouch_1": "Standing-to-crouch transition.",
    "crouch_idle_1": "Crouch idle.",
    "crouching_1": "Crouch-to-standing transition.",
    "crouching_2": "Crouched-block exit.",
    "crouching_3": "Crouched hurt reaction.",
    "block_1": "Standing block entry.",
    "block_idle_1": "Standing block hold.",
    "crouch_block_1": "Crouched block entry.",
    "crouch_block_2": "Crouched blocked-hit reaction.",
    "crouch_block_idle_1": "Crouched block hold.",
    "impact_1": "Standing blocked-hit reaction.",
    "impact_2": "Light standing hurt.",
    "impact_3": "Heavy standing hurt.",
    "death_1": "Backward death.",
    "death_2": "Forward death.",
    "slash_2": "Three input-driven light-combo segments.",
    "slash_5": "Crouch attack.",
    "casting_2": "Directional base-grapple throw.",
    "power_up_1": "Neutral sword-and-shield special with chest-centered burst.",
    "roll_1": "Dash/roll.",
    "grapple_swinging_1": "Airborne attached-grapple swing.",
    "water_idle_1": "Stationary water idle.",
    "swimming_1": "Swimming locomotion.",
    "grab_ledge_from_water_1": "Water-to-ledge transition.",
    "get_up_from_hang_1": "Ledge climb/get-up.",
    "hanging_idle_1": "Ledge/wall hanging loop.",
    "jump_into_wall_hang_1": "Wall-hang entry.",
    "jumping_into_water_1": "Downward water-entry transition.",
    "turn_1": "Save-point turn toward camera before sitting.",
    "stand_to_sit_1": "Save-point sit-down transition.",
    "sit_to_stand_1": "Save-point stand-up transition.",
    "turn_2": "Save-point turn back to gameplay profile after standing.",
}

UNUSED = {
    "attack_1": "Aerial overhead special or grapple-assisted attack.",
    "attack_2": "Running spin attack.",
    "attack_3": "Low sweep or alternate running attack.",
    "attack_4": "Pommel guard break, door knock, or contextual strike.",
    "block_2": "Alternate block entry or short guard adjustment.",
    "casting_1": "Thread magic, ranged special, or power technique.",
    "draw_sword_1": "Compare with sheath actions; likely redundant.",
    "draw_sword_2": "Compare with sheath actions; likely redundant.",
    "kick_1": "Guard break or breakable-door interaction.",
    "sheath_sword_1": "Enter a future sheathed locomotion set.",
    "sheath_sword_2": "Exit a future sheathed locomotion set.",
    "slash_1": "Standalone single slash or NPC/simple enemy attack.",
    "slash_3": "Riposte or retreating counterattack.",
    "slash_4": "Sprint, grapple, or aerial special.",
    "strafe_1": "Toward-camera cinematic movement.",
    "strafe_2": "Away-from-camera cinematic movement.",
    "strafe_3": "Fast away-from-camera cinematic movement.",
    "strafe_4": "Fast toward-camera cinematic movement.",
    "turn_180_1": "Walking direction-change transition.",
    "turn_180_2": "Sprinting direction-change transition.",
    "walk_1": "Slow forward locomotion if walking is introduced.",
    "walk_2": "Slow backward locomotion if walking is introduced.",
}

MISSING = [
    "Grapple aim/charge pose that can hold indefinitely before release.",
    "Grapple pull/reel-in, grapple release, and grapple-assisted attack variants.",
    "Air light chain plus up-air and down-air attacks.",
    "Wall slide/climb loop and a dry ledge-grab transition.",
    "Swim stop, underwater rise/dive, and water-exit variants beyond the ledge grab.",
    "Landing variants for short fall, hard fall, and grapple release.",
    "Weapon sheath locomotion/idles if sheathing becomes normal gameplay.",
    "Parry/perfect-block success, guard break, and guard-broken reaction.",
    "Sword-and-shield interaction poses for doors, levers, and pickups.",
]


def main():
    with SOURCE.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))
    lines = [
        "# Player animation inventory",
        "",
        f"Canonical Blender library: **{len(rows)} actions** at 30 FPS.",
        "",
        "## Integrated in gameplay",
        "",
        "| Action | Frames | Current use |",
        "| --- | ---: | --- |",
    ]
    for row in rows:
        if row["action"] in ACTIVE:
            lines.append(f'| `{row["action"]}` | {row["frames"]} | {ACTIVE[row["action"]]} |')
    lines += [
        "",
        "## Downloaded and retained, but not currently used",
        "",
        "| Action | Frames | Good candidate use |",
        "| --- | ---: | --- |",
    ]
    for row in rows:
        if row["action"] not in ACTIVE:
            suggestion = UNUSED.get(row["action"], "Keep available for later review.")
            lines.append(f'| `{row["action"]}` | {row["frames"]} | {suggestion} |')
    lines += ["", "## Still needed", ""]
    lines += [f"- {item}" for item in MISSING]
    lines += [
        "",
        "All source FBXs are retained under `ArtSource/Player/Blender/imported_character/mixamo_library/source`. ",
        "The Downloads-folder copies are disposable after byte-for-byte verification.",
        "",
    ]
    OUTPUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"ANIMATION_INVENTORY_READY actions={len(rows)} active={len(ACTIVE)} unused={len(rows) - len(ACTIVE)}")


main()
