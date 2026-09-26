# Migration: V31 → V32

V32 changes the hardware catalog from a persistent resolver to recipe-style
one-time patches.

Removed from the public geometry contract:

```text
drawer_slide_profile
hinge_profile
```

The generated `modular_storage_hardware_v1.scad` lookup layer is no longer
needed. Hardware is authored in `modular_storage_hardware_v2.json` and its
`apply` values become ordinary cabinet/drawer configuration.

A V31 saved design that used a profile ID should be migrated by locating that
ID in the V2 catalog and applying its `apply` object once. Save the resulting
canonical values afterward.

New canonical settings include explicit slide member hole arrays and separate
cabinet/drawer hole diameters, while the legacy first-hole/spacing/count mode
remains the default for backward compatibility.

V31 custom/default designs require no migration: all six V31 default assemblies
and CUT layouts are unchanged in V32.
