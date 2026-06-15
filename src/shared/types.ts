// Serializable clipboard item shared across the main <-> renderer IPC boundary.
// (Native NSImage / Data become data-URL strings so they survive structured clone.)

export type ClipKind = "text" | "image" | "files";

export interface ClipboardItem {
  /** Stable UUID for this entry. */
  id: string;
  /** Capture time, epoch milliseconds. */
  timestamp: number;
  kind: ClipKind;
  /** Present when kind === "text". */
  text?: string;
  /** PNG data URL, present when kind === "image". */
  imageDataUrl?: string;
  /** Absolute file paths, present when kind === "files". */
  files?: string[];
  /** System file icon as a data URL (files only); renderer draws its own icons otherwise. */
  iconDataUrl?: string;
  /** Human-readable preview, also the field the search box matches against (parity with Swift). */
  previewString: string;
  /** Content fingerprint used for de-duplication / equality. */
  signature: string;
}

/** User-configurable settings, persisted to userData/settings.json. */
export interface Settings {
  /** Master on/off for clipboard capture ("Start/Stop oioi"). */
  monitoring: boolean;
  /** Global toggle shortcut as an Electron accelerator, e.g. "Alt+V". */
  shortcut: string;
  /** Open oioi automatically at macOS login. */
  startAtLogin: boolean;
  /** Maximum number of items kept in history. */
  maxHistory: number;
  /** Tint opacity over the blurred backdrop (0–0.7); higher = milkier/less transparent. */
  glassTint: number;
  /** Backdrop blur radius in px (0–100). */
  glassBlur: number;
  /** Panel corner radius in px (0–60). */
  glassRadius: number;
  /** Set true once the user has completed first-run setup. */
  configured: boolean;
}

/** IPC channel names, kept in one place so main and preload agree. */
export const IPC = {
  getHistory: "history:get",
  historyUpdated: "history:updated",
  copyItem: "history:copy",
  clearHistory: "history:clear",
  closePanel: "panel:close",
  panelShown: "panel:shown",
  backdrop: "panel:backdrop",
  getSettings: "settings:get",
  saveSettings: "settings:save",
  settingsDone: "settings:done",
  getAccessibility: "perm:accessibility:get",
  openAccessibility: "perm:accessibility:open",
} as const;

/** Result of a save that may have failed to register the global shortcut. */
export interface SaveSettingsResult {
  settings: Settings;
  shortcutOk: boolean;
}

/** The API exposed to renderers via contextBridge (see preload.ts). */
export interface OioiApi {
  getHistory(): Promise<ClipboardItem[]>;
  copyItem(id: string): Promise<boolean>;
  clearHistory(): Promise<void>;
  closePanel(): void;
  getSettings(): Promise<Settings>;
  saveSettings(patch: Partial<Settings>): Promise<SaveSettingsResult>;
  settingsDone(): Promise<void>;
  onBackdrop(cb: (dataUrl: string) => void): () => void;
  getAccessibility(): Promise<boolean>;
  openAccessibility(): Promise<void>;
  onHistoryUpdated(cb: (items: ClipboardItem[]) => void): () => void;
  onPanelShown(cb: () => void): () => void;
}

declare global {
  interface Window {
    oioi: OioiApi;
  }
}
