// Port of oioi/Models/FilterTypes.swift — content-type and date-range filtering.
import type { ClipboardItem } from "./types";

export type ContentFilterType = "All" | "Text" | "Image" | "Files";
export const CONTENT_FILTERS: ContentFilterType[] = ["All", "Text", "Image", "Files"];

export type DateRangeFilter = "All Time" | "Today" | "Yesterday" | "Last 7 Days";
export const DATE_FILTERS: DateRangeFilter[] = ["All Time", "Today", "Yesterday", "Last 7 Days"];

const DAY_MS = 24 * 60 * 60 * 1000;

/** Mirrors DateRangeFilter.matches(_:) in the Swift app. */
export function dateMatches(filter: DateRangeFilter, timestamp: number): boolean {
  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();

  switch (filter) {
    case "All Time":
      return true;
    case "Today":
      return timestamp >= startOfToday;
    case "Yesterday": {
      const yesterday = startOfToday - DAY_MS;
      return timestamp >= yesterday && timestamp < startOfToday;
    }
    case "Last 7 Days":
      return timestamp >= startOfToday - 7 * DAY_MS;
  }
}

function kindMatches(kind: ClipboardItem["kind"], filter: ContentFilterType): boolean {
  switch (filter) {
    case "All":
      return true;
    case "Text":
      return kind === "text";
    case "Image":
      return kind === "image";
    case "Files":
      return kind === "files";
  }
}

export interface FilterState {
  searchText: string;
  type: ContentFilterType;
  dateRange: DateRangeFilter;
}

/** Mirrors HistoryViewModel.filteredItems: date -> type -> search (on previewString). */
export function filterItems(items: ClipboardItem[], state: FilterState): ClipboardItem[] {
  const query = state.searchText.trim().toLowerCase();
  return items.filter((item) => {
    if (!dateMatches(state.dateRange, item.timestamp)) return false;
    if (!kindMatches(item.kind, state.type)) return false;
    if (query.length === 0) return true;
    return item.previewString.toLowerCase().includes(query);
  });
}
