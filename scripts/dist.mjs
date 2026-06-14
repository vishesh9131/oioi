// Packaging pipeline (free / no Apple Developer account):
//   1. bundle JS/CSS/assets (esbuild)
//   2. package a universal .app with electron-builder (unsigned)
//   3. ad-hoc sign the .app  -> required so it runs on Apple Silicon
//   4. wrap it in a drag-to-Applications .dmg with hdiutil
//
// The result is NOT notarized (that needs the $99 program), so first launch on
// another Mac shows Gatekeeper's "unidentified developer" prompt — see INSTALL.md.
import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, rmSync, symlinkSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const run = (cmd, args, extraEnv) =>
  execFileSync(cmd, args, {
    stdio: "inherit",
    cwd: root,
    env: { ...process.env, ...extraEnv },
  });

const pkg = JSON.parse(readFileSync(resolve(root, "package.json"), "utf8"));
const APP = "oioi";

console.log("• bundling renderer/main…");
run(process.execPath, ["scripts/build.mjs"]);

console.log("• packaging universal .app (electron-builder)…");
run("npx", ["electron-builder", "--mac", "dir", "--universal"], {
  CSC_IDENTITY_AUTO_DISCOVERY: "false",
});

const candidates = [
  resolve(root, "release/mac-universal", `${APP}.app`),
  resolve(root, "release/mac", `${APP}.app`),
  resolve(root, "release/mac-arm64", `${APP}.app`),
];
const appPath = candidates.find(existsSync);
if (!appPath) {
  throw new Error(`Packaged app not found. Looked in:\n  ${candidates.join("\n  ")}`);
}
console.log("  -> " + appPath);

console.log("• ad-hoc signing…");
run("codesign", ["--deep", "--force", "--sign", "-", appPath]);
run("codesign", ["--verify", "--deep", "--strict", "--verbose=2", appPath]);

console.log("• building .dmg…");
const stage = resolve(root, "release/.dmg-stage");
rmSync(stage, { recursive: true, force: true });
mkdirSync(stage, { recursive: true });
// ditto preserves the bundle structure, symlinks, and ad-hoc signature.
run("ditto", [appPath, resolve(stage, `${APP}.app`)]);
symlinkSync("/Applications", resolve(stage, "Applications"));

const dmgPath = resolve(root, "release", `${APP}-${pkg.version}-universal.dmg`);
rmSync(dmgPath, { force: true });
run("hdiutil", [
  "create",
  "-volname",
  APP,
  "-srcfolder",
  stage,
  "-ov",
  "-format",
  "UDZO",
  dmgPath,
]);
rmSync(stage, { recursive: true, force: true });

console.log("\n✓ Done");
console.log("  app: " + appPath);
console.log("  dmg: " + dmgPath);
