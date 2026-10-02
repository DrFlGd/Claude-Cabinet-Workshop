# Build and hosting

Use Node 24 and pnpm 11.25.0. Install with `pnpm install --frozen-lockfile`.
Run `pnpm run dev:static` for local development or `pnpm run build:static` for a
static website in web-dist. Serve that directory over HTTP; do not open index.html
using file://. The bundled OpenSCAD WASM runtime needs no external installation.

`CABINET_BASE_PATH` sets the path the site is served from. The release build uses
`./` (relative, works from any folder); the GitHub Pages build for this repository
uses `/Claude-Cabinet-Workshop/`. The HTML base, scripts, workers, engine files and
engraving font all resolve under that path.

The original Sites build remains available through `pnpm dev` and `pnpm build`.
That build uses Vinext and a Cloudflare Worker; it is not the static Pages output.

## Continuous integration and releases

The Build and Pages workflow runs on every push to main and on pull requests:
type-check, the release test suite (including the engine fit and interference
suites and the embedded-source sync check), a portable release build and the
Pages build. On a push to main whose package version has no tag yet, it tags
`v<version>` and publishes a GitHub release containing
`claude-cabinet-workshop-web-v<version>.zip`, with the matching CHANGELOG section
as release notes. Existing tags and releases are never overwritten.

The Windows test build workflow runs on pushes to main that change `desktop/`, its
own workflow file or `VERSION`. After its packaged EXE passes the smoke test, it
attaches `Claude-Cabinet-Workshop-v<version>-Windows-x64.zip` to the release that
was tagged at the same commit (it waits for Build and Pages to publish it). To add
a Windows build to an existing release, run the workflow manually with that tag
(for example `v0.6.0`); it builds that tag's sources. An asset that is already
attached is never replaced.

Keep package.json, VERSION and the changelog heading aligned when releasing.

## Publish with GitHub Pages

The Pages deploy job runs only when manually started with deploy enabled. Pages
availability depends on the GitHub plan; a private repository does not by itself
guarantee a private Pages website. Check the intended audience first.

1. Open the repository Settings → Pages and select GitHub Actions as Source.
2. Open Actions → Build and Pages → Run workflow on main.
3. Enable Deploy the built site to GitHub Pages, then run the workflow.
4. Wait for build and deploy to succeed; use the deployment's returned URL.

For a different repository name or a custom-domain root, change the Pages
`CABINET_BASE_PATH` in the workflow to match the serving path.

No source ZIP, generated web-dist, node_modules or executable belongs in git.
For a local production check, run `pnpm run build:static`, then
`pnpm exec vite preview --config vite.static.config.ts` and open its HTTP URL.
Use [development notes](docs/DEVELOPMENT.md) for verification requirements.
