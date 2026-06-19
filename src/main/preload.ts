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
  onboardingDone: (): Promise<void> => ipcRenderer.invoke(IPC.onboardingDone),
  getAccessibility: (): Promise<boolean> => ipcRenderer.invoke(IPC.getAccessibility),
  openAccessibility: (): Promise<void> => ipcRenderer.invoke(IPC.openAccessibility),
  getScreenPermission: (): Promise<boolean> => ipcRenderer.invoke(IPC.getScreenPermission),
  openScreenSettings: (): Promise<void> => ipcRenderer.invoke(IPC.openScreenSettings),

  onPanelOpened: (cb: () => void): (() => void) => {
    const listener = () => cb();
    ipcRenderer.on(IPC.panelOpened, listener);
    return () => ipcRenderer.off(IPC.panelOpened, listener);
  },

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

  onBackdrop: (cb: (dataUrl: string) => void): (() => void) => {
    const listener = (_e: unknown, dataUrl: string) => cb(dataUrl);
    ipcRenderer.on(IPC.backdrop, listener);
    return () => ipcRenderer.off(IPC.backdrop, listener);
  },
};

export type OioiApi = typeof api;

contextBridge.exposeInMainWorld("oioi", api);
