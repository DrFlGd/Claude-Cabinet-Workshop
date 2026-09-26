# Kitchen independent-bay and hardware grouping patch

Based on v5.3.0. Kitchen exposed bay count but hid a one-element width-weight
array and explicitly disabled partitions. Increasing bay count raised
ERROR|MIXED_BAY_WEIGHTS_SHORT, which the browser correctly rejected.

Kitchen now exposes width weights, front gap, and a partition toggle under
Structure / Layout. Partitions default on; one divider separates each pair of
bays. Four default type/weight entries allow increasing bay count. Native open
cabinet presets retain open bays. The legacy single-bay layout is unaffected.

Wood rail and drawer runner thickness controls are in Hardware / Wood Runners
across all six applicable frontends. Automatic thickness expressions remain.
The schema no longer marks text choices, toggles, and relative weights as mm.

The kitchen parameter-contract hash was intentionally updated for these new
public controls and defaults. Geometry checks cover 2/3/4 bays and butt, dado,
and tab-slot joinery. The website also extends incomplete kitchen bay arrays
from old saved designs while preserving their existing values.
