// Persistent user settings, stored as JSON in the app's userData directory.
import { app } from "electron";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import type { Settings } from "../shared/types";

export const DEFAULT_SETTINGS: Settings = {
  monitoring: true,
  shortcut: "Alt+V",
  startAtLogin: false,
  maxHistory: 50,
  panelStyle: "soft",
  glassTint: 0.12,
  glassBlur: 40,
  glassRadius: 28,
  configured: false,
};

let cache: Settings | null = null;

function settingsFile(): string {
  return join(app.getPath("userData"), "settings.json");
}

export function getSettings(): Settings {
  if (cache) return cache;
  let loaded: Settings;
  try {
    const raw = JSON.parse(readFileSync(settingsFile(), "utf8"));
    loaded = { ...DEFAULT_SETTINGS, ...raw };
  } catch {
    loaded = { ...DEFAULT_SETTINGS };
  }
  cache = loaded;
  return loaded;
}

export function saveSettings(patch: Partial<Settings>): Settings {
  const next: Settings = { ...getSettings(), ...patch };
  // Clamp to sane bounds.
  next.maxHistory = Math.max(1, Math.min(500, Math.round(next.maxHistory)));
  next.glassTint = Math.max(0, Math.min(0.7, next.glassTint));
  next.glassBlur = Math.max(0, Math.min(100, Math.round(next.glassBlur)));
  next.glassRadius = Math.max(0, Math.min(60, Math.round(next.glassRadius)));
  next.panelStyle = next.panelStyle === "glass" ? "glass" : "soft";
  cache = next;
  try {
    mkdirSync(app.getPath("userData"), { recursive: true });
    writeFileSync(settingsFile(), JSON.stringify(next, null, 2), "utf8");
  } catch (err) {
    console.error("Failed to persist settings:", err);
  }
  return next;
}
