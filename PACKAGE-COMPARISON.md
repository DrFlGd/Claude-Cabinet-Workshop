# Cabinet Workshop v5 Source Package Comparison

Comparison direction: `Cabinet-Workshop-v5-Source.zip` → `Cabinet-Workshop-v5-Fixed-Source.zip`

## Conclusion

`Cabinet-Workshop-v5-Fixed-Source.zip` is the newer package with high confidence.

Evidence:

- The original package's newest internal ZIP timestamp is 2026-09-25 02:24:46.
- The fixed package contains changes through 2026-09-25 03:44:06.
- Desktop documentation/package metadata advances from 0.3.0 to 0.3.1.
- The fixed archive retains all files from the earlier archive, modifies 9 files, adds 6 files, and removes none.
- `STARTUP-FIX.md` explicitly documents the repair and validation performed after the earlier v5 source.

Archive SHA-256:

- Original: `d75ee067c870553b5199d8e69efc5cf55b82fb635eeffa904342a9a769f7b76a`
- Fixed: `2899b7c0a14bd2b35ad24a62deaa0e18d773c56fe17c9cc8bbd3c80343cdaf28`

## File-level summary

- Original package files: 518
- Fixed package files: 524
- Byte-identical files: 509
- Modified files: 9
- Added files: 6
- Removed files: 0

## Changelog

### Startup crash repair

`lib/units.ts` changes dimensional-field classification so choice fields, booleans, strings, counts, and relative weighting arrays are not interpreted as physical dimensions just because schema metadata contains `unit: "mm"`.

This repairs the documented startup exception caused by `width_basis` being treated as a dimensional value and eventually reaching `fromMillimeters(...).toFixed(...)` with the string value `"outside"`.

Independent comparison of the two implementations confirms:

- Older source: `width_basis`, `apply_kerf_compensation`, and `mixed_bay_width_weights` are incorrectly classified as length fields.
- Fixed source: those fields are non-dimensional, while `cabinet_width` remains dimensional.

### Web/renderer bootstrap diagnostics

Added `desktop/bootstrap.js` and changed the root `index.html` to load it instead of loading `desktop/entry.tsx` directly.

The bootstrap displays a visible startup message and catches dynamic-import failures, replacing a blank page with an error message and stack information.

`desktop/entry.tsx` now wraps the application in a React startup error boundary. Unhandled render failures show a recovery/error screen and provide a reload button.

### Electron startup diagnostics

`desktop/main.cjs` now:

- writes startup diagnostics to `startup.log` in Electron user data;
- logs asset failures, renderer console warnings/errors, failed navigation, and renderer termination;
- displays error dialogs for failed page loads or renderer crashes;
- adds View → Toggle Developer Tools;
- adds View → Open startup log;
- reports startup as Cabinet Workshop desktop 0.3.1.

### Desktop version bump

`desktop/README.md` and `desktop/package-windows.py` advance the desktop build from version 0.3.0 to 0.3.1.

### Regression testing

Added `tests/startup.cjs` and a new `pnpm run test:startup` script in `package.json`.

The new startup regression test is designed to render the complete initial page and iterate dimensional controls across schema families/starters in both millimeters and inches. `STARTUP-FIX.md` reports that 13,807 scalar dimensional field configurations were validated.

The full test command could not be independently rerun from these source ZIPs in the comparison environment because the archives do not contain installed project dependencies such as React/Vite. The dimensional-classification fix itself was independently executed and verified from the supplied TypeScript/schema files.

### Static web build regenerated

`web-dist/index.html` now loads the new bootstrap-oriented bundle `assets/index-B9qnBDe5.js`.

Added generated assets:

- `web-dist/assets/index-B9qnBDe5.js`
- `web-dist/assets/entry-Ceo29_2b.js`
- `web-dist/assets/entry-Uo-JXa0W.css`

The new small index bundle loads the application entry dynamically and handles bootstrap failures; the application/CSS were split into the new entry assets.

### Documentation

Added `STARTUP-FIX.md`, documenting the reproduced crash, repair, validation scope, Windows usage notes, and diagnostic workflow.

`HOSTING.md` now points to the startup-repair notes and recommends running `pnpm run test:startup` before packaging.

## Modified files

- `HOSTING.md`
- `desktop/README.md`
- `desktop/entry.tsx`
- `desktop/main.cjs`
- `desktop/package-windows.py`
- `index.html`
- `lib/units.ts`
- `package.json`
- `web-dist/index.html`

## Added files

- `STARTUP-FIX.md`
- `desktop/bootstrap.js`
- `tests/startup.cjs`
- `web-dist/assets/entry-Ceo29_2b.js`
- `web-dist/assets/entry-Uo-JXa0W.css`
- `web-dist/assets/index-B9qnBDe5.js`

## Potential cleanup note

The fixed source archive still contains the prior generated web assets `web-dist/assets/index-B3Un7tzr.js` and `web-dist/assets/index-CTotjU-P.css`. They are no longer referenced by the fixed `web-dist/index.html` or by the new bundle graph, so they appear to be stale build artifacts rather than active code. Removing them before a production source release would reduce ambiguity and archive size.

## Overall interpretation

This is a targeted hotfix release, not a new cabinet-feature revision. The application feature/source files are overwhelmingly identical between the packages. The meaningful delta is startup robustness, unit-field classification, diagnostics, regression testing, a regenerated static bundle, and a desktop patch-version bump.
