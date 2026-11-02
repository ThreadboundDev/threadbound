"""Read-only file inventory. Never follows links or changes scanned files."""

import argparse
import collections
import json
import os
from pathlib import Path


def inventory(roots):
    files, errors, skipped = [], [], []
    for root in roots:
        root = Path(root).absolute()
        if not root.exists():
            errors.append({"path": str(root), "error": "missing"})
            continue
        scan_root = Path("\\\\?\\" + str(root)) if os.name == "nt" else root
        for directory, dirs, names in os.walk(scan_root, followlinks=False,
                                               onerror=lambda e: errors.append({"path": e.filename, "error": str(e)})):
            for name in list(dirs):
                path = Path(directory, name)
                if name in {".git", "node_modules", "__pycache__"} or path.is_symlink() or path.is_junction():
                    dirs.remove(name)
                    skipped.append(str(path))
            for name in names:
                path = Path(directory, name)
                try:
                    if path.is_symlink():
                        skipped.append(str(path))
                        continue
                    info = path.stat()
                    display_path = str(path).removeprefix("\\\\?\\")
                    files.append({"path": display_path, "root": str(root),
                                  "relative": str(path.relative_to(scan_root)),
                                  "bytes": info.st_size, "modified_ns": info.st_mtime_ns})
                except OSError as error:
                    errors.append({"path": str(path), "error": str(error)})
    return {"files": files, "errors": errors, "skipped": skipped}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", action="append", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    result = inventory(args.root)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2), encoding="utf-8")
    groups = collections.defaultdict(lambda: [0, 0])
    for row in result["files"]:
        group = str(Path(row["root"]) / Path(row["relative"]).parts[0])
        groups[group][0] += 1
        groups[group][1] += row["bytes"]
    print(json.dumps({"files": len(result["files"]), "error_count": len(result["errors"]),
                      "largest_groups": dict(sorted(groups.items(), key=lambda x: -x[1][1])[:25])}, indent=2))


if __name__ == "__main__":
    main()
