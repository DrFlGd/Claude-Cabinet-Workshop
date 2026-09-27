"""Package a checksum-verified Electron Windows x64 runtime and static renderer."""
import argparse, hashlib, json, pathlib, shutil, struct, zipfile

root = pathlib.Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('runtime', type=pathlib.Path)
p.add_argument('checksums', type=pathlib.Path)
p.add_argument('output', type=pathlib.Path)
p.add_argument('--source-revision', required=True, help='GitHub revision used for the application renderer')
a = p.parse_args()
runtime, out = a.runtime.resolve(), a.output.resolve()
expected = next((line.split()[0] for line in a.checksums.read_text().splitlines()
                 if len(line.split()) == 2 and line.split()[1].lstrip('*') == runtime.name), None)
actual = hashlib.file_digest(runtime.open('rb'), 'sha256').hexdigest()
if actual != expected:
    raise ValueError('Electron runtime checksum mismatch or missing manifest entry')
renderer = root / 'web-dist'
if not (renderer / 'index.html').is_file() or '<base href="/">' not in (renderer / 'index.html').read_text():
    raise ValueError('Run npm run build:desktop:renderer first (root-relative asset paths required)')
if out.exists() and any(out.iterdir()):
    raise ValueError('Choose an empty output directory; existing builds are not overwritten')
out.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(runtime) as archive:
    for entry in archive.infolist():
        if not (out / entry.filename).resolve().is_relative_to(out):
            raise ValueError('Unsafe runtime archive path')
    bad = archive.testzip()
    if bad:
        raise ValueError('Corrupt runtime archive: ' + bad)
    archive.extractall(out)
exe = out / 'electron.exe'
with exe.open('rb') as f:
    if f.read(2) != b'MZ':
        raise ValueError('Expected Windows executable')
    f.seek(0x3c); offset = struct.unpack('<I', f.read(4))[0]
    f.seek(offset)
    if f.read(6) != b'PE\x00\x00\x64\x86':
        raise ValueError('Expected Windows x64 PE executable')
exe.rename(out / 'Cabinet Workshop.exe')
app = out / 'resources/app'
app.mkdir(parents=True, exist_ok=True)
for name in ['main.cjs', 'assets.cjs', 'smoke.cjs']:
    shutil.copyfile(root / 'desktop' / name, app / name)
shutil.copytree(renderer, app / 'renderer')
version = json.loads((root / 'package.json').read_text())['version']
(app / 'package.json').write_text(json.dumps(dict(name='cabinet-workshop-desktop', productName='Cabinet Workshop', version=version, main='main.cjs'), indent=2)+'\n')
(out / 'resources/default_app.asar').unlink(missing_ok=True)
(out / 'BUILD-INFO.json').write_text(json.dumps(dict(application_version=version, application_source=a.source_revision, electron_archive=runtime.name, electron_sha256=actual, architecture='Windows x64', signed_by_project=False), indent=2)+'\n')
shutil.copyfile(root / 'CHANGELOG.md', out / 'CHANGELOG.md')
shutil.copyfile(root / 'examples/photo-section-cabinet.cabinet.json', out / 'Photo-example.cabinet.json')
(out / 'START-HERE.txt').write_text(f'''Cabinet Workshop {version} — Windows x64 portable test build

1. Extract ALL files from the ZIP into a folder.
2. Open Cabinet Workshop.exe inside that folder.
3. Keep resources, DLLs, locales and the other runtime files beside the EXE.

No website hosting, Node.js installation or separate OpenSCAD installation is required.
This build contains the local OpenSCAD WASM renderer and engine sources.

Photo example: choose Kitchen cabinet, then the starter named
Photo example · six drawers and paired doors (Section layouts group).
You can also Open design and select the included Photo-example.cabinet.json.

Use Save design for portable backups. Desktop autosave is separate from browser storage.
This is an unsigned testing build, not an installer. Windows may identify it as
an unrecognized application. See WINDOWS-SMOKE-TEST.json for automated Windows startup/render checks.
Manual interactive testing remains necessary.

Interior section supports are butt-fit blanks requiring suitable mounting hardware
or shop-drilled fastening. See the included changelog for scope and limitations.
''', encoding='utf-8')
print('Packaged Windows x64:', out)
