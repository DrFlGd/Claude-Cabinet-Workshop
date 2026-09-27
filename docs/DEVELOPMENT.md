# Development and verification

Use Node 24 and pnpm 11.25.0. See [HOSTING.md](../HOSTING.md) for installation,
local serving and deployment. Application versioning is defined in the
[changelog](../CHANGELOG.md); engine versions are independent.

## Source map

| Area | Location |
|---|---|
| Configuration workspace | app/page.tsx |
| Presentation, help and dependencies | lib/settings.ts, app/SettingHelp.tsx |
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

The release tests require native OpenSCAD on PATH for stackable geometry checks.
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

Keep native resources, generated schema and lib/engine-sources.json synchronized.
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
