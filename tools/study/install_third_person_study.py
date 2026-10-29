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


def installed_path(name):
    path = DESTINATION / name
    if not path.resolve().is_relative_to(DESTINATION.resolve()):
        raise ValueError(f'Install path escapes the study folder: {name}')
    return path


def main():
    files = [p for p in SOURCE.rglob('*') if p.is_file() and '.godot' not in p.parts
             and p.suffix not in {'.log', '.import'}
             and p.name not in {'test_results.json', 'combat_test_results.json', 'polish_test_results.json', 'demo_feel_test_results.json', 'demo_feel_results.json', 'committed_combat_test_results.json'} and 'captures' not in p.relative_to(SOURCE).parts
             and not (p.parent in {SOURCE / 'assets', SOURCE / 'assets/enemies', SOURCE / 'assets/village', SOURCE / 'assets/local_licensed'} and p.suffix in {'.png', '.jpg'})]
    if DESTINATION.exists():
        if not MARKER.exists():
            raise SystemExit(f'Refusing to overwrite an existing unrecognized folder: {DESTINATION}')
        previous = json.loads(MARKER.read_text(encoding='utf-8'))
        changed = [name for name, sha in previous['files'].items()
                   if installed_path(name).exists() and digest(installed_path(name)) != sha
                   and (not (SOURCE / name).exists() or digest(installed_path(name)) != digest(SOURCE / name))]
        if changed:
            raise SystemExit(f'Preserved manually edited study files; reconcile before updating: {changed}')
    DESTINATION.mkdir(parents=True, exist_ok=True)
    # Validate the complete update before copying any file. Identical existing files
    # can be adopted safely, including Godot-generated UID files and interrupted copies.
    for file in files:
        relative = file.relative_to(SOURCE)
        destination = installed_path(relative)
        if destination.exists() and (not MARKER.exists() or relative.as_posix() not in previous['files']):
            if digest(destination) != digest(file):
                raise SystemExit(f'Preserved unexpected existing file: {destination}')
    manifest = {}
    for file in files:
        relative = file.relative_to(SOURCE)
        destination = installed_path(relative)
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(file, destination)
        manifest[relative.as_posix()] = digest(destination)
    # Remove only unchanged files owned by the previous installation. Manual edits
    # were rejected in preflight, and installed_path confines deletion to this study.
    if MARKER.exists():
        for name, sha in previous['files'].items():
            obsolete = installed_path(name)
            if name not in manifest and obsolete.is_file() and digest(obsolete) == sha:
                obsolete.unlink()
    MARKER.write_text(json.dumps({'source': str(SOURCE), 'files': manifest}, indent=2), encoding='utf-8')
    print(f'Installed {len(manifest)} source files in {DESTINATION}')


if __name__ == '__main__':
    main()
