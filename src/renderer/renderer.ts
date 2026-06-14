// Port of oioi/UI/HistoryPanel/HistoryPanel.swift + HistoryViewModel.swift
// Renders the clipboard history list with search, type/date filters, keyboard
// navigation, and copied feedback. Talks to main only through window.oioi.
import {
  CONTENT_FILTERS,
  DATE_FILTERS,
  filterItems,
  type ContentFilterType,
  type DateRangeFilter,
  type FilterState,
} from "../shared/filters";
import type { ClipboardItem } from "../shared/types";

// --- inline icons (stroke = currentColor) ----------------------------------
const ICONS = {
  search: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="7"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>`,
  clear: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>`,
  text: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="8" y1="13" x2="16" y2="13"/><line x1="8" y1="17" x2="13" y2="17"/></svg>`,
  image: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>`,
  files: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/></svg>`,
  copyText: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>`,
  check: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>`,
  clipboard: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/><rect x="8" y="2" width="8" height="4" rx="1"/></svg>`,
};

// --- state -----------------------------------------------------------------
let items: ClipboardItem[] = [];
const filter: FilterState = { searchText: "", type: "All", dateRange: "All Time" };
let selectedIndex: number | null = null;
let lastCopiedId: string | null = null;

const $ = <T extends HTMLElement>(sel: string): T => document.querySelector(sel) as T;

let searchInput: HTMLInputElement;
let clearBtn: HTMLButtonElement;
let typeRow: HTMLElement;
let dateRow: HTMLElement;
let listEl: HTMLElement;

function visibleItems(): ClipboardItem[] {
  return filterItems(items, filter);
}

// --- rendering -------------------------------------------------------------
function buildFilters(): void {
  const makeBtn = (label: string, onClick: () => void): HTMLButtonElement => {
    const b = document.createElement("button");
    b.className = "chip";
    b.textContent = label;
    b.dataset.value = label;
    b.addEventListener("click", onClick);
    return b;
  };

  for (const t of CONTENT_FILTERS) {
    typeRow.appendChild(
      makeBtn(t, () => {
        filter.type = t as ContentFilterType;
        selectedIndex = null;
        render();
      })
    );
  }
  for (const d of DATE_FILTERS) {
    dateRow.appendChild(
      makeBtn(d, () => {
        filter.dateRange = d as DateRangeFilter;
        selectedIndex = null;
        render();
      })
    );
  }
}

function syncChips(): void {
  typeRow.querySelectorAll<HTMLElement>(".chip").forEach((c) => {
    c.classList.toggle("active", c.dataset.value === filter.type);
  });
  dateRow.querySelectorAll<HTMLElement>(".chip").forEach((c) => {
    c.classList.toggle("active", c.dataset.value === filter.dateRange);
  });
}

function leadingIcon(item: ClipboardItem): string {
  if (item.kind === "image" && item.imageDataUrl) {
    return `<img class="thumb-icon" src="${item.imageDataUrl}" alt="" />`;
  }
  if (item.kind === "files" && item.iconDataUrl) {
    return `<img class="thumb-icon" src="${item.iconDataUrl}" alt="" />`;
  }
  return `<span class="glyph">${item.kind === "text" ? ICONS.text : item.kind === "image" ? ICONS.image : ICONS.files}</span>`;
}

function contentMarkup(item: ClipboardItem): string {
  if (item.kind === "image" && item.imageDataUrl) {
    return `<img class="thumb" src="${item.imageDataUrl}" alt="Image" />`;
  }
  const label =
    item.kind === "files"
      ? item.previewString
      : (item.text ?? item.previewString);
  return `<div class="content-text ${item.kind}">${escapeHtml(label)}</div>`;
}

function buildRow(item: ClipboardItem, index: number): HTMLElement {
  const row = document.createElement("div");
  row.className = "row";
  if (index === selectedIndex) row.classList.add("selected");
  const copied = item.id === lastCopiedId;
  if (copied) row.classList.add("copied");

  const copyIcon = copied ? ICONS.check : ICONS.copyText;

  row.innerHTML = `
    <div class="icon">${leadingIcon(item)}</div>
    <div class="body">
      ${contentMarkup(item)}
      <div class="timestamp">
        <span>${timeAgo(item.timestamp)}</span>
        ${copied ? `<span class="dot">• oioi</span>` : ""}
      </div>
    </div>
    <div class="copy-btn">${copyIcon}</div>`;

  row.addEventListener("click", () => copy(item.id));
  return row;
}

function render(): void {
  syncChips();
  renderList();
}

