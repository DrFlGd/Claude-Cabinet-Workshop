# Development Notes — V32

Hardware must follow the same architectural rule as recipes:

```text
profile → one-time patch → canonical config → geometry
```

Do not add profile-ID conditionals to core geometry. If a hardware property is
needed by geometry, first promote it to an ordinary canonical frontend setting,
then let hardware entries patch that setting.

Partial manufacturer profiles must fail safe. Prefer disabling an unsupported
machining operation to carrying forward stale values or guessing a hole
pattern.

The hardware generator validates patch keys against each target frontend. This
is intentional: adding a catalog field that geometry cannot consume should not
silently succeed.

## Stackable bottom tab placement fix

Stackable tab/slot cabinets now treat the cabinet-bottom joint as a distinct
joinery location. The default `bottom_tab_placement = "stack_safe"` keeps the
first and last bottom tabs inside the full-height front/rear stacking pads so
their side-panel slots do not straddle the rounded lower stacking shoulders.
All other carcass tab patterns retain the existing distribution logic.

For web/configurator use, `bottom_tab_placement = "custom"` accepts explicit
`bottom_tab_custom_centers` in millimeters from the front cabinet edge. The
same resolved centers drive both the bottom-panel tabs and the matching side
slots, so cut and assembly geometry stay synchronized.
