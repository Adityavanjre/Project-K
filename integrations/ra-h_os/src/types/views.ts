// View system types

export type ViewType = 'focus' | 'list' | 'grid' | 'table' | 'map';

export interface ViewFilter {
  context: string;
  operator: 'includes' | 'excludes';
}

export interface ViewSort {
  field: 'title' | 'created_at' | 'updated_at' | 'edge_count';
  direction: 'asc' | 'desc';
}

export interface ViewConfig {
  filters: ViewFilter[];
  filterLogic: 'and' | 'or';
  sort: ViewSort;
}

export interface SavedView {
  id: number;
  name: string;
  type: ViewType;
  config: ViewConfig;
  is_default: boolean;
  created_at: string;
  updated_at: string;
}

// Default view configuration
export const DEFAULT_VIEW_CONFIG: ViewConfig = {
  filters: [],
  filterLogic: 'and',
  sort: { field: 'updated_at', direction: 'desc' },
};