function renderList(): void {
  const list = visibleItems();
  if (selectedIndex != null && selectedIndex >= list.length) {
    selectedIndex = list.length > 0 ? list.length - 1 : null;
  }

  listEl.replaceChildren();

  if (list.length === 0) {
    const empty = document.createElement("div");
    empty.className = "empty";
    empty.innerHTML = `
      <div class="empty-icon">${ICONS.clipboard}</div>
      <div class="empty-title">Your clipboard history will appear here</div>
      <div class="empty-sub">Copy text to see it in your history</div>`;
    listEl.appendChild(empty);
    return;
  }

  const frag = document.createDocumentFragment();
  list.forEach((item, i) => frag.appendChild(buildRow(item, i)));
  listEl.appendChild(frag);
  scrollToSelected();
}

function scrollToSelected(): void {
  if (selectedIndex == null) return;
  const rows = listEl.querySelectorAll<HTMLElement>(".row");
  rows[selectedIndex]?.scrollIntoView({ block: "nearest" });
}

// --- actions ---------------------------------------------------------------
async function copy(id: string): Promise<void> {
  const ok = await window.oioi.copyItem(id);
  if (ok) {
    lastCopiedId = id;
    renderList();
  }
}

function move(delta: number): void {
  const len = visibleItems().length;
  if (len === 0) return;
  if (selectedIndex == null) {
    selectedIndex = delta > 0 ? 0 : len - 1;
  } else {
    selectedIndex = Math.max(0, Math.min(len - 1, selectedIndex + delta));
  }
  renderList();
}

function activateSelected(): void {
  const list = visibleItems();
  const idx = selectedIndex ?? 0;
  if (list[idx]) copy(list[idx].id);
}

// --- keyboard --------------------------------------------------------------
function onKeyDown(e: KeyboardEvent): void {
  const inSearch = e.target === searchInput;

  switch (e.key) {
    case "Escape":
      e.preventDefault();
      window.oioi.closePanel();
      return;
    case "ArrowDown":
      e.preventDefault();
      move(1);
      return;
    case "ArrowUp":
      e.preventDefault();
      move(-1);
      return;
    case "Enter":
      e.preventDefault();
      if (inSearch && selectedIndex == null) selectedIndex = 0;
      activateSelected();
      return;
    case " ":
      if (inSearch) return; // let the space type into the field
      e.preventDefault();
      activateSelected();
      return;
  }
}

// --- helpers ---------------------------------------------------------------
function timeAgo(ts: number): string {
  const s = Math.max(0, Math.floor((Date.now() - ts) / 1000));
  if (s < 60) return `${s}s ago`;
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  const d = Math.floor(h / 24);
  if (d < 7) return `${d}d ago`;
  const w = Math.floor(d / 7);
  if (w < 5) return `${w}w ago`;
  const mo = Math.floor(d / 30);
  if (mo < 12) return `${mo}mo ago`;
  return `${Math.floor(d / 365)}y ago`;
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

// --- init ------------------------------------------------------------------
function init(): void {
  searchInput = $("#search");
  clearBtn = $("#clear");
  typeRow = $("#type-filters");
  dateRow = $("#date-filters");
  listEl = $("#list");

  $("#search-icon").innerHTML = ICONS.search;
  clearBtn.innerHTML = ICONS.clear;
  $("#close").addEventListener("click", () => window.oioi.closePanel());

  buildFilters();

  searchInput.addEventListener("input", () => {
    filter.searchText = searchInput.value;
    selectedIndex = null;
    clearBtn.classList.toggle("hidden", searchInput.value.length === 0);
    renderList();
  });
  clearBtn.addEventListener("click", () => {
    searchInput.value = "";
    filter.searchText = "";
    clearBtn.classList.add("hidden");
    renderList();
    searchInput.focus();
  });

  document.addEventListener("keydown", onKeyDown);

  window.oioi.onHistoryUpdated((next) => {
    items = next;
    renderList();
  });
  window.oioi.onPanelShown(() => {
    lastCopiedId = null;
    selectedIndex = null;
    void refresh();
    void applyGlass();
    searchInput.focus();
    searchInput.select();
  });

  void refresh();
  void applyGlass();
  render();
  searchInput.focus();
}

async function applyGlass(): Promise<void> {
  const { glassTint } = await window.oioi.getSettings();
  document.documentElement.style.setProperty("--glass-a", String(glassTint));
}

async function refresh(): Promise<void> {
  items = await window.oioi.getHistory();
  renderList();
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", init);
} else {
  init();
}
