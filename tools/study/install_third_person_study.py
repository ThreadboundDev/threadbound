"""Copy the independent Godot study beside the main project, preserving manual edits."""
from pathlib import Path
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'work/third-person-study-2026-10-28/project'
DESTINATION = Path.home() / 'Documents/Threadbound 3D Study'
MARKER = DESTINATION / '.threadbound-study-install.json'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    files = [p for p in SOURCE.rglob('*') if p.is_file() and '.godot' not in p.parts
             and p.suffix not in {'.log', '.import'}
             and p.name not in {'test_results.json', 'combat_test_results.json'} and 'captures' not in p.relative_to(SOURCE).parts
             and not (p.parent in {SOURCE / 'assets', SOURCE / 'assets/enemies'} and p.suffix in {'.png', '.jpg'})]
    if DESTINATION.exists():
        if not MARKER.exists():
            raise SystemExit(f'Refusing to overwrite an existing unrecognized folder: {DESTINATION}')
        previous = json.loads(MARKER.read_text(encoding='utf-8'))
        changed = [name for name, sha in previous['files'].items()
                   if (DESTINATION / name).exists() and digest(DESTINATION / name) != sha]
        if changed:
            raise SystemExit(f'Preserved manually edited study files; reconcile before updating: {changed}')
    DESTINATION.mkdir(parents=True, exist_ok=True)
    manifest = {}
    for file in files:
        relative = file.relative_to(SOURCE)
        destination = DESTINATION / relative
        if destination.exists() and (not MARKER.exists() or relative.as_posix() not in previous['files']):
            raise SystemExit(f'Preserved unexpected existing file: {destination}')
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(file, destination)
        manifest[relative.as_posix()] = digest(destination)
    MARKER.write_text(json.dumps({'source': str(SOURCE), 'files': manifest}, indent=2), encoding='utf-8')
    print(f'Installed {len(manifest)} source files in {DESTINATION}')


if __name__ == '__main__':
    main()
