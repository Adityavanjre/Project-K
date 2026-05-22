"use client";

import { useState, useCallback, useEffect, useRef, useMemo } from 'react';
import { GripVertical, X } from 'lucide-react';
import SettingsModal, { SettingsTab } from '../settings/SettingsModal';
import SearchModal from '../nodes/SearchModal';
import { Node } from '@/types/database';
import { DatabaseEvent } from '@/services/events';
import { usePersistentState } from '@/hooks/usePersistentState';
import { useTheme } from '@/hooks/useTheme';

// Layout components
import LeftToolbar from './LeftToolbar';
import SplitHandle from './SplitHandle';
import ChatPanel from './ChatPanel';

// Pane components
import { NodePane, MapPane, ViewsPane, TablePane, SkillsPane, SlotTabBar } from '../panes';
import QuickAddInput from '../agents/QuickAddInput';
import type { PaneType, SlotState, SlotTab, PaneAction, SlotId } from '../panes/types';
import { createTabId, getActiveTab } from '../panes/types';
import type { FocusedSkill } from '@/types/skills';

export interface PendingNode {
  id: string;
  input: string;
  inputType: string;
  submittedAt: number;
  status: 'processing' | 'error';
  error?: string;
}

// --- localStorage migration ---
function migrateSlotState(raw: unknown): SlotState | null {
  if (raw === null || raw === undefined) return null;
  const obj = raw as Record<string, unknown>;
  const validPaneTypes = new Set<PaneType>(['views', 'node', 'map', 'table', 'skills']);

  // Already v4+ format (has tabs array) — filter out removed pane types
  if (Array.isArray(obj.tabs)) {
    const state = raw as SlotState;
    const mappedTabs = state.tabs.map(t => (t.type as string) === 'guides'
      ? { ...t, id: 'skills', type: 'skills' as PaneType }
      : t);
    const filtered = mappedTabs.filter(t => validPaneTypes.has(t.type));
    if (filtered.length === 0) return null;
    const activeStillExists = filtered.some(t => t.id === state.activeTabId);
    const activeTabId = state.activeTabId === 'guides' ? 'skills' : state.activeTabId;
    return { tabs: filtered, activeTabId: activeStillExists ? activeTabId : filtered[0].id };
  }

  // v3 format (has type field) — migrate
  if (typeof obj.type === 'string') {
    const oldType = obj.type as string;

    // Removed pane types should not hydrate into current panel state
    if (!validPaneTypes.has(oldType as PaneType) && oldType !== 'guides') return null;
    if (oldType === 'guides') {
      return { tabs: [{ id: 'skills', type: 'skills' }], activeTabId: 'skills' };
    }

    const paneType = oldType as PaneType;
    const tabs: SlotTab[] = [];

    // Add the main type tab
    if (paneType === 'node') {
      // Migrate node tabs
      const nodeTabs = (obj.nodeTabs as number[]) || [];
      for (const nodeId of nodeTabs) {
        tabs.push({ id: createTabId('node', nodeId), type: 'node', nodeId });
      }
      if (tabs.length === 0) {
        // Empty node pane — just return null
        return null;
      }
      const activeNodeTab = obj.activeNodeTab as number | null | undefined;
      const activeTabId = activeNodeTab != null
        ? createTabId('node', activeNodeTab)
        : tabs[0].id;
      return { tabs, activeTabId };
    }

    // Singleton pane type
    tabs.push({ id: createTabId(paneType), type: paneType });
    return { tabs, activeTabId: tabs[0].id };
  }

  return null;
}

function stripNodeTabsForPersistence(state: SlotState | null): SlotState | null {
  if (!state) return null;

  const tabs = state.tabs.filter((tab) => tab.type !== 'node');
  if (tabs.length === 0) {
    return null;
  }

  const activeTabId = tabs.some((tab) => tab.id === state.activeTabId)
    ? state.activeTabId
    : tabs[0].id;

  return { tabs, activeTabId };
}

function readPersistedSlotState(key: string, fallback: SlotState | null): SlotState | null {
  if (typeof window === 'undefined') {
    return fallback;
  }

  try {
    const raw = window.localStorage.getItem(key);
    if (raw === null) {
      return fallback;
    }

    return stripNodeTabsForPersistence(migrateSlotState(JSON.parse(raw))) ?? fallback;
  } catch (error) {
    console.error(`Error loading ${key} from localStorage:`, error);
    return fallback;
  }
}

function persistSlotState(key: string, state: SlotState | null): void {
  if (typeof window === 'undefined') {
    return;
  }

  try {
    const sanitized = stripNodeTabsForPersistence(state);
    if (sanitized) {
      window.localStorage.setItem(key, JSON.stringify(sanitized));
    } else {
      window.localStorage.removeItem(key);
    }
  } catch (error) {
    console.error(`Error saving ${key} to localStorage:`, error);
  }
}

const DEFAULT_SLOT_A: SlotState = {
  tabs: [{ id: 'views', type: 'views' }],
  activeTabId: 'views',
};

const SLOT_A_KEY = 'ui.slotA.v6';
const SLOT_B_KEY = 'ui.slotB.v6';
const SLOT_C_KEY = 'ui.slotC.v6';
const CHAT_PANEL_OPEN_KEY = 'ui.chatPanel.open';
const CHAT_SLOT_KEY = 'ui.chatPanel.slot.v1';
const VISIBLE_PANE_COUNT_KEY = 'ui.visiblePaneCount.v1';
const PANEL_A_EXPANDED_KEY = 'ui.panelA.expanded.v1';
const PANEL_B_EXPANDED_KEY = 'ui.panelB.expanded.v1';
const PANEL_C_EXPANDED_KEY = 'ui.panelC.expanded.v1';
const PANEL_A_WEIGHT_KEY = 'ui.panelA.weight.v1';
const PANEL_B_WEIGHT_KEY = 'ui.panelB.weight.v1';
const PANEL_C_WEIGHT_KEY = 'ui.panelC.weight.v1';
const LEFT_NAV_EXPANDED_KEY = 'ui.leftNavExpanded';
const ONBOARDING_SURFACE_SEEN_KEY = 'ui.onboarding.firstRun.seen.v1';
const ONBOARDING_HINT_DISMISSED_KEY = 'ui.onboarding.firstRun.dismissed.v1';
const ONBOARDING_BOOTSTRAP_CHECKED_KEY = 'ui.onboarding.firstRun.checked.v1';
const ONBOARDING_HINT_TEXT = 'Just tell your agent you want to get setup, and it will help you.';
const SLOT_ORDER: SlotId[] = ['A', 'B', 'C'];
const MIN_PANE_WIDTH = 280;
const CHAT_FEATURE_ENABLED = false;

function deriveInitialPaneCount(): number {
  if (typeof window === 'undefined') {
    return 2;
  }

  const stored = window.localStorage.getItem(VISIBLE_PANE_COUNT_KEY);
  if (stored) {
    const parsed = Number(stored);
    if (parsed >= 1 && parsed <= 3) {
      return parsed;
    }
  }

  try {
    const panelCExpanded = window.localStorage.getItem(PANEL_C_EXPANDED_KEY) === 'true';
    const panelBExpanded = window.localStorage.getItem(PANEL_B_EXPANDED_KEY) === 'true';
    return panelCExpanded ? 3 : panelBExpanded ? 2 : 1;
  } catch {
    return 2;
  }
}

function isTauriRuntime(): boolean {
  if (typeof window === 'undefined') return false;
  return Boolean((window as unknown as { __TAURI__?: unknown }).__TAURI__);
}

