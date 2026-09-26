# Documentation guide

## Current application

- [README](../README.md): features, usage, limits and quick start.
- [Hosting](../HOSTING.md): static builds, GitHub Pages and the retained Sites build.
- [Development](DEVELOPMENT.md): source layout, checks and engine maintenance.
- [Changelog](../CHANGELOG.md): consolidated application and engine history.
- [VERSION](../VERSION): application release number; the engine version is separate.

## Current bundled engine

The application bundles Modular Organization 5.3.0 with the later cabinet/relief
patches described in the changelog. These documents describe the Python/native
engine; not every engine capability has a dedicated web control.

- [Engine README](../public/engine/v5/README.md): installation, CLI and package map.
- [Integration](../public/engine/v5/docs/INTEGRATION.md): Python API and request handling.
- [Machining](../public/engine/v5/docs/MACHINING.md): operation semantics and relief overrides.
- [Parameter conventions](../public/engine/v5/docs/PARAMETER_CONVENTIONS.md): native schema rules and web presentation differences.
- [Migration](../public/engine/v5/docs/MIGRATION.md): compatibility and upgrade guidance.

## Historical evidence

- [Package review](../public/engine/v5/docs/REVIEW.md) and
  [validation report](../public/engine/v5/docs/VALIDATION.md) record the original
  package review, not a fresh test of every later application change.
- [Kitchen patch note](../public/engine/v5/docs/KITCHEN_BAY_FIX.md) records the
  independent-bay correction.
- Older versioned READMEs, release notes, migration guides and validation reports
  directly under public/engine are retained for legacy compatibility and evidence.
  Their versions, counts and commands must not be treated as current instructions.
  Start with the consolidated changelog when researching the history.

License/attribution files remain beside their bundled dependencies. Historical
reports are retained in place to preserve existing source references.
