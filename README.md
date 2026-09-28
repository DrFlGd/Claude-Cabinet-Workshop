# Cabinet Workshop

A web configurator for shop carts, utility cabinets, benchtop cabinets, stackable
cabinets, kitchen cabinets, standalone drawers and equipment stands. The app
includes 110 starters, including 48 standard kitchen configurations.

Application version: **0.5.2**. Bundled engine: **Modular Organization 5.3.0**
(engine family v5, interface MOI-4), with the patches recorded in the
[changelog](CHANGELOG.md). [Documentation guide](docs/README.md).

## Run locally

Use Node 24 and pnpm 11.25.0:

```sh
pnpm install --frozen-lockfile
pnpm run dev:static
```

Open the HTTP address printed by Vite. Browser rendering uses bundled OpenSCAD
WebAssembly; it does not require Python or desktop OpenSCAD. See
[HOSTING.md](HOSTING.md) for production/static builds and GitHub Pages, and
[development notes](docs/DEVELOPMENT.md) for tests and the original Sites build.

## Configure a design

Choose a family and starter in Setup, then edit the relevant settings. Native
presets replace the starting configuration; standard kitchen patches retain
unrelated stock/hardware choices. Hardware presets apply editable values once.
Reference-only hardware entries do not supply machining settings.

Materials and Machining lead the settings list. Front controls appear under Doors
and Drawers; shared front settings edit the same value in both sections. Advanced
fields have a badge and gold accent. Kerf compensation/width are advanced controls.
Dependent controls appear only when relevant, preserving their saved values.
Search includes relevant advanced fields. Hover the setting label or use the
focusable information button for help, including the face-frame mid-rail modes.

Measured stock accepts decimals. Metric/inch presentation retains full-precision
millimeter values; angles, weights and counts are not converted as lengths.
Expression-backed defaults remain automatic until overridden.

Save design downloads portable JSON. Autosave and ten recent designs are local
to the browser, not cloud backups. Earlier design formats are migrated where
supported; outdated starter identifiers become Custom while values are retained.

## Preview and machining

The schematic is a simplified view, not exact joinery geometry. Use OpenSCAD
assembly or flat_3d rendering for exact geometry. Native part guides remain
approximate and are disabled for equipment stands and flat layouts.
Kitchen **Sections** supports nested top/bottom and left/right splits with independent
drawers, doors and shelves. The older Mixed bays mode retains full-height columns.
See the [section layout guide and photo example](docs/SECTION_LAYOUTS.md).
For stackable open modules, each added shelf creates another open section.

Machining groups applicable controls by carcass, drawer box, drawer bottom and
drawer divider. Each supports its own relief style/cutter where applicable.
Inherit uses the shared style; a zero diameter uses the shared cutter. Drawer
bottom relief defaults to None. Equipment side-panel relief is separate.
See [machining semantics](public/engine/v5/docs/MACHINING.md).

Design Health reflects the current configuration. Export project creates a frozen
review of operation SVGs, BOM/dimension reports, warnings, logs, configured source
and a printable assembly guide; editing makes the review stale. Semantic CHECK
errors block manufacturing downloads. Browser layouts are not CNC toolpaths or
the Python final-contour audit, and geometric checks are not load certification.

The source export includes the nested v5 Python package. Follow the
[engine README](public/engine/v5/README.md) and
[integration guide](public/engine/v5/docs/INTEGRATION.md) for native inspection,
preview and manufacturing. Preserve registration between machining layers and
review operation depths, faces and cleat bevel notes.

## Releases and evidence

[CHANGELOG.md](CHANGELOG.md) contains the consolidated change history, source
references and validation limits. [HOSTING.md](HOSTING.md) explains manual Pages
publication. Windows packaging is a separate deliverable; the repository's web
release does not include a newly tested Windows executable.
