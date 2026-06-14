// Port of oioi/App + oioi/UI/MenuBarController.swift
// Menu-bar (tray) clipboard manager: a frameless, vibrant popover window toggled
// from the tray icon or the global ⌥V shortcut.
import {
  app,
  BrowserWindow,
  globalShortcut,
  ipcMain,
  Menu,
  nativeImage,
  screen,
  shell,
  systemPreferences,
  Tray,
} from "electron";
import { join } from "node:path";
import { historyManager } from "./historyManager";
import { clipboardWatcher } from "./clipboardWatcher";
import { getSettings, saveSettings } from "./settingsStore";
import { IPC, type Settings, type SaveSettingsResult } from "../shared/types";

const WINDOW_WIDTH = 400;
const WINDOW_HEIGHT = 500;

let tray: Tray | null = null;
let panel: BrowserWindow | null = null;
let settingsWin: BrowserWindow | null = null;

app.setName("oioi");
// Single-instance: a second launch just focuses the existing one.
if (!app.requestSingleInstanceLock()) {
  app.quit();
}

function createPanel(): BrowserWindow {
  const win = new BrowserWindow({
    width: WINDOW_WIDTH,
    height: WINDOW_HEIGHT,
    show: false,
    frame: false,
    resizable: false,
    movable: true,
    transparent: true,
    hasShadow: true,
    // Real macOS liquid-glass: native vibrancy blurs what's behind. It can't be
    // clipped to a custom radius, so macOS rounds the window (generous on Tahoe).
    vibrancy: "under-window",
    visualEffectState: "active",
    roundedCorners: true,
    skipTaskbar: true,
    fullscreenable: false,
    backgroundColor: "#00000000",
    webPreferences: {
      preload: join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  win.loadFile(join(__dirname, "../renderer/index.html"));

  // Transient behaviour: dismiss when focus leaves (parent of NSPopover.transient).
  win.on("blur", () => {
    if (!win.webContents.isDevToolsOpened()) win.hide();
  });

  return win;
}

function showPanel(position: (win: BrowserWindow) => void): void {
  if (!panel) panel = createPanel();
  position(panel);
  panel.show();
  panel.focus();
  panel.webContents.send(IPC.panelShown);
}

function togglePanel(position: (win: BrowserWindow) => void): void {
  if (panel && panel.isVisible()) {
    panel.hide();
  } else {
    showPanel(position);
  }
}

// --- positioning -----------------------------------------------------------

function positionAtTray(win: BrowserWindow): void {
  if (!tray) return positionAtCursor(win);
  const bounds = tray.getBounds();
  const area = screen.getDisplayNearestPoint({ x: bounds.x, y: bounds.y }).workArea;
  const [w] = win.getSize();
  let x = Math.round(bounds.x + bounds.width / 2 - w / 2);
  const y = Math.round(bounds.y + bounds.height + 4);
  x = Math.max(area.x + 8, Math.min(x, area.x + area.width - w - 8));
  win.setPosition(x, y, false);
}

// Mirrors positionPanelOptimally(): open away from screen edges by quadrant.
function positionAtCursor(win: BrowserWindow): void {
  const pt = screen.getCursorScreenPoint();
  const area = screen.getDisplayNearestPoint(pt).workArea;
  const [w, h] = win.getSize();

  const inRightHalf = pt.x > area.x + area.width / 2;
  const inTopHalf = pt.y < area.y + area.height / 2;

  let x = inRightHalf ? pt.x - w - 10 : pt.x + 10;
  let y = inTopHalf ? pt.y + 10 : pt.y - h - 10;

  x = Math.max(area.x + 10, Math.min(x, area.x + area.width - w - 10));
  y = Math.max(area.y + 10, Math.min(y, area.y + area.height - h - 10));

  win.setPosition(Math.round(x), Math.round(y), false);
}

// --- tray -------------------------------------------------------------------

function createTray(): void {
  const icon = nativeImage.createFromPath(join(__dirname, "../assets/tray.png"));
  tray = new Tray(icon.isEmpty() ? nativeImage.createEmpty() : icon);
  tray.setToolTip("oioi");

  // Left click toggles the panel; right click opens the menu.
  tray.on("click", () => togglePanel(positionAtTray));
  tray.on("right-click", () => tray?.popUpContextMenu(buildTrayMenu()));
}

function buildTrayMenu(): Menu {
  const running = getSettings().monitoring;
  return Menu.buildFromTemplate([
    { label: "Open oioi", click: () => showPanel(positionAtTray) },
    {
      type: "checkbox",
      label: "oioi is running",
      checked: running,
      click: () => applySettings(saveSettings({ monitoring: !running })),
    },
    { type: "separator" },
    { label: "Settings…", click: showSettings },
    { label: "Clear History", click: () => historyManager.clear() },
    { type: "separator" },
    { label: "Quit oioi", role: "quit" },
  ]);
}

// --- splash -----------------------------------------------------------------

function createSplash(): BrowserWindow {
  const splash = new BrowserWindow({
    width: 340,
    height: 360,
    frame: false,
    transparent: true,
    resizable: false,
    movable: false,
    alwaysOnTop: true,
    center: true,
    skipTaskbar: true,
    fullscreenable: false,
    hasShadow: true,
    vibrancy: "under-window",
    visualEffectState: "active",
    roundedCorners: true,
  });
  splash.loadFile(join(__dirname, "../renderer/splash.html"));
  return splash;
}

// --- settings window --------------------------------------------------------

function showSettings(): void {
  if (settingsWin && !settingsWin.isDestroyed()) {
    settingsWin.show();
    settingsWin.focus();
    return;
  }
  app.dock?.show(); // make the settings window reachable/focusable
  settingsWin = new BrowserWindow({
    width: 460,
    height: 600,
    resizable: false,
    fullscreenable: false,
    minimizable: false,
    title: "oioi Settings",
    titleBarStyle: "hiddenInset",
    webPreferences: {
      preload: join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });
  settingsWin.loadFile(join(__dirname, "../renderer/settings.html"));
  settingsWin.on("closed", () => {
    settingsWin = null;
    app.dock?.hide(); // back to menu-bar-only
  });
}

// --- settings application ---------------------------------------------------

/** Apply settings to the running app; returns whether the shortcut registered. */
function applySettings(s: Settings): boolean {
  if (s.monitoring) clipboardWatcher.start();
  else clipboardWatcher.stop();

  historyManager.setMaxSize(s.maxHistory);
  try {
    // Fails harmlessly for an unpackaged dev build ("operation not permitted");
    // works once installed as oioi.app.
    app.setLoginItemSettings({ openAtLogin: s.startAtLogin });
  } catch (err) {
    console.warn("setLoginItemSettings failed:", err);
  }
  return registerShortcut(s.shortcut);
}

function registerShortcut(accelerator: string): boolean {
  globalShortcut.unregisterAll();
  if (!accelerator) return false;
  try {
    return globalShortcut.register(accelerator, () => togglePanel(positionAtCursor));
  } catch {
    return false;
  }
}

// --- ipc --------------------------------------------------------------------

function registerIpc(): void {
  ipcMain.handle(IPC.getHistory, () => historyManager.getItems());

  ipcMain.handle(IPC.copyItem, (_e, id: string) => {
    const item = historyManager.getItems().find((i) => i.id === id);
    if (!item) return false;
    const ok = clipboardWatcher.writeItem(item);
    // Auto-close after a short delay, like the Swift panel.
    if (ok) setTimeout(() => panel?.hide(), 500);
    return ok;
  });

  ipcMain.handle(IPC.clearHistory, () => historyManager.clear());
  ipcMain.on(IPC.closePanel, () => panel?.hide());

  ipcMain.handle(IPC.getSettings, () => getSettings());

  ipcMain.handle(IPC.saveSettings, (_e, patch: Partial<Settings>): SaveSettingsResult => {
    const settings = saveSettings(patch);
    const shortcutOk = applySettings(settings);
    return { settings, shortcutOk };
  });

  ipcMain.handle(IPC.settingsDone, () => {
    saveSettings({ configured: true });
    settingsWin?.close();
  });

  ipcMain.handle(IPC.getAccessibility, () =>
    process.platform === "darwin" ? systemPreferences.isTrustedAccessibilityClient(false) : true
  );
  ipcMain.handle(IPC.openAccessibility, () => {
    if (process.platform === "darwin") systemPreferences.isTrustedAccessibilityClient(true);
    void shell.openExternal(
      "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    );
  });

  historyManager.on("changed", (items) => {
    panel?.webContents.send(IPC.historyUpdated, items);
  });
}

// --- lifecycle --------------------------------------------------------------

app.whenReady().then(() => {
  app.dock?.hide(); // menu-bar-only app (LSUIElement equivalent)
  registerIpc();
  createTray();
  panel = createPanel();

  const settings = getSettings();
  applySettings(settings);

  // Adobe-style: show the splash, then hand off to first-run onboarding.
  const splash = createSplash();
  setTimeout(() => {
    if (!splash.isDestroyed()) splash.destroy();
    if (!settings.configured) showSettings();
  }, 2200);
});

app.on("second-instance", () => showPanel(positionAtTray));

// Stay alive without windows — this is a menu-bar resident app.
app.on("window-all-closed", () => {});

app.on("will-quit", () => {
  globalShortcut.unregisterAll();
  clipboardWatcher.stop();
});
