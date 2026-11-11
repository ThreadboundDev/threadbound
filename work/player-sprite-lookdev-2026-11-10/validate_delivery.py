"""Audit the delivered frames, original-source integrity and engine evidence."""
import ast
import hashlib
import json
import subprocess
from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[1]
inspection = json.loads((OUT / "source_inspection.json").read_text())
source = ROOT / inspection["source"]
assert hashlib.sha256(source.read_bytes()).hexdigest() == inspection["sha256"]
manifest = json.loads((OUT / "sprite_manifest.json").read_text())
assert manifest["cell"] == [240, 320]
frames = manifest["frames"]
assert len(frames) == 51
spans = {"idle": (1, 77, 31), "run": (78, 99, 9), "jump": (100, 125, 11)}
clipped = []
for clip, (start, end, count) in spans.items():
    records = [r for r in frames if r["clip"] == clip]
    assert len(records) == count
    assert all(start <= r["frame"] <= end for r in records)
    assert all(a["frame"] < b["frame"] for a, b in zip(records, records[1:]))
    assert abs(sum(r["duration_ms"] for r in records) - (end - start + 1) / 30 * 1000) <= count / 2
    with Image.open(OUT / "sprites" / f"{clip}.png") as atlas:
        assert atlas.width == 1920
        for record in records:
            x, y, width, height = record["region"]
            assert x >= 0 and y >= 0 and x + width <= atlas.width and y + height <= atlas.height
    with Image.open(OUT / f"{clip}_preview.gif") as gif:
        gif.verify()
    for record in records:
        with Image.open(OUT / record["file"]) as im:
            assert im.size == (600, 800)
            bounds = im.getchannel("A").getbbox()
            assert bounds is not None
            gutter = min(bounds[0], bounds[1], im.width - bounds[2], im.height - bounds[3])
            if gutter <= manifest["outline_source_radius"]:
                clipped.append(record["file"])
assert not clipped
jumps = [r for r in frames if r["clip"] == "jump"]
assert all("removed_vertical_travel_m" in r for r in jumps)
assert max(r["removed_vertical_travel_m"] for r in jumps) > 0
capture = json.loads((OUT / "chamber_capture_report.json").read_text())
assert capture["renderer"] == "forward_plus"
assert "Threadbound Sprite Study" in capture["user_data"]
assert capture["player_on_floor"] is True
assert capture["controller_integrated"] is False
assert capture["production_files_modified"] is False
for name in ["current", "rendered", "rendered_lit", "reference_pair"]:
    with Image.open(OUT / f"chamber_{name}.png") as im:
        assert im.size == (1920, 1080)
        im.verify()
for script in OUT.glob("*.py"):
    ast.parse(script.read_text(encoding="utf-8"))

# Ensure the existing unrelated working-tree changes have not disappeared or
# acquired new status flags. Content changes to the work list are deliberate.
baseline_path = OUT / "temp/baseline_status.txt"
baseline_check = "not available (local first-run audit only)"
if baseline_path.exists():
    prefix = "work/player-sprite-lookdev-2026-11-10/"
    def unrelated(line):
        return prefix not in line and line[3:] != "docs/project_status_and_worklist.md"
    baseline = {line for line in baseline_path.read_text(encoding="utf-8-sig").splitlines() if unrelated(line)}
    current_lines = subprocess.check_output(["git", "status", "--porcelain=v1"], cwd=ROOT, text=True).splitlines()
    current = {line for line in current_lines if unrelated(line)}
    assert current == baseline, {"added": sorted(current - baseline), "missing": sorted(baseline - current)}
    baseline_check = "same unrelated path/status set as task start"

report = {"source_sha256": inspection["sha256"], "source_unchanged": True, "fixed_canvas_frames": len(frames), "frames_touching_outline_gutter": clipped, "clip_counts": {clip: count for clip, (_, _, count) in spans.items()}, "jump_lift_removed": True, "engine_captures": 4, "renderer": capture["renderer"], "controller_integrated": False, "unrelated_working_tree": baseline_check, "engine_shutdown_diagnostics": "Texture RID/ObjectDB/resource cleanup diagnostics remain; see README", "visual_acceptance": "Pending Chase review"}
(OUT / "validation.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
print(json.dumps(report, indent=2))