export default function ThreePanelLayout() {
  const containerRef = useRef<HTMLDivElement>(null);
  const panelRefs = useRef<Record<SlotId, HTMLDivElement | null>>({ A: null, B: null, C: null });
  const hasHydratedPaneCountRef = useRef(false);
  const [theme, toggleTheme] = useTheme();

  const [slotA, setSlotA] = useState<SlotState | null>(() => readPersistedSlotState(SLOT_A_KEY, DEFAULT_SLOT_A));
  const [slotB, setSlotB] = useState<SlotState | null>(() => readPersistedSlotState(SLOT_B_KEY, null));
  const [slotC, setSlotC] = useState<SlotState | null>(() => readPersistedSlotState(SLOT_C_KEY, null));
  const [visiblePaneCount, setVisiblePaneCount] = usePersistentState<number>(VISIBLE_PANE_COUNT_KEY, 2);
  const [panelAExpanded, setPanelAExpanded] = usePersistentState<boolean>(PANEL_A_EXPANDED_KEY, true);
  const [panelBExpanded, setPanelBExpanded] = usePersistentState<boolean>(PANEL_B_EXPANDED_KEY, false);
  const [panelCExpanded, setPanelCExpanded] = usePersistentState<boolean>(PANEL_C_EXPANDED_KEY, false);
  const [panelAWeight, setPanelAWeight] = usePersistentState<number>(PANEL_A_WEIGHT_KEY, 1);
  const [panelBWeight, setPanelBWeight] = usePersistentState<number>(PANEL_B_WEIGHT_KEY, 1);
  const [panelCWeight, setPanelCWeight] = usePersistentState<number>(PANEL_C_WEIGHT_KEY, 1);
  const [chatPanelOpen, setChatPanelOpen] = usePersistentState<boolean>(CHAT_PANEL_OPEN_KEY, false);
  const [chatSlot, setChatSlot] = usePersistentState<SlotId | null>(CHAT_SLOT_KEY, null);
  const [leftNavExpanded, setLeftNavExpanded] = usePersistentState<boolean>(LEFT_NAV_EXPANDED_KEY, false);

  // Track which pane is active
  const [activePane, setActivePane] = useState<SlotId>('A');

  // Settings modal state
  const [showSettings, setShowSettings] = useState(false);
  const [settingsInitialTab, setSettingsInitialTab] = useState<SettingsTab>();
  const handleCloseSettings = useCallback(() => {
    setShowSettings(false);
    setSettingsInitialTab(undefined);
  }, []);

  // Search modal state
  const [showSearchModal, setShowSearchModal] = useState(false);

  // Add Stuff modal state
  const [showAddStuff, setShowAddStuff] = useState(false);

  // Pending quick-add nodes (loading placeholders)
  const [pendingNodes, setPendingNodes] = useState<PendingNode[]>([]);

  // Track selected nodes (for context)
  const [selectedNodes, setSelectedNodes] = useState<Set<number>>(new Set<number>());
  const [focusedNodeId, setFocusedNodeId] = useState<number | null>(null);
  const [isMapFocusSuppressed, setIsMapFocusSuppressed] = useState(false);

  // Open tabs data (full node objects for context)
  const [openTabsData, setOpenTabsData] = useState<Node[]>([]);

  // Event handlers for SSE events
  const [nodesPanelRefresh, setNodesPanelRefresh] = useState(0);
  const [focusPanelRefresh, setFocusPanelRefresh] = useState(0);
  const [folderViewRefresh, setFolderViewRefresh] = useState(0);

  const [focusedSkill, setFocusedSkill] = useState<FocusedSkill | null>(null);
  const [autoOpenSkillName, setAutoOpenSkillName] = useState<string | null>(null);
  const [showOnboardingHint, setShowOnboardingHint] = useState(false);

  // Chat state (lifted to persist across pane type changes)
  const [chatMessages, setChatMessages] = useState<unknown[]>([]);

  // Source awareness - highlighted passage context for agent
  const [highlightedPassage, setHighlightedPassage] = useState<{
    nodeId: number;
    nodeTitle: string;
    selectedText: string;
  } | null>(null);

  // Ref to get current openTabs value in SSE handler
  const openTabsRef = useRef<number[]>([]);

  const dismissOnboardingHint = useCallback(() => {
    if (typeof window !== 'undefined') {
      window.localStorage.setItem(ONBOARDING_HINT_DISMISSED_KEY, 'true');
    }
    setShowOnboardingHint(false);
  }, []);

  useEffect(() => {
    persistSlotState(SLOT_A_KEY, slotA);
  }, [slotA]);

  useEffect(() => {
    persistSlotState(SLOT_B_KEY, slotB);
  }, [slotB]);

  useEffect(() => {
    persistSlotState(SLOT_C_KEY, slotC);
  }, [slotC]);

  useEffect(() => {
    let cancelled = false;

    if (typeof window === 'undefined' || !isTauriRuntime()) {
      return;
    }

    if (
      window.localStorage.getItem(ONBOARDING_SURFACE_SEEN_KEY)
      || window.localStorage.getItem(ONBOARDING_HINT_DISMISSED_KEY)
      || window.localStorage.getItem(ONBOARDING_BOOTSTRAP_CHECKED_KEY)
    ) {
      return;
    }

    void (async () => {
      try {
        const response = await fetch('/api/nodes?limit=1');
        if (!response.ok) return;

        const data = await response.json();
        const total = typeof data.total === 'number'
          ? data.total
          : Number(data.total ?? data.count ?? 0);

        if (cancelled || Number.isNaN(total)) {
          return;
        }

        window.localStorage.setItem(ONBOARDING_BOOTSTRAP_CHECKED_KEY, 'true');

        if (total >= 3) {
          return;
        }

        window.localStorage.setItem(ONBOARDING_SURFACE_SEEN_KEY, 'true');
        setSlotA({ tabs: [{ id: 'skills', type: 'skills' }], activeTabId: 'skills' });
        setSlotB(null);
        setSlotC(null);
        setVisiblePaneCount(1);
        setActivePane('A');
        setAutoOpenSkillName('Onboarding');
        if (CHAT_FEATURE_ENABLED) {
          setChatPanelOpen(true);
          setChatSlot('A');
          setShowOnboardingHint(true);
        }
      } catch (error) {
        console.error('[ThreePanelLayout] Failed to bootstrap onboarding surface:', error);
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [setChatPanelOpen, setChatSlot, setSlotA, setSlotB, setSlotC, setVisiblePaneCount]);

  // --- Collect node tabs from both slots for chat context ---
  const { openTabs, activeTab } = useMemo(() => {
    const collectNodeTabs = (state: SlotState | null): number[] => {
      if (!state) return [];
      return state.tabs
        .filter(t => t.type === 'node' && t.nodeId != null)
        .map(t => t.nodeId!);
    };

    const slotStates: Record<SlotId, SlotState | null> = { A: slotA, B: slotB, C: slotC };
    const activeSlotState = slotStates[activePane];
    const otherNodes = (['A', 'B', 'C'] as SlotId[])
      .filter((slot) => slot !== activePane)
      .flatMap((slot) => collectNodeTabs(slotStates[slot]));

    const activeNodes = collectNodeTabs(activeSlotState);
    const allNodes = [...new Set([...activeNodes, ...otherNodes])];

    // Active tab: prefer the active slot's node tab, then another active node.
    let active: number | null = null;
    if (activeSlotState) {
      const activeT = getActiveTab(activeSlotState);
      if (activeT?.type === 'node' && activeT.nodeId != null) {
        active = activeT.nodeId;
      }
    }
    if (active == null) {
      for (const slot of ['A', 'B', 'C'] as SlotId[]) {
        if (slot === activePane) continue;
        const otherT = getActiveTab(slotStates[slot] ?? { tabs: [], activeTabId: '' });
        if (otherT?.type === 'node' && otherT.nodeId != null) {
          active = otherT.nodeId;
          break;
        }
      }
    }
    if (active == null && allNodes.length > 0) {
      active = allNodes[0];
    }

    return { openTabs: allNodes, activeTab: active };
  }, [slotA, slotB, slotC, activePane]);

  const deriveFallbackFocusedNode = useCallback((): number | null => {
    const slotStates: Record<SlotId, SlotState | null> = { A: slotA, B: slotB, C: slotC };
    const orderedSlots: SlotId[] = [activePane, ...(['A', 'B', 'C'] as SlotId[]).filter((slot) => slot !== activePane)];

    for (const slot of orderedSlots) {
      const activeTab = getActiveTab(slotStates[slot] ?? { tabs: [], activeTabId: '' });
      if (activeTab?.type === 'node' && activeTab.nodeId != null) {
        return activeTab.nodeId;
      }
    }

    for (const slot of orderedSlots) {
      const fallbackTab = slotStates[slot]?.tabs.find((tab) => tab.type === 'node' && tab.nodeId != null);
      if (fallbackTab?.nodeId != null) {
        return fallbackTab.nodeId;
      }
    }

    return null;
  }, [activePane, slotA, slotB, slotC]);

  // Fetch full node data for open tabs
  const fetchOpenTabsData = async (tabIds: number[]) => {
    if (tabIds.length === 0) {
      setOpenTabsData([]);
      return;
    }

    try {
      const nodePromises = tabIds.map(async (id) => {
        const response = await fetch(`/api/nodes/${id}`);
        if (response.ok) {
          const data = await response.json();
          return data.node as Node;
        }
        return null;
      });

      const nodes = await Promise.all(nodePromises);
      const validNodes = nodes.filter((node): node is Node => Boolean(node)).map(node => ({
        id: node.id,
        title: node.title,
        description: node.description,
        link: node.link,
        source: node.source,
        created_at: node.created_at,
        updated_at: node.updated_at,
        chunk_status: node.chunk_status,
        metadata: node.metadata,
      }));
      setOpenTabsData(validNodes);
    } catch (error) {
      console.error('Failed to fetch tab data:', error);
      setOpenTabsData([]);
    }
  };

  // Update tab data whenever openTabs changes or a node is updated
  const openTabsKey = openTabs.join(',');
  useEffect(() => {
    openTabsRef.current = openTabs;
    fetchOpenTabsData(openTabs);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [openTabsKey, focusPanelRefresh]);

  useEffect(() => {
    if (focusedNodeId == null) {
      return;
    }

    const isStillOpen = [slotA, slotB, slotC].some((state) =>
      state?.tabs.some((tab) => tab.type === 'node' && tab.nodeId === focusedNodeId),
    );

    if (!isStillOpen) {
      setFocusedNodeId(deriveFallbackFocusedNode());
    }
  }, [deriveFallbackFocusedNode, focusedNodeId, slotA, slotB, slotC]);

  useEffect(() => {
    if (focusedNodeId != null || isMapFocusSuppressed) {
      return;
    }

    const initialFocusedNode = deriveFallbackFocusedNode();
    if (initialFocusedNode != null) {
      setFocusedNodeId(initialFocusedNode);
    }
  }, [deriveFallbackFocusedNode, focusedNodeId, isMapFocusSuppressed]);

  // Timeout cleanup for stuck pending nodes (90s)
  useEffect(() => {
    if (pendingNodes.length === 0) return;
    const interval = setInterval(() => {
      const now = Date.now();
      setPendingNodes(prev => prev.filter(p => {
        // Keep error nodes for 30s so user can see them, then auto-dismiss
        if (p.status === 'error') return now - p.submittedAt < 120_000;
        // Auto-dismiss processing nodes after 90s
        return now - p.submittedAt < 90_000;
      }));
    }, 5_000);
    return () => clearInterval(interval);
  }, [pendingNodes.length]);

  const handleRefreshAll = useCallback(() => {
    setNodesPanelRefresh(prev => prev + 1);
    setFolderViewRefresh(prev => prev + 1);
    setFocusPanelRefresh(prev => prev + 1);
  }, []);

  const getSuggestedPaneType = useCallback((): Exclude<PaneType, 'node'> => {
    const openTypes = new Set<PaneType>();
    slotA?.tabs.forEach((tab) => openTypes.add(tab.type));
    slotB?.tabs.forEach((tab) => openTypes.add(tab.type));
    slotC?.tabs.forEach((tab) => openTypes.add(tab.type));

    const order: Exclude<PaneType, 'node'>[] = ['map', 'table', 'skills', 'views'];
    return order.find((paneType) => !openTypes.has(paneType)) || 'map';
  }, [slotA, slotB, slotC]);

  const getSlotState = useCallback((slot: SlotId): SlotState | null => {
    switch (slot) {
      case 'A':
        return slotA;
      case 'B':
        return slotB;
      case 'C':
        return slotC;
    }
  }, [slotA, slotB, slotC]);

  const getSlotSetter = useCallback((slot: SlotId) => {
    switch (slot) {
      case 'A':
        return setSlotA;
      case 'B':
        return setSlotB;
      case 'C':
        return setSlotC;
    }
  }, [setSlotA, setSlotB, setSlotC]);

  const visibleSlots = useMemo(
    () => SLOT_ORDER.slice(0, Math.max(1, Math.min(3, visiblePaneCount))),
    [visiblePaneCount]
  );
  const searchModalFilters = useMemo(() => [], []);

  const isPanelExpanded = useCallback((slot: SlotId) => {
    return visibleSlots.includes(slot);
  }, [visibleSlots]);

  const setPanelExpanded = useCallback((slot: SlotId, expanded: boolean) => {
    if (!expanded) {
      return;
    }

    const requiredCount = SLOT_ORDER.indexOf(slot) + 1;
    setVisiblePaneCount((current) => Math.max(current, requiredCount));
  }, [setVisiblePaneCount]);

  const getPanelWeight = useCallback((slot: SlotId) => {
    switch (slot) {
      case 'A':
        return panelAWeight;
      case 'B':
        return panelBWeight;
      case 'C':
        return panelCWeight;
    }
  }, [panelAWeight, panelBWeight, panelCWeight]);

  const setPanelWeight = useCallback((slot: SlotId, weight: number) => {
    const next = Math.max(0.6, Math.min(3, weight));
    switch (slot) {
      case 'A':
        setPanelAWeight(next);
        break;
      case 'B':
        setPanelBWeight(next);
        break;
      case 'C':
        setPanelCWeight(next);
        break;
    }
  }, [setPanelAWeight, setPanelBWeight, setPanelCWeight]);

  const isSlotEmpty = useCallback((slot: SlotId) => {
    const state = getSlotState(slot);
    return !state || state.tabs.length === 0;
  }, [getSlotState]);

  const getAvailableVisibleContentSlots = useCallback(() => {
    if (!CHAT_FEATURE_ENABLED) {
      return visibleSlots;
    }
    return visibleSlots.filter((slot) => slot !== chatSlot);
  }, [chatSlot, visibleSlots]);

  useEffect(() => {
    if (hasHydratedPaneCountRef.current || typeof window === 'undefined') {
      return;
    }

    hasHydratedPaneCountRef.current = true;

    if (window.localStorage.getItem(VISIBLE_PANE_COUNT_KEY) !== null) {
      return;
    }

    setVisiblePaneCount(deriveInitialPaneCount());
  }, [setVisiblePaneCount]);

  useEffect(() => {
    setPanelAExpanded(true);
    setPanelBExpanded(visiblePaneCount >= 2);
    setPanelCExpanded(visiblePaneCount >= 3);
  }, [setPanelAExpanded, setPanelBExpanded, setPanelCExpanded, visiblePaneCount]);

  useEffect(() => {
    if (!visibleSlots.includes(activePane) || (CHAT_FEATURE_ENABLED && activePane === chatSlot)) {
      const fallback = getAvailableVisibleContentSlots()[0] ?? visibleSlots[0] ?? 'A';
      setActivePane(fallback);
    }
  }, [activePane, chatSlot, getAvailableVisibleContentSlots, visibleSlots]);

  useEffect(() => {
    if (!CHAT_FEATURE_ENABLED) {
      if (chatPanelOpen) {
        setChatPanelOpen(false);
      }
      if (chatSlot !== null) {
        setChatSlot(null);
      }
      return;
    }

    if (!chatPanelOpen) {
      if (chatSlot !== null) {
        setChatSlot(null);
      }
      return;
    }

    // Keep chat pinned to its current visible slot. Reassign only when chat has
    // no slot yet or its slot is no longer visible (for example after reducing
    // pane count). Otherwise an empty sibling pane can cause A<->B flip-flopping.
    if (chatSlot !== null && visibleSlots.includes(chatSlot)) {
      return;
    }

    const spareVisibleSlots = visibleSlots.filter((slot) => slot !== chatSlot && isSlotEmpty(slot));
    const nextChatSlot = spareVisibleSlots[spareVisibleSlots.length - 1]
      ?? visibleSlots[visibleSlots.length - 1]
      ?? 'A';

    if (chatSlot !== nextChatSlot) {
      setChatSlot(nextChatSlot);
    }
  }, [chatPanelOpen, chatSlot, isSlotEmpty, setChatPanelOpen, setChatSlot, visibleSlots]);

  // --- SSE connection for real-time updates ---
  useEffect(() => {
    let eventSource: EventSource | null = null;

    try {
      eventSource = new EventSource('/api/events');

      eventSource.onopen = () => {
        console.log('SSE connected for real-time updates');
      };

      eventSource.onmessage = (event) => {
        try {
          const data: DatabaseEvent = JSON.parse(event.data);

          switch (data.type) {
            case 'NODE_CREATED':
              setNodesPanelRefresh(prev => prev + 1);
              break;

            case 'NODE_UPDATED': {
              const currentOpenTabs = openTabsRef.current;
              const updatedNodeId = Number(data.data.nodeId);
              if (currentOpenTabs.includes(updatedNodeId)) {
                setFocusPanelRefresh(prev => prev + 1);
              }
              setNodesPanelRefresh(prev => prev + 1);
              break;
            }

            case 'NODE_DELETED':
              handleNodeDeleted(data.data.nodeId);
              setNodesPanelRefresh(prev => prev + 1);
              break;

            case 'EDGE_CREATED':
            case 'EDGE_DELETED': {
              const currentOpenTabsForEdge = openTabsRef.current;
              if (currentOpenTabsForEdge.includes(data.data.fromNodeId) ||
                  currentOpenTabsForEdge.includes(data.data.toNodeId)) {
                setFocusPanelRefresh(prev => prev + 1);
              }
              break;
            }

            case 'DIMENSION_UPDATED':
              setNodesPanelRefresh(prev => prev + 1);
              setFolderViewRefresh(prev => prev + 1);
              break;

            case 'HELPER_UPDATED':
            case 'AGENT_UPDATED':
              if (typeof window !== 'undefined') {
                window.dispatchEvent(new CustomEvent('agents:updated', { detail: data.data }));
              }
              break;

            case 'SKILL_UPDATED':
              if (typeof window !== 'undefined') {
                window.dispatchEvent(new CustomEvent('skills:updated'));
              }
              break;

            case 'QUICK_ADD_COMPLETED': {
              const completedId = data.data?.quickAddId;
              if (completedId) {
                setPendingNodes(prev => prev.filter(p => p.id !== completedId));
              }
              break;
            }

            case 'QUICK_ADD_FAILED': {
              const failedId = data.data?.quickAddId;
              const errorMsg = data.data?.error || 'Processing failed';
              if (failedId) {
                setPendingNodes(prev => prev.map(p =>
                  p.id === failedId ? { ...p, status: 'error' as const, error: errorMsg } : p
                ));
              }
              break;
            }

            case 'CONNECTION_ESTABLISHED':
              console.log('SSE connection established');
              break;

            default:
              console.log('Unknown SSE event:', data.type);
          }
        } catch (error) {
          console.error('Failed to parse SSE event:', error);
        }
      };

      eventSource.onerror = (error) => {
        console.error('SSE connection error:', error);
      };
    } catch (error) {
      console.error('Failed to establish SSE connection:', error);
    }

    return () => {
      if (eventSource) {
        eventSource.close();
      }
    };
  }, []);

  // --- Tab helpers ---

  const setSingletonPaneInSlot = useCallback((
    setter: React.Dispatch<React.SetStateAction<SlotState | null>>,
    paneType: Exclude<PaneType, 'node'>,
  ) => {
    const tab: SlotTab = { id: createTabId(paneType), type: paneType };

    setter((prev) => {
      if (!prev || prev.tabs.length === 0) {
        return { tabs: [tab], activeTabId: tab.id };
      }

      const existingIndex = prev.tabs.findIndex((t) => t.type === paneType);
      if (existingIndex >= 0) {
        return { ...prev, activeTabId: prev.tabs[existingIndex].id };
      }

      const tabs = [...prev.tabs];
      const nonNodeIndex = tabs.findIndex((t) => t.type !== 'node');

      if (nonNodeIndex >= 0) {
        tabs[nonNodeIndex] = tab;
      } else {
        tabs.push(tab);
      }

      return { tabs, activeTabId: tab.id };
    });
  }, []);

  const focusPaneIfOpen = useCallback((paneType: Exclude<PaneType, 'node'>): SlotId | null => {
    const tabId = createTabId(paneType);

    for (const slot of visibleSlots) {
      if (slot === chatSlot) {
        continue;
      }

      const state = getSlotState(slot);
      if (state?.tabs.some((tab) => tab.id === tabId)) {
        getSlotSetter(slot)((prev) => prev ? { ...prev, activeTabId: tabId } : prev);
        setActivePane(slot);
        return slot;
      }
    }

    return null;
  }, [chatSlot, getSlotSetter, getSlotState, visibleSlots]);

  const openPaneSingleton = useCallback((paneType: Exclude<PaneType, 'node'>, preferredSlot?: SlotId) => {
    const existing = focusPaneIfOpen(paneType);
    if (existing) {
      return existing;
    }

    const orderedVisibleSlots = preferredSlot && visibleSlots.includes(preferredSlot)
      ? [preferredSlot, ...visibleSlots.filter((slot) => slot !== preferredSlot)]
      : visibleSlots;

    const contentSlots = orderedVisibleSlots.filter((slot) => slot !== chatSlot);
    const visibleEmpty = contentSlots.find((slot) => isSlotEmpty(slot));
    if (visibleEmpty) {
      setSingletonPaneInSlot(getSlotSetter(visibleEmpty), paneType);
      setActivePane(visibleEmpty);
      return visibleEmpty;
    }

    const replacementTarget = contentSlots.includes(activePane)
      ? activePane
      : contentSlots[contentSlots.length - 1]
        ?? orderedVisibleSlots[orderedVisibleSlots.length - 1]
        ?? 'A';

    setSingletonPaneInSlot(getSlotSetter(replacementTarget), paneType);
    setActivePane(replacementTarget);
    return replacementTarget;
  }, [activePane, chatSlot, focusPaneIfOpen, getSlotSetter, isSlotEmpty, setSingletonPaneInSlot, visibleSlots]);

  // Add or focus a tab in a slot
  const addOrFocusTab = useCallback((
    setter: (value: SlotState | null | ((prev: SlotState | null) => SlotState | null)) => void,
    currentState: SlotState | null,
    tab: SlotTab,
  ) => {
    if (tab.type !== 'node') {
      setter({ tabs: [tab], activeTabId: tab.id });
      return;
    }

    const nodeTabs = currentState?.tabs.filter((t) => t.type === 'node') ?? [];
    const existing = nodeTabs.find((t) => t.id === tab.id);

    if (existing) {
      setter({ tabs: nodeTabs, activeTabId: tab.id });
    } else {
      setter({
        tabs: [...nodeTabs, tab],
        activeTabId: tab.id,
      });
    }
  }, []);

  // Remove a tab from a slot
  const removeTabFromSlot = useCallback((
    setter: (value: SlotState | null | ((prev: SlotState | null) => SlotState | null)) => void,
    currentState: SlotState | null,
    tabId: string,
  ) => {
    if (!currentState) return;
    const newTabs = currentState.tabs.filter(t => t.id !== tabId);
    if (newTabs.length === 0) {
      setter(null);
      return;
    }
    let newActiveTabId = currentState.activeTabId;
    if (currentState.activeTabId === tabId) {
      const oldIndex = currentState.tabs.findIndex(t => t.id === tabId);
      const newIndex = Math.min(oldIndex, newTabs.length - 1);
      newActiveTabId = newTabs[newIndex].id;
    }
    setter(prev => prev ? { ...prev, tabs: newTabs, activeTabId: newActiveTabId } : null);
  }, []);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        setShowSearchModal(true);
      }

      if ((e.metaKey || e.ctrlKey) && e.key === '\\') {
        e.preventDefault();
        setVisiblePaneCount((current) => Math.min(3, current + 1));
      }

      if (CHAT_FEATURE_ENABLED && (e.metaKey || e.ctrlKey) && e.key === 'j') {
        e.preventDefault();
        setChatPanelOpen((prev: boolean) => !prev);
      }

      if ((e.metaKey || e.ctrlKey) && e.key === 'n') {
        if (document.activeElement?.closest('[data-rah-app]')) {
          e.preventDefault();
          setShowAddStuff(true);
        }
      }

      if ((e.metaKey || e.ctrlKey) && e.shiftKey && e.key === 'r') {
        e.preventDefault();
        handleRefreshAll();
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [handleRefreshAll, setChatPanelOpen, setVisiblePaneCount]);

  // --- Node tab management ---
  const addNodeTabToSlot = useCallback((
    slot: SlotId,
    nodeId: number,
  ) => {
    const tab: SlotTab = { id: createTabId('node', nodeId), type: 'node', nodeId };
    const setter = getSlotSetter(slot);
    const state = getSlotState(slot);
    addOrFocusTab(setter, state, tab);
    setIsMapFocusSuppressed(false);
    setFocusedNodeId(nodeId);
  }, [getSlotSetter, getSlotState, addOrFocusTab]);

  const openNodeFromSlot = useCallback((nodeId: number, fromSlot?: SlotId) => {
    const existingTabId = createTabId('node', nodeId);
    const contentSlots = visibleSlots.filter((slot) => slot !== chatSlot);

    for (const slot of visibleSlots) {
      if (slot === chatSlot) {
        continue;
      }
      const state = getSlotState(slot);
      if (state?.tabs.some((tab) => tab.id === existingTabId)) {
        getSlotSetter(slot)((prev) => prev ? { ...prev, activeTabId: existingTabId } : prev);
        setSelectedNodes(new Set([nodeId]));
        setIsMapFocusSuppressed(false);
        setFocusedNodeId(nodeId);
        setActivePane(slot);
        return;
      }
    }

    const visibleNodeSlots = contentSlots.filter((slot) => {
      const state = getSlotState(slot);
      return state?.tabs.some((tab) => tab.type === 'node');
    });

    const preferredNodeTarget = fromSlot && visibleNodeSlots.includes(fromSlot)
      ? fromSlot
      : visibleNodeSlots.includes(activePane)
        ? activePane
        : visibleNodeSlots[0];

    if (preferredNodeTarget) {
      addNodeTabToSlot(preferredNodeTarget, nodeId);
      setSelectedNodes(new Set([nodeId]));
      setIsMapFocusSuppressed(false);
      setFocusedNodeId(nodeId);
      setActivePane(preferredNodeTarget);
      return;
    }

    const orderedTargets = fromSlot
      ? [...contentSlots.filter((slot) => slot !== fromSlot), fromSlot]
      : contentSlots;
    const emptyTarget = orderedTargets.find((slot) => isSlotEmpty(slot));
    const preferredActiveTarget = orderedTargets.includes(activePane) ? activePane : null;
    const target = emptyTarget ?? preferredActiveTarget ?? orderedTargets[orderedTargets.length - 1] ?? 'A';

    addNodeTabToSlot(target, nodeId);
    setSelectedNodes(new Set([nodeId]));
    setIsMapFocusSuppressed(false);
    setFocusedNodeId(nodeId);
    setActivePane(target);
  }, [activePane, addNodeTabToSlot, chatSlot, getSlotSetter, getSlotState, isSlotEmpty, visibleSlots]);

  const handleNodeSelect = useCallback((nodeId: number, _multiSelect: boolean) => {
    openNodeFromSlot(nodeId);
  }, [openNodeFromSlot]);

  const handleTabSelectA = useCallback((tabId: string) => {
    setSlotA(prev => prev ? { ...prev, activeTabId: tabId } : null);
    // If it's a node tab, update selection
    const tab = slotA?.tabs.find(t => t.id === tabId);
    if (tab?.type === 'node' && tab.nodeId) {
      setSelectedNodes(new Set([tab.nodeId]));
      setIsMapFocusSuppressed(false);
      setFocusedNodeId(tab.nodeId);
    }
    setActivePane('A');
  }, [slotA, setSlotA]);

  const handleTabSelectB = useCallback((tabId: string) => {
    setSlotB(prev => prev ? { ...prev, activeTabId: tabId } : null);
    const tab = slotB?.tabs.find(t => t.id === tabId);
    if (tab?.type === 'node' && tab.nodeId) {
      setSelectedNodes(new Set([tab.nodeId]));
      setIsMapFocusSuppressed(false);
      setFocusedNodeId(tab.nodeId);
    }
    setActivePane('B');
  }, [slotB, setSlotB]);

  const handleTabSelectC = useCallback((tabId: string) => {
    setSlotC(prev => prev ? { ...prev, activeTabId: tabId } : null);
    const tab = slotC?.tabs.find(t => t.id === tabId);
    if (tab?.type === 'node' && tab.nodeId) {
      setSelectedNodes(new Set([tab.nodeId]));
      setIsMapFocusSuppressed(false);
      setFocusedNodeId(tab.nodeId);
    }
    setActivePane('C');
  }, [slotC, setSlotC]);

  const clearMapFocus = useCallback(() => {
    setIsMapFocusSuppressed(true);
    setFocusedNodeId(null);
  }, []);

  const handleCloseTabA = useCallback((tabId: string) => {
    removeTabFromSlot(setSlotA, slotA, tabId);
    // Remove from selection if it's a node
    const tab = slotA?.tabs.find(t => t.id === tabId);
    if (tab?.type === 'node' && tab.nodeId) {
      setSelectedNodes(prev => {
        const next = new Set(prev);
        next.delete(tab.nodeId!);
        return next;
      });
    }
  }, [slotA, setSlotA, removeTabFromSlot]);

  const handleCloseTabB = useCallback((tabId: string) => {
    removeTabFromSlot(setSlotB, slotB, tabId);
  }, [slotB, setSlotB, removeTabFromSlot]);

  const handleCloseTabC = useCallback((tabId: string) => {
    removeTabFromSlot(setSlotC, slotC, tabId);
  }, [slotC, setSlotC, removeTabFromSlot]);

  // Get node-specific props from a slot for rendering NodePane
  const getNodeTabsFromSlot = useCallback((state: SlotState | null): { openTabs: number[]; activeTab: number | null } => {
    if (!state) return { openTabs: [], activeTab: null };
    const nodeTabs = state.tabs.filter(t => t.type === 'node' && t.nodeId != null);
    const nodeIds = nodeTabs.map(t => t.nodeId!);
    const activeT = getActiveTab(state);
    const activeNodeId = activeT?.type === 'node' && activeT.nodeId != null ? activeT.nodeId : null;
    return { openTabs: nodeIds, activeTab: activeNodeId };
  }, []);

  const handleNodeCreated = useCallback((newNode: Node) => {
    openNodeFromSlot(newNode.id);
  }, [openNodeFromSlot]);

  const handleNodeDeleted = useCallback((nodeId: number) => {
    const tabId = createTabId('node', nodeId);
    removeTabFromSlot(setSlotA, slotA, tabId);
    removeTabFromSlot(setSlotB, slotB, tabId);
    removeTabFromSlot(setSlotC, slotC, tabId);
  }, [slotA, slotB, slotC, setSlotA, setSlotB, setSlotC, removeTabFromSlot]);

  const handleReorderTabsA = useCallback((fromIndex: number, toIndex: number) => {
    if (fromIndex === toIndex || !slotA) return;
    if (fromIndex < 0 || toIndex < 0 || fromIndex >= slotA.tabs.length || toIndex >= slotA.tabs.length) return;
    const updated = [...slotA.tabs];
    const [moved] = updated.splice(fromIndex, 1);
    updated.splice(toIndex, 0, moved);
    setSlotA(prev => prev ? { ...prev, tabs: updated } : null);
  }, [slotA, setSlotA]);

  const handleReorderTabsB = useCallback((fromIndex: number, toIndex: number) => {
    if (fromIndex === toIndex || !slotB) return;
    if (fromIndex < 0 || toIndex < 0 || fromIndex >= slotB.tabs.length || toIndex >= slotB.tabs.length) return;
    const updated = [...slotB.tabs];
    const [moved] = updated.splice(fromIndex, 1);
    updated.splice(toIndex, 0, moved);
    setSlotB(prev => prev ? { ...prev, tabs: updated } : null);
  }, [slotB, setSlotB]);

  const handleReorderTabsC = useCallback((fromIndex: number, toIndex: number) => {
    if (fromIndex === toIndex || !slotC) return;
    if (fromIndex < 0 || toIndex < 0 || fromIndex >= slotC.tabs.length || toIndex >= slotC.tabs.length) return;
    const updated = [...slotC.tabs];
    const [moved] = updated.splice(fromIndex, 1);
    updated.splice(toIndex, 0, moved);
    setSlotC(prev => prev ? { ...prev, tabs: updated } : null);
  }, [slotC, setSlotC]);

  const handleFolderViewDataChanged = useCallback(() => {
    setFolderViewRefresh(prev => prev + 1);
    setNodesPanelRefresh(prev => prev + 1);
  }, []);

  const handleNodeOpenFromDimensions = useCallback((nodeId: number) => {
    openNodeFromSlot(nodeId, 'A');
  }, [openNodeFromSlot]);

  // Handle pane type selection from toolbar — add/focus tab in active slot
  const handlePaneTypeClick = useCallback((paneType: PaneType) => {
    if (paneType !== 'node') {
      openPaneSingleton(paneType);
    }
  }, [openPaneSingleton]);

  // Auto-open Feed pane if not already visible
  const ensureFeedOpen = useCallback(() => {
    const visibleFeedSlot = visibleSlots.find((slot) => {
      if (slot === chatSlot) return false;
      return getSlotState(slot)?.tabs.some((tab) => tab.type === 'views');
    });

    if (visibleFeedSlot) {
      const state = getSlotState(visibleFeedSlot);
      const viewsTab = state?.tabs.find((tab) => tab.type === 'views');
      if (viewsTab) {
        getSlotSetter(visibleFeedSlot)((prev) => prev ? { ...prev, activeTabId: viewsTab.id } : prev);
        setActivePane(visibleFeedSlot);
        return;
      }
    }

    openPaneSingleton('views');
  }, [chatSlot, getSlotSetter, getSlotState, openPaneSingleton, visibleSlots]);

  const handleQuickAddSubmit = useCallback(async ({ input, mode, description }: { input: string; mode: 'link' | 'text'; description?: string }) => {
    try {
      const response = await fetch('/api/quick-add', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ input, mode, description })
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Failed to submit Quick Add');
      }

      const data = await response.json();
      const result = data.result as { id: string; inputType: string } | undefined;

      if (result?.id) {
        setPendingNodes(prev => [{
          id: result.id,
          input: input.trim(),
          inputType: result.inputType || 'note',
          submittedAt: Date.now(),
          status: 'processing',
        }, ...prev]);
      }

      ensureFeedOpen();
      setShowAddStuff(false);
    } catch (error) {
      console.error('[ThreePanelLayout] Quick Add error:', error);
    }
  }, [ensureFeedOpen]);

  // Handle closing a pane
  const handleCloseSlotA = useCallback(() => {
    setSlotA(null);
    setActivePane('A');
  }, [setSlotA]);

  const handleCloseSlotB = useCallback(() => {
    setSlotB(null);
    setActivePane('A');
  }, [setSlotB]);

  const handleCloseSlotC = useCallback(() => {
    setSlotC(null);
    setActivePane(visibleSlots[0] ?? 'A');
  }, [setSlotC, visibleSlots]);

  // Handle pane actions
  const handleSlotAAction = useCallback((action: PaneAction) => {
    switch (action.type) {
      case 'switch-pane-type': {
        if (action.paneType !== 'node') {
          setSingletonPaneInSlot(setSlotA, action.paneType);
          setActivePane('A');
        }
        break;
      }
      case 'open-node':
        openNodeFromSlot(action.nodeId, 'A');
        break;
    }
  }, [openNodeFromSlot, setSingletonPaneInSlot]);

  const handleSlotBAction = useCallback((action: PaneAction) => {
    switch (action.type) {
      case 'switch-pane-type': {
        if (action.paneType !== 'node') {
          setSingletonPaneInSlot(setSlotB, action.paneType);
          setActivePane('B');
        }
        break;
      }
      case 'open-node':
        openNodeFromSlot(action.nodeId, 'B');
        break;
    }
  }, [openNodeFromSlot, setSingletonPaneInSlot]);

  const handleSlotCAction = useCallback((action: PaneAction) => {
    switch (action.type) {
      case 'switch-pane-type': {
        if (action.paneType !== 'node') {
          setSingletonPaneInSlot(setSlotC, action.paneType);
          setActivePane('C');
        }
        break;
      }
      case 'open-node':
        openNodeFromSlot(action.nodeId, 'C');
        break;
    }
  }, [openNodeFromSlot, setSingletonPaneInSlot]);

  // Handle search result selection
  const handleSearchNodeSelect = useCallback((nodeId: number) => {
    handleNodeSelect(nodeId, false);
    setShowSearchModal(false);
  }, [handleNodeSelect]);

  const handleSwapPanes = useCallback((source: SlotId, target: SlotId) => {
    if (source === target) return;

    const sourceState = getSlotState(source);
    const targetState = getSlotState(target);

    getSlotSetter(source)(targetState);
    getSlotSetter(target)(sourceState);

    if (activePane === source) {
      setActivePane(target);
    } else if (activePane === target) {
      setActivePane(source);
    }

    if (chatSlot === source) {
      setChatSlot(target);
    } else if (chatSlot === target) {
      setChatSlot(source);
    }
  }, [activePane, chatSlot, getSlotSetter, getSlotState, setChatSlot]);

  // --- Drag state for cross-slot tab dragging ---
  const [dragOverSlot, setDragOverSlot] = useState<SlotId | null>(null);

  const handleSlotDragOver = useCallback((e: React.DragEvent, slot: SlotId) => {
    if (e.dataTransfer.types.includes('application/x-rah-pane') ||
        e.dataTransfer.types.includes('application/x-rah-tab') ||
        e.dataTransfer.types.includes('application/node-info')) {
      e.preventDefault();
      e.dataTransfer.dropEffect = e.dataTransfer.types.includes('application/x-rah-pane') ? 'move' : 'copy';
      setDragOverSlot(slot);
    }
  }, []);

  const handleSlotDragLeave = useCallback(() => {
    setDragOverSlot(null);
  }, []);

  const handleSlotDrop = useCallback((e: React.DragEvent, targetSlot: SlotId) => {
    setDragOverSlot(null);

    const paneData = e.dataTransfer.getData('application/x-rah-pane');
    if (paneData) {
      const sourceSlot = paneData as SlotId;
      if (sourceSlot !== targetSlot) {
        handleSwapPanes(sourceSlot, targetSlot);
      }
      return;
    }

    let tabData = e.dataTransfer.getData('application/x-rah-tab');
    if (!tabData) {
      tabData = e.dataTransfer.getData('application/node-info');
    }
    if (!tabData) return;

    try {
      const parsed = JSON.parse(tabData);
      const sourceSlot = parsed.sourceSlot as SlotId | undefined;

      // If it has tabId/tabType, it's a full tab drag
      if (parsed.tabId && parsed.tabType) {
        const tab: SlotTab = {
          id: parsed.tabId,
          type: parsed.tabType,
          ...(parsed.nodeId != null ? { nodeId: parsed.nodeId } : {}),
        };

        // Same slot — just select
        if (sourceSlot === targetSlot) {
          if (targetSlot === 'A') {
            setSlotA(prev => prev ? { ...prev, activeTabId: tab.id } : null);
          } else if (targetSlot === 'B') {
            setSlotB(prev => prev ? { ...prev, activeTabId: tab.id } : null);
          } else {
            setSlotC(prev => prev ? { ...prev, activeTabId: tab.id } : null);
          }
          return;
        }

        // Cross-slot: remove from source, add to target
        if (sourceSlot === 'A') removeTabFromSlot(setSlotA, slotA, tab.id);
        if (sourceSlot === 'B') removeTabFromSlot(setSlotB, slotB, tab.id);
        if (sourceSlot === 'C') removeTabFromSlot(setSlotC, slotC, tab.id);

        const targetSetter = getSlotSetter(targetSlot);
        const targetState = getSlotState(targetSlot);
        addOrFocusTab(targetSetter, targetState, tab);
        setActivePane(targetSlot);
        return;
      }

      // Legacy: node-info drop (from sidebar etc.)
      const nodeId = parsed.id;
      if (typeof nodeId !== 'number') return;

      const tab: SlotTab = { id: createTabId('node', nodeId), type: 'node', nodeId };
      const targetSetter = getSlotSetter(targetSlot);
      const targetState = getSlotState(targetSlot);

      addOrFocusTab(targetSetter, targetState, tab);
      setActivePane(targetSlot);
    } catch (err) {
      console.error('Failed to parse dropped tab data:', err);
    }
  }, [getSlotSetter, getSlotState, handleSwapPanes, slotA, slotB, slotC, addOrFocusTab, removeTabFromSlot, setSlotC]);

  // Cross-slot drop handler for SlotTabBar
  const handleCrossSlotDropA = useCallback((tab: SlotTab, fromSlot: SlotId) => {
    if (fromSlot === 'B') removeTabFromSlot(setSlotB, slotB, tab.id);
    if (fromSlot === 'C') removeTabFromSlot(setSlotC, slotC, tab.id);
    addOrFocusTab(setSlotA, slotA, tab);
    setActivePane('A');
  }, [slotA, slotB, slotC, setSlotA, setSlotB, setSlotC, addOrFocusTab, removeTabFromSlot]);

  const handleCrossSlotDropB = useCallback((tab: SlotTab, fromSlot: SlotId) => {
    if (fromSlot === 'A') removeTabFromSlot(setSlotA, slotA, tab.id);
    if (fromSlot === 'C') removeTabFromSlot(setSlotC, slotC, tab.id);
    addOrFocusTab(setSlotB, slotB, tab);
    setActivePane('B');
  }, [slotA, slotB, slotC, setSlotA, setSlotB, setSlotC, addOrFocusTab, removeTabFromSlot]);

  const handleCrossSlotDropC = useCallback((tab: SlotTab, fromSlot: SlotId) => {
    if (fromSlot === 'A') removeTabFromSlot(setSlotA, slotA, tab.id);
    if (fromSlot === 'B') removeTabFromSlot(setSlotB, slotB, tab.id);
    addOrFocusTab(setSlotC, slotC, tab);
    setActivePane('C');
  }, [slotA, slotB, slotC, setSlotA, setSlotB, setSlotC, addOrFocusTab, removeTabFromSlot]);

  const handleResizePanels = useCallback((left: SlotId, right: SlotId, clientX: number) => {
    const leftEl = panelRefs.current[left];
    const rightEl = panelRefs.current[right];
    if (!leftEl || !rightEl) return;

    const leftRect = leftEl.getBoundingClientRect();
    const rightRect = rightEl.getBoundingClientRect();
    const combinedWidth = leftRect.width + rightRect.width;
    if (combinedWidth <= 0) return;

    const rawLeftWidth = clientX - leftRect.left;
    const nextLeftWidth = Math.max(MIN_PANE_WIDTH, Math.min(combinedWidth - MIN_PANE_WIDTH, rawLeftWidth));
    const nextRightWidth = combinedWidth - nextLeftWidth;
    const totalWeight = getPanelWeight(left) + getPanelWeight(right);

    setPanelWeight(left, (nextLeftWidth / combinedWidth) * totalWeight);
    setPanelWeight(right, (nextRightWidth / combinedWidth) * totalWeight);
  }, [getPanelWeight, setPanelWeight]);

  // --- Compute toolbar indicators ---
  const { openTabTypes, activeTabType } = useMemo(() => {
    const types = new Set<PaneType>();
    if (slotA) {
      for (const tab of slotA.tabs) types.add(tab.type);
    }
    if (slotB) {
      for (const tab of slotB.tabs) types.add(tab.type);
    }
    if (slotC) {
      for (const tab of slotC.tabs) types.add(tab.type);
    }

    const activeSlot = getSlotState(activePane);
    const activeT = activeSlot ? getActiveTab(activeSlot) : null;

    return {
      openTabTypes: types,
      activeTabType: activeT?.type ?? null,
    };
  }, [slotA, slotB, slotC, activePane, getSlotState]);

  // --- Render a slot based on the active tab ---
  const renderSlotContent = (slot: SlotId, state: SlotState) => {
    const isActive = activePane === slot;
    const onCollapse = slot === 'A'
      ? handleCloseSlotA
      : slot === 'B'
        ? handleCloseSlotB
        : handleCloseSlotC;
    const activeT = getActiveTab(state);
    if (!activeT) return null;

    const renderTabBar = () => (
      <SlotTabBar
        tabs={state.tabs}
        activeTabId={state.activeTabId}
        slot={slot}
        onTabSelect={slot === 'A' ? handleTabSelectA : slot === 'B' ? handleTabSelectB : handleTabSelectC}
        onTabClose={slot === 'A' ? handleCloseTabA : slot === 'B' ? handleCloseTabB : handleCloseTabC}
        onReorderTabs={slot === 'A' ? handleReorderTabsA : slot === 'B' ? handleReorderTabsB : handleReorderTabsC}
        onCrossSlotDrop={slot === 'A' ? handleCrossSlotDropA : slot === 'B' ? handleCrossSlotDropB : handleCrossSlotDropC}
      />
    );

    const tabBarElement = activeT.type === 'node' ? renderTabBar() : undefined;

    switch (activeT.type) {
      case 'node': {
        const { openTabs: nodeTabs, activeTab: activeNodeTab } = getNodeTabsFromSlot(state);
        return (
          <NodePane
            slot={slot}
            isActive={isActive}
            onPaneAction={slot === 'A' ? handleSlotAAction : slot === 'B' ? handleSlotBAction : handleSlotCAction}
            onCollapse={onCollapse}
            onSwapPanes={handleSwapPanes}
            tabBar={tabBarElement}
            openTabs={nodeTabs}
            activeTab={activeNodeTab}
            onTabSelect={(nodeId) => {
              const tabId = createTabId('node', nodeId);
              if (slot === 'A') handleTabSelectA(tabId);
              else if (slot === 'B') handleTabSelectB(tabId);
              else handleTabSelectC(tabId);
            }}
            onTabClose={(nodeId) => {
              const tabId = createTabId('node', nodeId);
              if (slot === 'A') handleCloseTabA(tabId);
              else if (slot === 'B') handleCloseTabB(tabId);
              else handleCloseTabC(tabId);
            }}
            onNodeClick={(nodeId) => {
              addNodeTabToSlot(slot, nodeId);
              setSelectedNodes(new Set([nodeId]));
              setActivePane(slot);
            }}
            onReorderTabs={slot === 'A' ? (fromIndex: number, toIndex: number) => {
              const nodeTabIndices = state.tabs.reduce<number[]>((acc, t, i) => {
                if (t.type === 'node') acc.push(i);
                return acc;
              }, []);
              if (fromIndex < nodeTabIndices.length && toIndex < nodeTabIndices.length) {
                handleReorderTabsA(nodeTabIndices[fromIndex], nodeTabIndices[toIndex]);
              }
            } : slot === 'B' ? (fromIndex: number, toIndex: number) => {
              const nodeTabIndices = state.tabs.reduce<number[]>((acc, t, i) => {
                if (t.type === 'node') acc.push(i);
                return acc;
              }, []);
              if (fromIndex < nodeTabIndices.length && toIndex < nodeTabIndices.length) {
                handleReorderTabsB(nodeTabIndices[fromIndex], nodeTabIndices[toIndex]);
              }
            } : (fromIndex: number, toIndex: number) => {
              const nodeTabIndices = state.tabs.reduce<number[]>((acc, t, i) => {
                if (t.type === 'node') acc.push(i);
                return acc;
              }, []);
              if (fromIndex < nodeTabIndices.length && toIndex < nodeTabIndices.length) {
                handleReorderTabsC(nodeTabIndices[fromIndex], nodeTabIndices[toIndex]);
              }
            }}
            refreshTrigger={focusPanelRefresh}
            onOpenInOtherSlot={(nodeId) => openNodeFromSlot(nodeId, slot)}
            onTextSelect={(nodeId, nodeTitle, text) => {
              setHighlightedPassage({ nodeId, nodeTitle, selectedText: text });
            }}
            highlightedPassage={highlightedPassage}
          />
        );
      }

      case 'map':
        return (
          <MapPane
            slot={slot}
            isActive={isActive}
            onPaneAction={slot === 'A' ? handleSlotAAction : slot === 'B' ? handleSlotBAction : handleSlotCAction}
            onCollapse={onCollapse}
            onSwapPanes={handleSwapPanes}
            tabBar={undefined}
            onNodeClick={(nodeId) => openNodeFromSlot(nodeId, slot)}
            focusedNodeId={focusedNodeId}
            onClearFocus={clearMapFocus}
          />
        );

      case 'views':
        return (
          <ViewsPane
            slot={slot}
            isActive={isActive}
            onPaneAction={slot === 'A' ? handleSlotAAction : slot === 'B' ? handleSlotBAction : handleSlotCAction}
            onCollapse={onCollapse}
            onSwapPanes={handleSwapPanes}
            tabBar={undefined}
            onNodeClick={(nodeId) => openNodeFromSlot(nodeId, slot)}
            onNodeOpenInOtherPane={(nodeId) => openNodeFromSlot(nodeId, slot)}
            refreshToken={nodesPanelRefresh}
            pendingNodes={pendingNodes}
            onDismissPending={(id) => setPendingNodes(prev => prev.filter(p => p.id !== id))}
          />
        );

      case 'table':
        return (
          <TablePane
            slot={slot}
            isActive={isActive}
            onPaneAction={slot === 'A' ? handleSlotAAction : slot === 'B' ? handleSlotBAction : handleSlotCAction}
            onCollapse={onCollapse}
            onSwapPanes={handleSwapPanes}
            tabBar={undefined}
            onNodeClick={(nodeId) => openNodeFromSlot(nodeId, slot)}
            refreshToken={nodesPanelRefresh}
          />
        );

      case 'skills':
        return (
          <SkillsPane
            slot={slot}
            isActive={isActive}
            onPaneAction={slot === 'A' ? handleSlotAAction : slot === 'B' ? handleSlotBAction : handleSlotCAction}
            onCollapse={onCollapse}
            onSwapPanes={handleSwapPanes}
            tabBar={undefined}
            focusedSkill={focusedSkill}
            onFocusSkill={(skill) => {
              setFocusedSkill(skill);
              if (CHAT_FEATURE_ENABLED && skill) {
                setChatPanelOpen(true);
              }
            }}
            autoOpenSkillName={autoOpenSkillName}
            onAutoOpenHandled={() => setAutoOpenSkillName(null)}
          />
        );

      default:
        return null;
    }
  };

  const slotStates: Record<SlotId, SlotState | null> = { A: slotA, B: slotB, C: slotC };
  const getSlotContainerStyle = (slot: SlotId) => {
    const state = slotStates[slot];
    const hasContent = Boolean(state && state.tabs.length > 0);
    const weight = getPanelWeight(slot);
    const showsChat = CHAT_FEATURE_ENABLED && chatPanelOpen && chatSlot === slot;

    return {
      flex: `${weight} ${weight} 0`,
      minWidth: 0,
      overflow: 'hidden',
      display: 'flex',
      flexDirection: 'column' as const,
      background: 'var(--rah-bg-surface)',
      borderRadius: '10px',
      border: hasContent || showsChat ? '1px solid transparent' : '1px dashed var(--rah-border)',
      outline: dragOverSlot === slot ? '2px dashed var(--rah-accent-green)' : 'none',
      outlineOffset: '-4px',
      transition: 'outline 0.15s ease, background 0.15s ease',
    };
  };

  const renderExpandedEmptyPanel = (slot: SlotId) => (
    <div style={{ flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column' }}>
      <div
        draggable
        onDragStart={(e) => {
          e.dataTransfer.setData('application/x-rah-pane', slot);
          e.dataTransfer.effectAllowed = 'move';
        }}
        onDragOver={(e) => {
          if (!e.dataTransfer.types.includes('application/x-rah-pane')) return;
          e.preventDefault();
        }}
        onDrop={(e) => {
          e.preventDefault();
          const source = e.dataTransfer.getData('application/x-rah-pane') as SlotId;
          if (source && source !== slot) {
            handleSwapPanes(source, slot);
          }
        }}
        style={{
          minHeight: '48px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '8px 12px',
          cursor: 'grab',
        }}
      >
        <GripVertical size={14} color="var(--rah-text-muted)" />
        <button
          type="button"
          onClick={() => {
            getSlotSetter(slot)(null);
          }}
          title="Clear pane"
          style={{
            width: '28px',
            height: '28px',
            borderRadius: '8px',
            border: '1px solid var(--rah-border-strong)',
            background: 'var(--rah-bg-elevated)',
            color: 'var(--rah-text-secondary)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            cursor: 'pointer',
          }}
        >
          <X size={14} />
        </button>
      </div>
      <div
        style={{
          flex: 1,
          minHeight: 0,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          color: 'var(--rah-text-muted)',
          fontSize: '13px',
        }}
      >
        Select a pane from the nav
      </div>
    </div>
  );

  return (
    <div
      data-rah-app
      style={{
        display: 'flex',
        height: '100vh',
        width: '100vw',
        background: 'var(--rah-bg-base)',
        overflow: 'hidden'
      }}
    >
      {/* Left Toolbar */}
      <LeftToolbar
        onSearchClick={() => setShowSearchModal(true)}
        onAddStuffClick={() => setShowAddStuff(true)}
        onRefreshClick={handleRefreshAll}
        visiblePaneCount={visiblePaneCount as 1 | 2 | 3}
        onVisiblePaneCountChange={setVisiblePaneCount as (count: 1 | 2 | 3) => void}
        onSettingsClick={() => {
          setSettingsInitialTab(undefined);
          setShowSettings(true);
        }}
        onPaneTypeClick={handlePaneTypeClick}
        isExpanded={leftNavExpanded}
        onToggleExpanded={() => setLeftNavExpanded((prev) => !prev)}
        openTabTypes={openTabTypes}
        activeTabType={activeTabType}
        focusedSkill={focusedSkill}
        theme={theme}
        onThemeToggle={toggleTheme}
      />

      <div
        ref={containerRef}
        style={{ flex: 1, display: 'flex', overflow: 'hidden', padding: '8px', gap: '4px', minWidth: 0 }}
      >
        {visibleSlots.flatMap((slot, index) => {
          const state = slotStates[slot];
          const showsChat = CHAT_FEATURE_ENABLED && chatPanelOpen && chatSlot === slot;
          const nextSlot = visibleSlots[index + 1];
          const items: React.ReactNode[] = [];

          items.push(
            <div
              key={`panel-${slot}`}
              ref={(node) => {
                panelRefs.current[slot] = node;
              }}
              onClick={() => {
                if (!showsChat) {
                  setActivePane(slot);
                }
              }}
              onDragOver={(e) => handleSlotDragOver(e, slot)}
              onDragLeave={handleSlotDragLeave}
              onDrop={(e) => handleSlotDrop(e, slot)}
              style={getSlotContainerStyle(slot)}
            >
              {showsChat ? (
                <ChatPanel
                  isOpen={true}
                  isSoloPane={visibleSlots.length === 1}
                  slot={slot}
                  onClose={() => setChatPanelOpen(false)}
                  onOpen={() => setChatPanelOpen(true)}
                  onSwapPanes={handleSwapPanes}
                  openTabsData={openTabsData}
                  activeTabId={activeTab}
                  focusedSkill={focusedSkill}
                  onClearFocusedSkill={() => setFocusedSkill(null)}
                  onNodeClick={(nodeId) => {
                    openNodeFromSlot(nodeId);
                  }}
                  chatMessages={chatMessages as unknown[]}
                  setChatMessages={setChatMessages as React.Dispatch<React.SetStateAction<unknown[]>>}
                  highlightedPassage={highlightedPassage}
                  onClearPassage={() => setHighlightedPassage(null)}
                  onboardingHint={showOnboardingHint ? ONBOARDING_HINT_TEXT : null}
                  onDismissOnboardingHint={showOnboardingHint ? dismissOnboardingHint : undefined}
                />
              ) : state
                ? renderSlotContent(slot, state)
                : renderExpandedEmptyPanel(slot)}
            </div>
          );

          if (nextSlot) {
            items.push(
              <SplitHandle
                key={`split-${slot}-${nextSlot}`}
                onResize={(clientX) => handleResizePanels(slot, nextSlot, clientX)}
                title="Drag to resize panels"
              />
            );
          }

          return items;
        })}
      </div>

      {CHAT_FEATURE_ENABLED && !chatPanelOpen && (
        <ChatPanel
          isOpen={false}
          isSoloPane={false}
          onClose={() => setChatPanelOpen(false)}
          onOpen={() => setChatPanelOpen(true)}
          openTabsData={openTabsData}
          activeTabId={activeTab}
          focusedSkill={focusedSkill}
          onClearFocusedSkill={() => setFocusedSkill(null)}
          onNodeClick={(nodeId) => {
            openNodeFromSlot(nodeId, 'C');
          }}
          chatMessages={chatMessages as unknown[]}
          setChatMessages={setChatMessages as React.Dispatch<React.SetStateAction<unknown[]>>}
          highlightedPassage={highlightedPassage}
          onClearPassage={() => setHighlightedPassage(null)}
          onboardingHint={showOnboardingHint ? ONBOARDING_HINT_TEXT : null}
          onDismissOnboardingHint={showOnboardingHint ? dismissOnboardingHint : undefined}
        />
      )}

      {/* Search Modal */}
      <SearchModal
        isOpen={showSearchModal}
        onClose={() => setShowSearchModal(false)}
        onNodeSelect={handleSearchNodeSelect}
        existingFilters={searchModalFilters}
      />

      {/* Settings Modal */}
      <SettingsModal
        isOpen={showSettings}
        onClose={handleCloseSettings}
        initialTab={settingsInitialTab}
      />

      {/* Add Stuff Modal */}
      <QuickAddInput
        isOpen={showAddStuff}
        onClose={() => setShowAddStuff(false)}
        onSubmit={handleQuickAddSubmit}
      />
    </div>
  );
}
