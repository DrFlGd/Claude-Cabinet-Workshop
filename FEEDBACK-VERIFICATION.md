# Previous Feedback Verification

Baseline reviewed: `Cabinet-Workshop-v5-Fixed-Source.zip`

Verification performed against both the TypeScript/schema source and the prebuilt static UI.

## Status

| Request | Status | Finding |
|---|---|---|
| Visually distinguish advanced options after enabling them | **Not implemented** | Advanced fields are revealed, but render with the same field classes/styles as standard fields. |
| Part/material-specific slot relief and cutter diameter | **Not implemented** | The current UI still exposes a shared slot-relief setting and a single CNC cutter diameter. Frame and drawer clearances are separated, but relief type/diameter are not material-specific. |
| Show only clearance controls relevant to selected joinery | **Incomplete** | Some controls use visibility/inactive logic, but the available clearance configuration is not fully driven by the currently selected joinery as requested. |
| Move Fronts controls into Doors/Drawers sections | **Not implemented** | A standalone `Fronts` section remains in the section order and rendered UI. |

## UI observations

### Advanced settings
The Structure section reports advanced settings and the “Show advanced” control reveals them, but the resulting fields retain the same `.field` / `.toggle-field` presentation as normal settings. There is no advanced-field marker, badge, border, background, or other visual distinction.

### Machining / relief
The rendered Machining section contains:

- a single **CNC cutter diameter**;
- a **Shared Slot Relief** subsection;
- one **Shared slot relief** selector with `None`, `Dogbone`, and `T-bone` behavior in the schema;
- separate Frame Joint and Drawer Joint clearance fields.

That does not satisfy the requested per-material/per-part relief type and cutter-diameter configuration.

### Fronts
The rendered application still includes a top-level **Fronts** section with layout/reveal settings including front mount style, inset back clearance, overlay width style, front edge reveal, bottom-lip coverage, door gap, and drawer gap.

## Recommended next implementation

Treat these as three outstanding feature fixes on top of the v5 Fixed baseline:

1. Add an explicit visual treatment for advanced fields when advanced mode is enabled.
2. Replace/shared relief configuration with material/part-specific machining profiles (at minimum carcass, drawer box, door/front where applicable), each carrying relief type and cutter diameter; route each part’s geometry through the matching profile and condition clearance controls on active joinery.
3. Reassign front-related schema fields to the appropriate Doors or Drawers sections and remove the standalone Fronts section once no fields remain there.
