# oioi — Electron edition

An Electron port of the native macOS **oioi** clipboard manager. Runs with just
Node — **no Xcode required**.

## Run it

```bash
cd electron
npm install      # first time only (downloads Electron)
npm start        # builds, then launches the app
```

The app lives in the **menu bar** (look for the sloth icon — there's no Dock icon
or window on launch).

- **Click the tray icon** → opens the clipboard panel below it.
- **⌥V (Option+V)** → opens the panel next to your cursor, anywhere (the shortcut
  is configurable in Settings).
- **Right-click the tray icon** → menu with *Settings…*, *Clear History*, a
  *running* toggle, and *Quit*.

### Settings

A settings window opens automatically on first launch (and any time via
**right-click tray → Settings…**). It covers start/stop (clipboard monitoring),
the global shortcut (click to record a new one), start-at-login, history size,
and clearing history. Settings persist to `userData/settings.json`. **Done** is
enabled once oioi is running and a shortcut is set.

### In the panel

- Type in the search box to filter.
- Click the **type** chips (All / Text / Image / Files) or **date** chips
  (All Time / Today / Yesterday / Last 7 Days) to narrow the list.
- **↑ / ↓** to navigate, **Enter** / **Space** to copy the selected item,
  **Esc** to close.
- Click any item to copy it back to the clipboard (the panel auto-closes).

## How it maps to the Swift app

| Swift | Electron |
| --- | --- |
| `ClipboardManager` (0.5s `Timer` poll) | `src/main/clipboardWatcher.ts` |
| `HistoryManager` (max 50, dedupe, move-to-top) | `src/main/historyManager.ts` |
| `MenuBarController` (status item + ⌥V panel) | `src/main/main.ts` (`Tray` + `BrowserWindow`) |
| `FilterTypes.swift` | `src/shared/filters.ts` |
| `HistoryPanel` / `HistoryViewModel` (SwiftUI) | `src/renderer/*` |
| `NSVisualEffectView` blur | `BrowserWindow` `vibrancy: "popover"` |

## Known differences / limitations

- **Change detection:** Electron exposes no pasteboard `changeCount`, so the
  watcher polls and compares a content signature. Copying two *different* images
  with identical dimensions back-to-back is the one edge case it can miss.
- **File paste-back is best-effort.** Re-copying a *file* item writes both an
  `NSFilenamesPboardType` plist and a plain-text path fallback; pasting into
  Finder may not behave identically to the native app.
- **No haptic feedback** (no Electron equivalent).
- History is **in-memory only** (same as the Swift app — nothing is persisted to
  disk).

## Project layout

```
electron/
  scripts/build.mjs      # esbuild bundling + static copy
  src/
    shared/              # types + filter logic (used by main and renderer)
    main/                # main process: window, tray, clipboard, IPC
    renderer/            # the panel UI (HTML/CSS/TS)
  assets/                # tray + app icons (reused from the Swift app)
```
