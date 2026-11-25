# Staged for deletion — review before removing anything

Nothing here has been permanently deleted. Approximately 3.35 GiB of obsolete scenes, unused runtime assets, old art deliveries and art backups are grouped by reason.

- `Tracked/`: formerly versioned files; the cleanup checkpoint preserves their contents.
- `Uncommitted/`: previously untracked files, preserved locally for review.
- `LocalOnly/`: previously ignored local art/recovery files; these stay local.

Each category keeps the original repository-relative paths. The parent `.gdignore` keeps this material out of Godot. Do not move the review folder into `Assets` or `Src`.

Read [the cleanup report](../../docs/organization/cleanup_2026_11_25.md) and [per-file manifest](../../docs/organization/cleanup_manifest_2026_11_25.json) for the exact original path and hash. The report includes safe restoration commands. Review before any permanent deletion; Git does not back up `LocalOnly` or previously untracked files.
