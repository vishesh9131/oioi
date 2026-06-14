// Port of oioi/Managers/HistoryManager.swift
// In-memory ring of the most recent clipboard items, de-duplicated by content.
import { EventEmitter } from "node:events";
import type { ClipboardItem } from "../shared/types";

class HistoryManager extends EventEmitter {
  private items: ClipboardItem[] = [];
  private maxHistorySize = 50;

  getItems(): ClipboardItem[] {
    return this.items;
  }

  /** Update the cap; trims existing items if the new cap is smaller. */
  setMaxSize(size: number): void {
    this.maxHistorySize = Math.max(1, size);
    if (this.items.length > this.maxHistorySize) {
      this.items.length = this.maxHistorySize;
      this.emitChange();
    }
  }

  /**
   * Add a freshly captured item. If an identical item already exists (same
   * content signature) it is moved to the top instead of duplicated — mirroring
   * the Swift app, which keeps the original timestamp on a move.
   */
  add(item: ClipboardItem): void {
    const existingIndex = this.items.findIndex((i) => i.signature === item.signature);
    if (existingIndex !== -1) {
      const [existing] = this.items.splice(existingIndex, 1);
      this.items.unshift(existing);
    } else {
      this.items.unshift(item);
      if (this.items.length > this.maxHistorySize) {
        this.items.length = this.maxHistorySize;
      }
    }
    this.emitChange();
  }

  clear(): void {
    this.items = [];
    this.emitChange();
  }

  private emitChange(): void {
    this.emit("changed", this.items);
  }
}

export const historyManager = new HistoryManager();
