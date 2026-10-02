# Development and verification

Use Node 24 and pnpm 11.25.0. See [HOSTING.md](../HOSTING.md) for installation,
local serving and deployment. Application versioning is defined in the
[changelog](../CHANGELOG.md); engine versions are independent.

## Source map

| Area | Location |
|---|---|
| Configuration workspace | app/page.tsx |
| Cabinet type and starter picker | app/FamilyPicker.tsx |
| Presentation, help and dependencies | lib/settings.ts, lib/help.ts, app/SettingHelp.tsx |
| Background engine check, cut list and fit report | app/useEngineAnalysis.ts, lib/analysis.ts, app/PlanPanel.tsx, app/FitTargetResult.tsx |
| Dimension entry (fractions, unit suffixes) | lib/units.ts, app/DimensionInput.tsx |
| Design normalization and source export | lib/cabinet.ts |
| Local recovery | app/useProjects.tsx, lib/projects.ts |
| Schematic and exact rendering | app/CabinetView.tsx, app/SchematicScene.tsx, app/OpenSCADView.tsx |
| Manufacturing review | app/ManufacturingExport.tsx, lib/manufacturing.ts, lib/assembly.ts |
| Static bootstrap | static/, vite.static.config.ts |
| Browser engine runtime | public/openscad/ |
| Native engine package | public/engine/v5/ |
| Generated UI schema and embedded source | lib/schema.json, lib/engine-sources.json |
| Application-owned kitchen catalog | catalog/kitchen-standard-recipes.json |

## Checks

From the repository root, after installing dependencies:

```sh
pnpm exec tsc --noEmit --incremental false
pnpm run test:release
pnpm run build:static
```

`test:release` also runs:

- `scripts/sync-engine-sources.mjs --check`: the browser renders from the embedded
  copies in lib/engine-sources.json, so every edit under public/engine must be
  followed by `pnpm run sync:engine`.
- `tests/engine-fit.mjs`: the production export worker evaluates every starter and
  a set of regression configurations; it fails on undefined engine values, engine
  errors, BOM rows without sizes or drawer boxes that do not fit their openings.
- `tests/engine-interference.mjs`: renders sub-assemblies (carcass sides, bottom
  and top, rear construction, shelves, dividers and separators, partitions, rails,
  face frame, alternating drawers, doors) of representative designs with the
  bundled OpenSCAD WASM and intersects every pair, so tabs and tongues are checked
  against the parts that receive them. Correct joinery only touches; any overlap
  volume fails the test. `CASES='[[family,starter,{...}]]'` runs chosen designs.

- `tests/layout-editor.mjs`: the Layout tab's model (lib/layout.ts) against the
  engine. Every starter of the five cabinet types with a layout editor must map
  back to identical engine fronts, the editor's openings must match the engine's
  LAYOUT report, and typed widths, drawer front heights and door heights must
  come out exactly in the engine; unsupported arrangements must be refused.

- `tests/golden.mjs`: the engine's parts list and reports (BOM, DIM, LAYOUT, CHECK,
  WARN, HARDWARE and TARGET records) and fingerprints of the cut and pocket SVG
  layouts for all 110 starters must match `tests/golden/*.json`. Any engine change
  that alters a starter fails until it is accepted with `pnpm run golden:update`;
  the diff of the JSON files then shows exactly which parts or dimensions changed,
  for review in the same commit. About 2.5 minutes on two cores.
- `scripts/parity.mjs --check`: `docs/PARITY.md`, the generated table of features,
  options and front layouts per cabinet type, must be current (`pnpm run parity`
  regenerates it).

`pnpm run test:engine` runs the three engine suites alone (about six minutes on a
two-core machine). The release tests require native OpenSCAD on PATH for stackable geometry checks.
Browser use does not require native OpenSCAD. For the material-specific geometry
check, also install Python 3.10+ and run `python3 tests/material-relief.py` from the
repository root. Engine regression/matrix commands are documented in the engine
README and run from public/engine/v5 with the package installed.

Older version-named tests may intentionally encode historical file names/counts;
not every historical test is part of current CI. The release workflow defines
its actual gate. Historical reports are evidence for their stated source/version,
not a claim that all checks passed against today's tree. See the changelog for
browser-visual, desktop and manufacturing validation limits.

## Engine maintenance

Keep native resources, generated schema and lib/engine-sources.json synchronized
(`pnpm run sync:engine` refreshes the embedded copies of existing files).

OpenSCAD evaluates top-level assignments in file order. A function that runs
while an earlier variable is assigned must not read a variable assigned later in
the file (it is `undef` at that point); resolve such values from the public inputs
instead. The engine-fit suite fails on the resulting `undefined operation` warnings.
The browser and source exports use the embedded source map; changing only the
public SCAD file can leave them stale. Documentation included in that map also
needs synchronization. Preserve original runtime licenses and legacy source paths.

The importer is `scripts/import-modular-engine.py`. It expects a separate package
root with src/modular_organization/data, and currently reads the provenance ZIP at
`<package-root>/../../upload/modular_organization_v5.zip`. Prepare that staging
layout before running it; do not import the destination package onto itself.
It imports native presets/hardware, preserves the application kitchen catalog,
and generates schema/source data and the worker allowlist. Review its output and
provenance when importing a different upstream archive.

UI-specific presentation lives in lib/settings.ts: mount/rear-construction grouping, front regrouping, material
subgroups, advanced kerf classification and mid-rail help are intentional adapter
rules. Native parameter grouping remains governed by the engine layout contract.
Do not evaluate OpenSCAD default expressions in JavaScript.

## Section layout maintenance

`lib/sections.ts` and native `sections.scad` resolve the same bounded flat tree.
The SectionEditor edits that tree; the existing drawer and door modules are
re-resolved per opening using `layouts_modules.scad`. The root emits the carcass
once and owns shared split panels. Keep UI/native geometry tests aligned.

`catalog/section-layout-recipes.json` preserves the photo starter through engine
imports. Its values also appear in `examples/photo-section-cabinet.cabinet.json`
and the native `public/engine/v5/examples/photo_section_cabinet.scad`. Update all
three deliberately. Include new SCAD dependencies in the embedded source bundle
and worker manifest. `node tests/sections.cjs` is part of `test:release` and needs
native OpenSCAD, like the existing stackable tests.

`npm run test:sections:wasm` runs the production render/export workers in a Node
harness: photo assembly, flat parts, BOM, cut, hinge pockets and engraving. It
checks the full embedded source allowlist and shared SVG registration. This is
worker integration coverage, not a visual browser interaction test.
