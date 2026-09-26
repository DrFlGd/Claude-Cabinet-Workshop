# Release verification — 5.3.0

Verified with Python 3.12 and OpenSCAD 2021.01.

| Check | Result |
|---|---|
| Full CUT/POCKET audit matrix | 82 configurations: 64 PASS, 18 WARN, 0 ERROR |
| Native design presets | 54, across seven frontends |
| Explicit joint modes | butt, screw, dado, tab_slot for each frontend (28 cases) |
| Regression suite | 23 tests passed, including parameter layout and compatibility checks |
| Fractional stock + screw metadata | All seven frontends, 18.35 mm, no runtime warnings |
| Composition examples | Workbench PASS, drawer organizer PASS, equipment tower WARN; zero errors |
| Hardware resolver | 97 profiles valid: 84 machining, 13 metadata-only |
| Wheel build and isolated target install | Successful; installed stackable dado metadata PASS |
| Flat preview | Standalone drawer flat_3d STL, no runtime warnings |
| Complete manufacturing export | Equipment example: 30 files, 0 export errors, 2 planning sheets; WARN status retained |

`validation_matrix.json` stores individual audit outcomes. `tests/run_matrix.py` reproduces them; the regression suite separately checks request validation, decimal normalization, renderer failures/timeouts, nesting boundaries, project safety/immutability and examples. Matrix results reflect the tested defaults and presets, not all possible parameter combinations.

WARN records are preserved rather than suppressed. Equipment warnings include application-specific load/installation metadata and verification requirements. See each generated report for the actual configuration's warnings.

The wheel was installed into a separate target directory and imported from that directory to verify packaged SCAD/config resources. Public website deployment, browser behavior, host concurrency/load tests and other Python/OpenSCAD versions were not exercised.

## Parameter organization verification

The 82-case audit and 23-test suite were rerun after reorganization. Default BOMs, dimensions, interfaces, diagnostic checks and runtime warnings were compared before/after for every frontend and were identical. Contract signatures confirm all existing user parameter IDs, defaults, default expressions, ranges and enum values are preserved. Only the accidentally public internal standalone drawer resolver flag was removed from the public schema.

The complete manufacturing export and flat STL checks above were performed during the 5.2 package review. The 5.3 changes were reverified through the full manufacturing audit, metadata comparison and regression suite; the native OpenSCAD GUI itself was not interactively exercised.
