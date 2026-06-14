// Safe IPC bridge exposed to the renderer as window.oioi (contextIsolation on).
import { contextBridge, ipcRenderer } from "electron";
import {
  IPC,
  type ClipboardItem,
  type Settings,
  type SaveSettingsResult,
} from "../shared/types";

const api = {
  getHistory: (): Promise<ClipboardItem[]> => ipcRenderer.invoke(IPC.getHistory),
  copyItem: (id: string): Promise<boolean> => ipcRenderer.invoke(IPC.copyItem, id),
  clearHistory: (): Promise<void> => ipcRenderer.invoke(IPC.clearHistory),
  closePanel: (): void => ipcRenderer.send(IPC.closePanel),

  getSettings: (): Promise<Settings> => ipcRenderer.invoke(IPC.getSettings),
  saveSettings: (patch: Partial<Settings>): Promise<SaveSettingsResult> =>
    ipcRenderer.invoke(IPC.saveSettings, patch),
  settingsDone: (): Promise<void> => ipcRenderer.invoke(IPC.settingsDone),
  getAccessibility: (): Promise<boolean> => ipcRenderer.invoke(IPC.getAccessibility),
  openAccessibility: (): Promise<void> => ipcRenderer.invoke(IPC.openAccessibility),

  onHistoryUpdated: (cb: (items: ClipboardItem[]) => void): (() => void) => {
    const listener = (_e: unknown, items: ClipboardItem[]) => cb(items);
    ipcRenderer.on(IPC.historyUpdated, listener);
    return () => ipcRenderer.off(IPC.historyUpdated, listener);
  },

  onPanelShown: (cb: () => void): (() => void) => {
    const listener = () => cb();
    ipcRenderer.on(IPC.panelShown, listener);
    return () => ipcRenderer.off(IPC.panelShown, listener);
  },
};

export type OioiApi = typeof api;

contextBridge.exposeInMainWorld("oioi", api);
