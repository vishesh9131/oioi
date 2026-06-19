// Build script: bundles main + preload (Node/CJS) and renderer (browser/IIFE)
// with esbuild, then copies static assets into dist/.
import * as esbuild from "esbuild";
import { cpSync, mkdirSync, rmSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const watch = process.argv.includes("--watch");

rmSync(resolve(root, "dist"), { recursive: true, force: true });

const mainCtx = await esbuild.context({
  entryPoints: [
    resolve(root, "src/main/main.ts"),
    resolve(root, "src/main/preload.ts"),
  ],
  bundle: true,
  platform: "node",
  format: "cjs",
  target: "node20",
  outdir: resolve(root, "dist/main"),
  external: ["electron"],
  sourcemap: true,
  logLevel: "info",
});

const rendererCtx = await esbuild.context({
  entryPoints: [
    resolve(root, "src/renderer/renderer.ts"),
    resolve(root, "src/renderer/settings.ts"),
    resolve(root, "src/renderer/onboarding.ts"),
  ],
  bundle: true,
  platform: "browser",
  format: "iife",
  target: "chrome120",
  outdir: resolve(root, "dist/renderer"),
  sourcemap: true,
  logLevel: "info",
});

function copyStatic() {
  mkdirSync(resolve(root, "dist/renderer"), { recursive: true });
  for (const f of ["index.html", "styles.css", "settings.html", "settings.css", "splash.html", "splash.css", "onboarding.html", "onboarding.css"]) {
    cpSync(resolve(root, "src/renderer", f), resolve(root, "dist/renderer", f));
  }
  cpSync(resolve(root, "assets"), resolve(root, "dist/assets"), { recursive: true });
}

if (watch) {
  await mainCtx.watch();
  await rendererCtx.watch();
  copyStatic();
  console.log("watching for changes…");
} else {
  await mainCtx.rebuild();
  await rendererCtx.rebuild();
  copyStatic();
  await mainCtx.dispose();
  await rendererCtx.dispose();
  console.log("build complete -> dist/");
}
