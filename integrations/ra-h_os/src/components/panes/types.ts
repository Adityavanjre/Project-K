import { Node } from '@/types/database';
import type { FocusedSkill } from '@/types/skills';

export type SlotId = 'A' | 'B' | 'C';

// The pane types
export type PaneType = 'node' | 'map' | 'views' | 'table' | 'skills';

// A single tab within a slot
export interface SlotTab {
  id: string;        // 'views', 'map', or 'node-{nodeId}'
  type: PaneType;
  nodeId?: number;   // Only for type === 'node'
}

// State for each slot — persistent tabs
export interface SlotState {
  tabs: SlotTab[];
  activeTabId: string;
}

// Helper to create a consistent tab ID
export function createTabId(type: PaneType, nodeId?: number): string {
  return type === 'node' && nodeId != null ? `node-${nodeId}` : type;
}

// Helper to get the active tab from a slot state
export function getActiveTab(state: SlotState): SlotTab | undefined {
  return state.tabs.find(t => t.id === state.activeTabId);
}

// Actions panes can emit to the layout
export type PaneAction =
  | { type: 'open-node'; nodeId: number; targetSlot?: SlotId }
  | { type: 'switch-pane-type'; paneType: PaneType }
  | { type: 'close-pane' };

// Common props for all panes
export interface BasePaneProps {
  slot: SlotId;
  isActive: boolean;
  onPaneAction?: (action: PaneAction) => void;
  onCollapse?: () => void;
  onSwapPanes?: (source: SlotId, target: SlotId) => void;
  tabBar?: React.ReactNode;
}

// NodePane specific props
export interface NodePaneProps extends BasePaneProps {
  openTabs: number[];
  activeTab: number | null;
  onTabSelect: (nodeId: number) => void;
  onTabClose: (nodeId: number) => void;
  onNodeClick?: (nodeId: number) => void;
  onReorderTabs?: (fromIndex: number, toIndex: number) => void;
  refreshTrigger?: number;
  onOpenInOtherSlot?: (nodeId: number) => void;
  onTextSelect?: (nodeId: number, nodeTitle: string, text: string) => void;
  highlightedPassage?: HighlightedPassage | null;
}

// Highlighted passage for source awareness
export interface HighlightedPassage {
  nodeId: number;
  nodeTitle: string;
  selectedText: string;
}

export interface ChatPanelProps {
  isOpen: boolean;
  isSoloPane?: boolean;
  slot?: SlotId;
  onClose: () => void;
  onOpen: () => void;
  onSwapPanes?: (source: SlotId, target: SlotId) => void;
  openTabsData: Node[];
  activeTabId: number | null;
  focusedSkill?: FocusedSkill | null;
  onClearFocusedSkill?: () => void;
  onNodeClick?: (nodeId: number) => void;
  chatMessages?: unknown[];
  setChatMessages?: React.Dispatch<React.SetStateAction<unknown[]>>;
  highlightedPassage?: HighlightedPassage | null;
  onClearPassage?: () => void;
  onboardingHint?: string | null;
  onDismissOnboardingHint?: () => void;
}

// MapPane specific props
export interface MapPaneProps extends BasePaneProps {
  onNodeClick?: (nodeId: number) => void;
  focusedNodeId?: number | null;
  onClearFocus?: () => void;
}

// ViewsPane specific props
export interface ViewsPaneProps extends BasePaneProps {
  onNodeClick: (nodeId: number) => void;
  onNodeOpenInOtherPane?: (nodeId: number) => void;
  refreshToken?: number;
}

// TablePane specific props
export interface TablePaneProps extends BasePaneProps {
  onNodeClick: (nodeId: number) => void;
  refreshToken?: number;
}

// Pane header props
export interface PaneHeaderProps {
  slot?: SlotId;
  onCollapse?: () => void;
  onSwapPanes?: (source: SlotId, target: SlotId) => void;
  tabBar?: React.ReactNode;
  children?: React.ReactNode;
  toolbarHostRef?: (node: HTMLDivElement | null) => void;
}

// Labels for pane types
export const PANE_LABELS: Record<PaneType, string> = {
  node: 'Nodes',
  map: 'Map',
  views: 'Feed',
  table: 'Table',
  skills: 'Skills',
};

// Default slot states
export const DEFAULT_SLOT_A: SlotState = {
  tabs: [{ id: 'views', type: 'views' }],
  activeTabId: 'views',
};

export const DEFAULT_SLOT_B: SlotState | null = null;
