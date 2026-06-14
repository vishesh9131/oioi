// Settings window: live-applies each change and gates "Done" until oioi is on
// and a shortcut is set (per the requirement to close once both are configured).
import type { Settings } from "../shared/types";

const $ = <T extends HTMLElement>(sel: string): T => document.querySelector(sel) as T;

const monitoringEl = $<HTMLInputElement>("#monitoring");
const startAtLoginEl = $<HTMLInputElement>("#startAtLogin");
const maxHistoryEl = $<HTMLInputElement>("#maxHistory");
const maxHistoryVal = $("#maxHistoryVal");
const shortcutBtn = $<HTMLButtonElement>("#shortcut");
const shortcutHint = $("#shortcut-hint");
const clearBtn = $<HTMLButtonElement>("#clear");
const doneBtn = $<HTMLButtonElement>("#done");
const footerHint = $("#footer-hint");

const DEFAULT_SHORTCUT_HINT = "Opens the clipboard panel anywhere";

let current: Settings;
let recording = false;

const SYMBOLS: Record<string, string> = {
  Cmd: "⌘", Command: "⌘", Ctrl: "⌃", Control: "⌃", Alt: "⌥", Option: "⌥",
  Shift: "⇧", Return: "⏎", Enter: "⏎", Space: "␣", Up: "↑", Down: "↓",
  Left: "←", Right: "→",
};

function prettyShortcut(accel: string): string {
  if (!accel) return "None";
  return accel.split("+").map((t) => SYMBOLS[t] ?? t).join("");
}

function refresh(): void {
  monitoringEl.checked = current.monitoring;
  startAtLoginEl.checked = current.startAtLogin;
  maxHistoryEl.value = String(current.maxHistory);
  maxHistoryVal.textContent = String(current.maxHistory);
  if (!recording) shortcutBtn.textContent = prettyShortcut(current.shortcut);

  const ready = current.monitoring && Boolean(current.shortcut);
  doneBtn.disabled = !ready;
  footerHint.textContent = ready ? "" : "Turn oioi on and set a shortcut to finish.";
}

async function save(patch: Partial<Settings>): Promise<void> {
  const res = await window.oioi.saveSettings(patch);
  current = res.settings;
  if (patch.shortcut !== undefined) {
    if (res.shortcutOk) {
      shortcutHint.textContent = DEFAULT_SHORTCUT_HINT;
      shortcutHint.classList.remove("warn");
    } else {
      shortcutHint.textContent = "That shortcut is unavailable — pick another.";
      shortcutHint.classList.add("warn");
    }
  }
  refresh();
}

// --- shortcut recorder ------------------------------------------------------
function mainKey(e: KeyboardEvent): string | null {
  const c = e.code;
  if (c.startsWith("Key")) return c.slice(3); // KeyV -> V
  if (c.startsWith("Digit")) return c.slice(5); // Digit1 -> 1
  if (/^F\d{1,2}$/.test(c)) return c; // F1..F12
  const map: Record<string, string> = {
    Space: "Space", Enter: "Return", Tab: "Tab", Backslash: "\\",
    BracketLeft: "[", BracketRight: "]", Semicolon: ";", Quote: "'",
    Comma: ",", Period: ".", Slash: "/", Minus: "-", Equal: "=",
    Backquote: "`", ArrowUp: "Up", ArrowDown: "Down", ArrowLeft: "Left",
    ArrowRight: "Right",
  };
  return map[c] ?? null; // lone modifier keys return null
}

function startRecording(): void {
  recording = true;
  shortcutBtn.classList.add("recording");
  shortcutBtn.textContent = "Press keys…";
}

function stopRecording(): void {
  recording = false;
  shortcutBtn.classList.remove("recording");
  refresh();
}

window.addEventListener("keydown", (e) => {
  if (!recording) return;
  e.preventDefault();

  if (e.key === "Escape") {
    stopRecording();
    return;
  }

  const mods: string[] = [];
  if (e.metaKey) mods.push("Cmd");
  if (e.ctrlKey) mods.push("Ctrl");
  if (e.altKey) mods.push("Alt");
  if (e.shiftKey) mods.push("Shift");

  const key = mainKey(e);
  if (!key) return; // still waiting for the non-modifier key

  if (mods.length === 0) {
    shortcutHint.textContent = "Include ⌘, ⌥, ⌃ or ⇧.";
    shortcutHint.classList.add("warn");
    return;
  }

  recording = false;
  shortcutBtn.classList.remove("recording");
  void save({ shortcut: [...mods, key].join("+") });
});

// --- wiring -----------------------------------------------------------------
monitoringEl.addEventListener("change", () => save({ monitoring: monitoringEl.checked }));
startAtLoginEl.addEventListener("change", () => save({ startAtLogin: startAtLoginEl.checked }));
maxHistoryEl.addEventListener("input", () => {
  maxHistoryVal.textContent = maxHistoryEl.value;
});
maxHistoryEl.addEventListener("change", () => save({ maxHistory: Number(maxHistoryEl.value) }));
clearBtn.addEventListener("click", () => void window.oioi.clearHistory());
shortcutBtn.addEventListener("click", startRecording);
doneBtn.addEventListener("click", () => void window.oioi.settingsDone());

async function init(): Promise<void> {
  current = await window.oioi.getSettings();
  refresh();
}
void init();
