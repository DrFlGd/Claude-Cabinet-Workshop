# Windows portable build

The desktop wrapper loads the same static application as the website through
`cabinet://app/`. Assets, engine sources, OpenSCAD WASM and fonts are local; no
hosting or separately installed OpenSCAD is needed. Renderer Node integration is
disabled, context isolation/sandboxing are enabled, and navigation stays within
the app except HTTPS links opened in the system browser.

Build with the repository's Node/pnpm versions and Python 3.11 or later:

```sh
pnpm install --frozen-lockfile
pnpm run build:desktop:renderer
python desktop/package-windows.py /path/electron-v44.4.3-win32-x64.zip /path/SHASUMS256.txt /path/empty-output-folder --source-revision GITHUB_APPLICATION_COMMIT
```

Obtain the runtime ZIP and checksum manifest from the corresponding official
Electron release. The packager checks SHA-256, ZIP CRCs and the Windows x64 PE
header, requires a clean destination, retains upstream licenses, and takes the
application version from package.json. After a passing Windows smoke test, `python desktop/archive-windows.py OUTPUT_FOLDER
Claude-Cabinet-Workshop-v0.7.0-Windows-x64.zip` creates and CRC-verifies the portable ZIP
without renaming the recently executed folder.
Generated binaries stay out of the source repository.

Extract everything and run `Cabinet Workshop.exe`; copying only that EXE will not
work. This is an unsigned portable test build, not a single-file installer. Windows
may show an unrecognized-app warning. The Windows workflow launches the packaged EXE and verifies UI readiness and a
photo-example OpenSCAD render through the actual local protocol. Manual interactive
testing remains necessary. Menu Help → About identifies the application
version. Use Save design/Open design to transfer work between web and desktop;
autosave remains in the desktop application's own user profile.

`node tests/desktop-assets.cjs` checks offline asset resolution and build contents.
The production worker smoke tests are available through `pnpm run test:sections:wasm`.

The window opens immediately with a starting page. Each launch then checks that
the executable, DLLs, resource packs, snapshots and locale packs are present
with the size recorded at build time (metadata only), retrying for a few seconds
while Windows is still extracting them. Help → Verify program files
compares their SHA-256 hashes (the packaged smoke test does the same), and
Help → Open start-up log shows the last launch's log. Always extract a new
version into a fresh folder. A startup error identifies missing or mismatched
runtime files. Windows smoke tests now reject visible document metadata/style
text or a displaced header, and include `WINDOWS-LAYOUT.png` for visual review.
