"""Apply an explicit, reviewed local organization plan without deleting files.

Only same-volume renames are permitted. A durable JSONL journal supports recovery.
Run without --apply to validate paths and preview totals. Never overwrites a target.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path


def disk(path):
    return Path("\\\\?\\" + str(path)) if os.name == "nt" else path


def validate(row, source_roots, destination_roots):
    source = Path(row["source"]).resolve()
    target = Path(row["destination"]).resolve()
    if not any(source != root and source.is_relative_to(root) for root in source_roots):
        raise ValueError(f"Source outside approved roots: {source}")
    if not any(target != root and target.is_relative_to(root) for root in destination_roots):
        raise ValueError(f"Target outside approved roots: {target}")
    if source.drive != target.drive or target.is_relative_to(source):
        raise ValueError(f"Unsafe rename: {source} -> {target}")
    if disk(source).is_symlink() or disk(source).is_junction():
        raise ValueError(f"Refusing to move a link: {source}")
    if not disk(source).exists():
        raise FileNotFoundError(source)
    if disk(target).exists():
        raise FileExistsError(target)
    if row.get("sha256"):
        with disk(source).open("rb") as stream:
            if hashlib.file_digest(stream, "sha256").hexdigest() != row["sha256"]:
                raise ValueError(f"Source hash changed: {source}")
        keeper = Path(row["keeper"]).resolve()
        with disk(keeper).open("rb") as stream:
            if hashlib.file_digest(stream, "sha256").hexdigest() != row["sha256"]:
                raise ValueError(f"Retained duplicate changed: {keeper}")
    return source, target


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("plan", type=Path)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--journal", type=Path, required=True)
    args = parser.parse_args()
    plan = json.loads(args.plan.read_text(encoding="utf-8"))
    sources = [Path(p).resolve() for p in plan["source_roots"]]
    destinations = [Path(p).resolve() for p in plan["destination_roots"]]
    # Validate the whole batch before its first mutation. Sources in a parent
    # move still exist here; file moves deliberately precede the parent rename.
    targets = set()
    for row in plan["moves"]:
        _, target = validate(row, sources, destinations)
        key = str(target).casefold()
        if key in targets:
            raise ValueError(f"Repeated target: {target}")
        targets.add(key)
    print(json.dumps({"moves": len(plan["moves"]), "apply": args.apply}))
    if not args.apply:
        return
    args.journal.parent.mkdir(parents=True, exist_ok=True)
    # Exclusive creation prevents accidentally applying a batch twice.
    with args.journal.open("x", encoding="utf-8") as journal:
        for index, row in enumerate(plan["moves"]):
            source, target = validate(row, sources, destinations)
            disk(target.parent).mkdir(parents=True, exist_ok=True)
            before = disk(source).stat()
            intent = {"index": index, "state": "intent", **row}
            journal.write(json.dumps(intent) + "\n")
            journal.flush()
            os.fsync(journal.fileno())
            os.rename(disk(source), disk(target))
            after = disk(target).stat()
            if (before.st_ino, before.st_dev) != (after.st_ino, after.st_dev):
                raise RuntimeError(f"Rename identity changed: {target}")
            journal.write(json.dumps({"index": index, "state": "done", **row}) + "\n")
            journal.flush()
            os.fsync(journal.fileno())
    print("Completed. No files permanently deleted.")


if __name__ == "__main__":
    main()
