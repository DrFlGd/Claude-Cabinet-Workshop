# Build and hosting

Use Node 24 and pnpm 11.25.0. Install with `pnpm install --frozen-lockfile`.
Run `pnpm run dev:static` for local development or `pnpm run build:static` for a
static website in web-dist. Serve that directory over HTTP; do not open index.html
using file://. The bundled OpenSCAD WASM runtime needs no external installation.

For this GitHub repository build with CABINET_BASE_PATH=/Cabinet-Workshop/.
The HTML base, scripts, workers, engine and engraving font resolve under that path.
The original Sites build remains available through `pnpm build`.

The build workflow checks and builds every push to main. The Pages deploy job
runs only when manually started with deploy enabled. In repository Settings →
Pages choose GitHub Actions, then run Build and Pages with deploy enabled.
Pages availability depends on the GitHub plan; a private repository does not
by itself guarantee a private Pages website. Check the intended audience before
enabling deployment. No repository visibility change is made by this workflow.

No source ZIP, generated web-dist, node_modules or executable belongs in git.
Application release version: 0.4.0. See CHANGELOG.md for release policy and limits.
