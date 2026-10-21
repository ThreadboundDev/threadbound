# Existing village walkway stamps

Byte-identical source copies from the current consolidated Slate Library,
prepared October 21, 2026 at Chase's request. These are review/source assets;
`.gdignore` keeps them out of Godot imports until the runtime pass is approved.
No game scene, existing artwork or collision was replaced by this preparation.

- `A04_Japanese_Engawa_Landing.png`: house-side balcony/landing with supports.
- `B04_Simple_Plank_Crossing.png`: simple intact crossing.
- `J03_Japanese_Veranda.png`: railed timber walkway/veranda.
- `J04_Matched_Broken_Bridge.png`: broken pair; keep the visual opening separate
  from any real authored gap and do not infer new collision from transparency.
- `T01_Rock_Timber_Landing.png`: rock-attached timber landing reference.
- `Walkways.png`: original library category sheet for review.

The library's own START_HERE identifies it as the current kit, superseding its
historical source folders. `provenance.json` preserves source paths, original
manifest entries, dimensions, alpha ranges and SHA-256 fingerprints. Each PNG
was copied without image editing, recoloring or resampling. Git LFS stores them.

Recommended next step: reusable 2D objects using these source silhouettes and
material treatment, with fixed-scale ends/posts and repeated middle spans.
The file-specific integration proposal is
`docs/design/lakeside_walkway_stamp_proposal.md` in the repository root.
