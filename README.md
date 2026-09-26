# Cabinet Workshop 0.4.0

Web configurator for the supplied Modular Organization 5.3.0 package (engine v5,
MOI-4). Seven families: shop cart, utility, benchtop, stackable, kitchen,
standalone drawer and equipment stand. 109 starters include 48 application-owned
standard kitchen configurations. Source identity is in public/engine/BUNDLE_PROVENANCE.json.

## Configuration workflow

Choose a family and starter in the collapsible Setup rail. Engine presets replace
the full starting configuration; standard kitchen patches retain unrelated stock
and hardware choices. Materials and Machining lead the settings list. Category
and subgroup order follows the v5 schema, with separate hinges, slides, drilling,
fasteners, shared slot relief and equipment side-panel relief sections.

Search reaches relevant settings, including advanced controls. Advanced fields have
a gold accent and an Advanced badge. Dependent fields remain hidden until their
parent feature is enabled; hidden values are retained. Hover or focus the setting
label or information icon to read its help. Measured stock
supports decimals; imperial input is converted to millimeters internally.
Angles, equipment weights, counts and safety factors are not length-converted.
Computed defaults remain automatic until explicitly overridden.

Hardware profiles apply editable patches once. Equipment stands use the dedicated
equipment-hardware catalog. Reference-only entries do not apply machining settings;
manufacturer information is not independently certified by this application.

Save design downloads a portable JSON file. Local autosave and ten recent designs
are browser-local, not cloud backups. Existing v3 and Storage-era design files
are migrated; older starter identifiers become Custom while settings are retained.

## Visualization and accuracy

The quick schematic uses simplified solid envelopes and estimated dimensions.
It does not show actual joint profiles, screw guides, divider grooves, cleat bevels
or skeletonized-side cutouts. Exact OpenSCAD assembly and flat_3d render modes use
the original nested v5 source tree. Native part click guides are approximate and
are disabled for equipment stands and flat layouts. Fitted drawer and equipment
sizes can be calculated from engine reports.

Design Health evaluates the current configuration and is cleared after edits.
Browser manufacturing jobs force validation and interface keepout enforcement;
semantic CHECK errors block manufacturing downloads. Warnings remain visible.
A passing browser check is not the Python final-contour audit, a structural/load
rating or CAM verification. Equipment warnings about wall anchoring, extended
loads and generic slide drilling must be reviewed.

## Manufacturing and source exports

Export project generates a frozen snapshot for review before download. Changes
make the review stale. Supported output modes are taken from the module schema,
including divider-groove and equipment-slide operations. Packages contain SVGs,
BOM/dimension reports, Design Health and system-contract reports, logs, source,
and a printable assembly guide. Equipment diagrams show panel envelopes only;
cleat secondary bevel requirements remain in the BOM and machining notes.

Download project includes the complete v5 Python package and nested SCAD resources.
From the exported source root, install desktop OpenSCAD and Python 3.10+, then:

    python -m pip install ./v5
    python -m modular_organization audit --help
    python -m modular_organization manufacture --help

See v5/docs/INTEGRATION.md and v5/docs/MACHINING.md for the validated Python API,
request format and final CUT/POCKET contour audit. Browser SVGs are layouts, not
sheet nesting or machine toolpaths. Keep registration frames out of cut paths.

## Material-specific machining

Machining groups settings by carcass, drawer boxes, drawer bottoms and drawer
dividers. Each applicable group offers a slot-relief type and cutter diameter.
“inherit” uses the shared relief style; a diameter of zero uses the shared cutter.
Drawer bottoms default to no relief to preserve existing geometry. Overrides
follow the material receiving the cut, including divider capture in drawer bottoms.
Controls and clearances are shown only for their applicable joinery/features.
Equipment side-panel relief retains its dedicated controls.

Front settings appear under Doors and Drawers. Shared front construction settings
are shown in both applicable sections and edit the same underlying value.

## Development

Use Node >=22.13 and pnpm 11.25.0 with package.json and pnpm-lock.yaml:

    pnpm install --frozen-lockfile
    pnpm dev
    pnpm build

This checkout uses Vinext/Vite and a Cloudflare Worker through Sites. Keep its
existing hosting association and dependency lockfile. Browser rendering includes
the pinned OpenSCAD WASM runtime under public/openscad. No desktop OpenSCAD or
Python installation is needed for browser rendering. Windows packaging is a
separate deliverable and is not changed by this web update.

## Maintaining the engine adapter

    python scripts/import-modular-engine.py /path/to/modular_organization

The importer retains the package tree, imports typed native presets and hardware,
merges the application kitchen catalog, and generates the worker file allowlist.
Two native drawer capabilities are exposed by the adapter: the existing shared
slot-relief assignment and flat_3d output supported by the shared layout code.
No SCAD expression is evaluated in JavaScript.

Run tests/v5-integration.cjs for current migration, catalog, units, visibility and
source-bundle checks. Recovery and diagram depth checks are also current. Older
version-named catalog tests contain historical filename/count expectations.
Verification used the actual browser WASM workers for seven default BOMs,
48 kitchen presets, all 14 equipment presets, exact drawer/stand assembly and
flat renders, and representative machining outputs. Browser UI QA was unavailable
because the supervised preview service could not start in this session.

## GitHub and static hosting

See [HOSTING.md](HOSTING.md) for local/static builds and GitHub Pages.
See [CHANGELOG.md](CHANGELOG.md) for application releases, separate from engine versions.
