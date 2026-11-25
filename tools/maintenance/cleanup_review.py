"""Preview, apply, verify or restore a hash-checked repository cleanup manifest.

No permanent deletion, overwriting, link traversal or paths outside the repository.
By default this only previews. --restore can be restricted with --source PATH.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def disk(path):
    # Archived paths can exceed Windows' legacy 260-character API limit.
    return Path("\\\\?\\" + str(path)) if os.name == "nt" else path


def checked_path(value):
    relative = Path(value)
    if relative.is_absolute() or ".." in relative.parts:
        raise ValueError(f"Not a repository-relative path: {value}")
    if not relative.parts or relative.parts[0] in {".git", ".agents", ".codex"}:
        raise ValueError(f"Protected path: {value}")
    path = ROOT / relative
    for part in [path, *path.parents]:
        if part == ROOT:
            break
        if disk(part).is_symlink() or disk(part).is_junction():
            raise ValueError(f"Refusing link traversal: {part}")
    if not path.resolve().is_relative_to(ROOT):
        raise ValueError(f"Path escapes repository: {value}")
    return path


def digest(path):
    with disk(path).open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--apply", action="store_true")
    mode.add_argument("--restore", action="store_true")
    mode.add_argument("--verify", action="store_true")
    parser.add_argument("--source", action="append", help="Original path to restore/inspect")
    parser.add_argument("--journal", default="tmp/cleanup-2026-11-25/moves.jsonl")
    args = parser.parse_args()
    manifest = json.loads(args.manifest.read_text(encoding="utf-8-sig"))
    rows = manifest["moves"]
    if args.source:
        wanted = set(args.source)
        rows = [row for row in rows if row["source"] in wanted]
        if {row["source"] for row in rows} != wanted:
            raise ValueError("A requested source is absent from the manifest")
    sources, targets, prepared = set(), set(), []
    # Preflight the entire selected batch before making the first change.
    for row in rows:
        original = checked_path(row["source"])
        staged = checked_path(row["destination"])
        source, target = (staged, original) if args.restore else (original, staged)
        if original == staged:
            raise ValueError(f"Source equals destination: {original}")
        if source in sources or target in targets:
            raise ValueError("Repeated source or destination")
        sources.add(source)
        targets.add(target)
        if (args.apply or not (args.restore or args.verify)) and not disk(source).exists():
            if disk(target).is_file() and digest(target) == row["sha256"]:
                continue  # Resume an interrupted, journaled batch safely.
        content = staged if args.verify else source
        if not disk(content).is_file() or digest(content) != row["sha256"]:
            raise ValueError(f"Missing or changed file: {content}")
        if args.verify:
            if disk(original).exists():
                raise ValueError(f"Original path has reappeared: {original}")
        elif disk(target).exists():
            raise FileExistsError(target)
        prepared.append((source, target, row))
    if sources & targets:
        raise ValueError("Overlapping source/destination sets")
    print(json.dumps({"files": len(rows), "bytes": sum(row["bytes"] for row in rows),
                      "mode": "verify" if args.verify else "restore" if args.restore
                      else "apply" if args.apply else "preview"}))
    if not (args.apply or args.restore):
        return
    journal = checked_path(args.journal)
    journal.parent.mkdir(parents=True, exist_ok=True)
    with journal.open("a", encoding="utf-8") as stream:
        for source, target, row in prepared:
            # Check again at mutation time, then rename without overwriting.
            checked_path(source.relative_to(ROOT))
            checked_path(target.relative_to(ROOT))
            if disk(target).exists() or digest(source) != row["sha256"]:
                raise ValueError(f"File changed after preflight: {source}")
            disk(target.parent).mkdir(parents=True, exist_ok=True)
            event = {"source": str(source.relative_to(ROOT)),
                     "destination": str(target.relative_to(ROOT)), "sha256": row["sha256"]}
            stream.write(json.dumps({"state": "intent", **event}) + "\n")
            stream.flush()
            os.fsync(stream.fileno())
            disk(source).rename(disk(target))
            if digest(target) != row["sha256"]:
                raise ValueError(f"Destination verification failed: {target}")
            stream.write(json.dumps({"state": "done", **event}) + "\n")
            stream.flush()
            os.fsync(stream.fileno())
    print("Complete; every moved file verified. No files permanently deleted.")


if __name__ == "__main__":
    main()
