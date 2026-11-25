# Deeper game-folder cleanup — November 25, 2026

Chase clarified that unused individual assets and their obsolete prototype consumers must also leave the visible game folders. This extends [the first cleanup](cleanup_2026_11_25.md).

**512 more files / 402.4 MiB** are staged for review. Nothing was permanently deleted. See [the second manifest](cleanup_manifest_2026_11_25_pass2.json) for exact source/destination paths, prior Git state, byte counts and SHA-256 hashes.

## What left the game folders

- Old keyed pavilion, stilt-house, tower-house and wide-house images, the cutaway interior, Pavilion3D_V2 model and module textures, obsolete threadglass sheet/material/shader and unused native-wind shader.
- Unused vegetation and rooftop variants, old building/platform/StillVillage prefabs, unused older character maps/model variants and unused Blue art textures.
- Unreachable Blue prototype/component scripts and their UID/import companions.
- Twenty-three obsolete Blue fixture layouts and their dedicated historical prototype/art checks. The bank-dive water fixture remains hidden under `tools/fixtures/blue_layouts/` because a retained gameplay check uses it.
- Empty source directories removed after moving their final files.

Categories are `06 Unused Blue assets` (349 files), `07 Retired Blue components and prototypes` (77 files), and `08 Retired prototype fixtures and checks` (86 files), under `Staged for Delete/2026-11-25-pass2/`, in its `Tracked/` and `Uncommitted/` sections.

## What is still required

Demo 2.0, its inherited original Chamber, the consolidated Blue reference, startup/title preview, active editor addons and current gameplay regressions were dependency roots. The scan follows global script classes, autoloads, literal resource paths, constructed resource-name prefixes, importer sidecars and normalized relative/escaped GLB image URIs. A file being mentioned by an obsolete prototype is no longer enough to keep it in the game.

The cloud billow shader/material in Chase's screenshot stays: the retained Blue level dynamically creates cloud scenes that use it. The chroma-key material and village platform texture also stay because that level loads them. Current model textures, audio registry/resources, current Eave Runner v4 and Loom Heron v3 verifiers, modular bridge regression and current player/combat/grapple/save/UI checks remain. Folder provenance and guides remain where the corresponding assets are still current.

Current paintings and all pending doll/equipment source work are preserved. No gameplay tuning, equipment behavior, scene hierarchy or approved artwork changed. Seventeen archived old-check files already contained edits; their exact saved contents are preserved in the cleanup checkpoint without approving those historical changes. The checkout's unrelated staged deletions and remaining edits are kept separate.

## Restore or verify

Use `tools/maintenance/cleanup_review.py` with this second manifest. `--verify` checks every staged destination's hash. `--restore --source "original/path"` restores a reviewed file without overwriting or changing its bytes. Restore dependent archived resources together when reopening an old prototype. The local durable journal is `tmp/cleanup-2026-11-25/pass2/moves.jsonl`.

Formerly tracked resources remain versioned under the review folder and use LFS where applicable. Twenty-five previously untracked files remain local in `Uncommitted/`. This batch has its own `.gdignore` and LFS attributes. The first review batch and its parent ignore/attribute files were already deleted when this pass began; those existing deletions remain untouched. No prior review content was restored.

## Validation

All 512 moved files match their SHA-256 hashes. The new batch uses a separate directory with its ignore marker already in place; the live editor initially queued old-path metadata imports, so the archived sidecars were restored to their exact recorded bytes. Validation completed:

- Demo 2.0 and Blue reference each launch for 90 frames in the working project; startup title launches too. Before/after error and warning counts match exactly.
- Player-presentation regression: 39 checks, zero failures.
- An isolated copy of 2,434 retained runtime/editor inputs imports from an empty `.godot` cache successfully. No missing-resource, script or parse errors. The existing editor-settings safe-save diagnostic remains.
- Demo 2.0 and Blue reference each launch for 60 frames from that fresh import. Only the same existing editable-instance and shutdown diagnostics remain.
- All 512 moved files verify against their original hashes. The importer-modified archived sidecars were restored byte-for-byte, and the separate ignored review directory prevents further imports there.
- Only one hidden historical water layout remains for a current bank-dive regression; the 23 obsolete layouts and their dedicated old prototype checks are staged.
- The temporary source/import snapshot was removed after validation, keeping the verification logs without leaving another game copy.

Cleanup checkpoint: `fd0b69b2` — `chore: retire unused Blue assets and prototype checks`. Local evidence stays under `tmp/cleanup-2026-11-25/pass2/`.

Validation uses the existing development checkout. Its pre-existing runtime/source edits and earlier deletions remain separate; this cleanup checkpoint is not a clean-checkout release validation.
