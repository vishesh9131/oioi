# Installing oioi

oioi is a free, open clipboard manager for macOS (Intel **and** Apple Silicon).

Because it isn't paid-Apple-notarized, macOS shows a one-time "unidentified
developer" warning the **first** time you open it. Clearing it takes about 10
seconds — steps below. This is normal for free Mac apps and only happens once.

---

## Install

1. **Download** `oioi-x.y.z-universal.dmg`.
2. **Double-click the DMG**, then drag the **oioi** icon onto the **Applications**
   folder.
3. Eject the DMG (drag it to the Trash / click ⏏).

## First launch (clear the Gatekeeper warning — one time only)

Pick whichever is easier:

### Option A — Right-click to open (no Terminal)

1. Open your **Applications** folder.
2. **Right-click** (or Control-click) **oioi** → **Open**.
3. In the dialog, click **Open** again.

> On **macOS Sequoia (15) or later** the right-click dialog may only offer
> *Done*. If so: open **System Settings → Privacy & Security**, scroll down to
> *"oioi was blocked…"* and click **Open Anyway**, then confirm with **Open**.

### Option B — One Terminal command

```bash
xattr -dr com.apple.quarantine /Applications/oioi.app
```

Then open oioi normally (double-click). The warning is gone for good.

---

## Using oioi

- It lives in the **menu bar** (the sloth icon) — there's no Dock icon or window.
- **Click** the icon, or press **⌥V (Option+V)**, to open the clipboard panel.
- **Right-click** the icon for the menu, including **Start at Login**, **Clear
  History**, and **Quit**.

## Uninstall

Quit oioi (right-click the icon → Quit), then drag **oioi** from Applications to
the Trash.

---

### "Why the warning? Is it safe?"

Apple only removes that warning for apps signed by a developer enrolled in the
**$99/year** Apple Developer Program and run through Apple's notarization
service. oioi is free and not enrolled, so macOS can't auto-verify the
publisher — hence the prompt. The app is ad-hoc signed (so it runs natively on
Apple Silicon) and the full source is in this repo if you want to build it
yourself.
