// Port of oioi/Managers/ClipboardManager.swift
// Electron has no pasteboard "changeCount", so we poll every 500ms and detect
// changes by comparing a lightweight signature of the current clipboard.
import { app, clipboard, nativeImage } from "electron";
import { createHash, randomUUID } from "node:crypto";
import { basename } from "node:path";
import { fileURLToPath } from "node:url";
import { historyManager } from "./historyManager";
import type { ClipboardItem } from "../shared/types";

const POLL_INTERVAL_MS = 500;

class ClipboardWatcher {
  private timer: NodeJS.Timeout | null = null;
  private paused = false;
  /** Cheap fingerprint of the last clipboard state we acted on. */
  private lastChangeKey = "";

  start(): void {
    this.stop();
    // Seed with whatever is currently on the clipboard so we don't capture it on launch.
    this.lastChangeKey = this.computeChangeKey();
    this.timer = setInterval(() => this.check(), POLL_INTERVAL_MS);
  }

  stop(): void {
    if (this.timer) clearInterval(this.timer);
    this.timer = null;
  }

  pause(): void {
    this.paused = true;
  }

  resume(): void {
    this.paused = false;
  }

  // --- reading -------------------------------------------------------------

  /** A quick fingerprint that avoids hashing image bytes on every poll. */
  private computeChangeKey(): string {
    const files = this.readFiles();
    const text = clipboard.readText();
    const img = clipboard.readImage();
    const imgKey = img.isEmpty() ? "" : `${img.getSize().width}x${img.getSize().height}`;
    return `f:${files.join("|")}##i:${imgKey}##t:${text}`;
  }

  private async check(): Promise<void> {
    if (this.paused) return;

    const changeKey = this.computeChangeKey();
    if (changeKey === this.lastChangeKey) return;
    this.lastChangeKey = changeKey;

    const item = await this.buildItem();
    if (item) historyManager.add(item);
  }

  /** Priority mirrors the Swift app: file URLs -> image -> plain text. */
  private async buildItem(): Promise<ClipboardItem | null> {
    const files = this.readFiles();
    if (files.length > 0) {
      const iconDataUrl = await this.fileIcon(files[0]);
      const previewString = files.length === 1 ? basename(files[0]) : `${files.length} Files`;
      return this.base("files", `f:${files.join("\n")}`, { files, iconDataUrl, previewString });
    }

    const img = clipboard.readImage();
    if (!img.isEmpty()) {
      const png = img.toPNG();
      const signature = `i:${createHash("md5").update(png).digest("hex")}`;
      const imageDataUrl = `data:image/png;base64,${png.toString("base64")}`;
      // Icon-only file copies often still carry the name as text — use it.
      const label = clipboard.readText().trim();
      return this.base("image", signature, {
        imageDataUrl,
        previewString: label || "Image",
      });
    }

    const text = clipboard.readText();
    if (text.length > 0) {
      return this.base("text", `t:${text}`, { text, previewString: text });
    }

    return null;
  }

  private base(
    kind: ClipboardItem["kind"],
    signature: string,
    extra: Partial<ClipboardItem>
  ): ClipboardItem {
    return {
      id: randomUUID(),
      timestamp: Date.now(),
      kind,
      signature,
      previewString: "",
      ...extra,
    };
  }

  /** Read copied file paths. macOS exposes them via NSFilenamesPboardType / public.file-url. */
  private readFiles(): string[] {
    const formats = clipboard.availableFormats();

    if (formats.includes("NSFilenamesPboardType")) {
      const plist = clipboard.read("NSFilenamesPboardType");
      const paths = [...plist.matchAll(/<string>([\s\S]*?)<\/string>/g)].map((m) =>
        decodeXmlEntities(m[1])
      );
      if (paths.length > 0) return paths;
    }

    if (formats.includes("public.file-url")) {
      const url = clipboard.read("public.file-url").trim();
      if (url) {
        try {
          return [fileURLToPath(url)];
        } catch {
          /* not a valid file URL — ignore */
        }
      }
    }

    return [];
  }

  private async fileIcon(path: string): Promise<string | undefined> {
    try {
      const icon = await app.getFileIcon(path, { size: "normal" });
      return icon.isEmpty() ? undefined : icon.toDataURL();
    } catch {
      return undefined;
    }
  }

  // --- writing (copy back) -------------------------------------------------

  /**
   * Write an item back to the clipboard. Pauses monitoring around the write and
   * primes lastChangeKey so the watcher doesn't immediately re-capture it
   * (mirrors pauseMonitoring/resumeMonitoring in HistoryViewModel.copyToClipboard).
   */
  writeItem(item: ClipboardItem): boolean {
    this.pause();
    let success = false;
    try {
      switch (item.kind) {
        case "text":
          if (item.text != null) {
            clipboard.writeText(item.text);
            success = true;
          }
          break;
        case "image":
          if (item.imageDataUrl) {
            clipboard.writeImage(nativeImage.createFromDataURL(item.imageDataUrl));
            success = true;
          }
          break;
        case "files":
          success = this.writeFiles(item.files ?? []);
          break;
      }
    } finally {
      // Re-seed the fingerprint to the new content, then resume shortly after.
      this.lastChangeKey = this.computeChangeKey();
      setTimeout(() => this.resume(), 300);
    }
    return success;
  }

  /** Best-effort file write: NSFilenamesPboardType plist + plain-text fallback. */
  private writeFiles(paths: string[]): boolean {
    const valid = paths.filter(Boolean);
    if (valid.length === 0) return false;
    // Text fallback first (some targets only read text); then attach the file list.
    clipboard.writeText(valid.join("\n"));
    try {
      const items = valid.map((p) => `<string>${encodeXmlEntities(p)}</string>`).join("");
      const plist =
        `<?xml version="1.0" encoding="UTF-8"?>` +
        `<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">` +
        `<plist version="1.0"><array>${items}</array></plist>`;
      clipboard.writeBuffer("NSFilenamesPboardType", Buffer.from(plist, "utf8"));
    } catch {
      /* plist write unsupported — text fallback already applied */
    }
    return true;
  }
}

function decodeXmlEntities(s: string): string {
  return s
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&amp;/g, "&");
}

function encodeXmlEntities(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

export const clipboardWatcher = new ClipboardWatcher();
