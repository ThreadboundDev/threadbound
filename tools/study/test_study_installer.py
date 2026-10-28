"""Exercise preservation and interrupted-install recovery using disposable fixtures."""
from pathlib import Path
from tempfile import TemporaryDirectory
import importlib.util

ROOT = Path(__file__).resolve().parents[2]
TEMP = ROOT / 'work/third-person-study-2026-10-28/temp'
spec = importlib.util.spec_from_file_location('study_installer', Path(__file__).with_name('install_third_person_study.py'))
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


def refused():
    try:
        installer.main()
    except SystemExit:
        return
    raise AssertionError('Conflicting manual data was not preserved')


with TemporaryDirectory(prefix='installer-check-', dir=TEMP) as temporary:
    folder = Path(temporary).resolve()
    assert folder.is_relative_to(TEMP.resolve())
    source, target = folder / 'source', folder / 'target'
    source.mkdir()
    installer.SOURCE = source
    installer.DESTINATION = target
    installer.MARKER = target / '.threadbound-study-install.json'
    (source / 'a.txt').write_text('old-a')
    (source / 'b.txt').write_text('old-b')
    (source / 'polish_test_results.json').write_text('generated')
    installer.main()
    assert not (target / 'polish_test_results.json').exists()
    (target / 'a.txt').write_text('manual edit')
    (source / 'a.txt').write_text('new-a')
    (source / 'b.txt').write_text('new-b')
    refused()
    assert (target / 'a.txt').read_text() == 'manual edit'
    assert (target / 'b.txt').read_text() == 'old-b'
    print('PASS manual edits preserved before any write')
    (target / 'a.txt').write_text('old-a')
    (source / 'c.uid').write_text('uid://new')
    (target / 'c.uid').write_text('uid://unrecognized')
    refused()
    assert (target / 'b.txt').read_text() == 'old-b'
    print('PASS unexpected file conflict preflight is atomic')
    (target / 'c.uid').write_text('uid://new')
    (target / 'a.txt').write_text('new-a')  # Simulate a previously interrupted copy.
    installer.main()
    assert (target / 'b.txt').read_text() == 'new-b'
    print('PASS identical generated UID adopted; interrupted copy recovered')
    try:
        installer.installed_path('../outside.txt')
    except ValueError:
        print('PASS install paths cannot escape the destination')
    else:
        raise AssertionError('Path traversal was accepted')
