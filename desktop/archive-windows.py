"""Archive a portable build without renaming a recently executed Windows folder."""
import argparse, json, pathlib, zipfile
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('folder', type=pathlib.Path)
p.add_argument('archive', type=pathlib.Path)
a = p.parse_args()
if not json.loads((a.folder/'WINDOWS-SMOKE-TEST.json').read_text(encoding='utf-8')).get('passed'):
    raise ValueError('A passing Windows smoke test is required')
with zipfile.ZipFile(a.archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as z:
    for f in sorted(a.folder.rglob('*')):
        if f.is_file():
            z.write(f, pathlib.Path(a.archive.stem)/f.relative_to(a.folder))
with zipfile.ZipFile(a.archive) as z:
    bad = z.testzip()
    if bad:
        raise ValueError('Archive verification failed: '+bad)
print(a.archive, a.archive.stat().st_size, 'bytes; CRC verification passed')
