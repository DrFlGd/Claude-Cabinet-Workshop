// Refresh the browser's embedded engine snapshot (lib/engine-sources.json) from
// the bundled native package under public/engine. The browser renders and the
// source export read only the embedded copies, so every SCAD/doc edit must be
// followed by this sync. `--check` exits non-zero when the snapshot is stale.
import fs from "node:fs";
const root = new URL("../", import.meta.url);
const target = new URL("lib/engine-sources.json", root);
const bundle = JSON.parse(fs.readFileSync(target, "utf8"));
const stale = [];
for (const name of Object.keys(bundle)) {
  const file = new URL("public/engine/" + name, root);
  if (!fs.existsSync(file)) continue; // application-owned entries (e.g. section recipes)
  const text = fs.readFileSync(file, "utf8");
  if (bundle[name] !== text) {
    stale.push(name);
    bundle[name] = text;
  }
}
if (process.argv.includes("--check")) {
  if (stale.length) {
    console.error("Embedded engine sources are stale:\n  " + stale.join("\n  ") + "\nRun: node scripts/sync-engine-sources.mjs");
    process.exit(1);
  }
  console.log("Embedded engine sources match public/engine.");
} else {
  fs.writeFileSync(target, JSON.stringify(bundle));
  console.log(stale.length ? "Updated " + stale.length + " embedded file(s):\n  " + stale.join("\n  ") : "Already in sync.");
}
