"use client";

import { useState, type ReactNode } from 'react';
import {
  Search,
  Plus,
  RefreshCw,
  LayoutList,
  Map,
  ChevronDown,
  ChevronRight,
  Table2,
  BookOpen,
  Settings,
  PanelLeftClose,
  PanelLeftOpen,
  Sun,
  Moon,
} from 'lucide-react';
import type { PaneType } from '../panes/types';
import type { FocusedSkill } from '@/types/skills';
import type { Theme } from '@/hooks/useTheme';

interface LeftToolbarProps {
  onSearchClick: () => void;
  onAddStuffClick: () => void;
  onRefreshClick: () => void;
  visiblePaneCount: 1 | 2 | 3;
  onVisiblePaneCountChange: (count: 1 | 2 | 3) => void;
  onSettingsClick: () => void;
  onPaneTypeClick: (paneType: PaneType) => void;
  isExpanded: boolean;
  onToggleExpanded: () => void;
  openTabTypes: Set<PaneType>;
  activeTabType: PaneType | null;
  focusedSkill?: FocusedSkill | null;
  theme: Theme;
  onThemeToggle: () => void;
}

const NAV_WIDTH_COLLAPSED = 50;
const NAV_WIDTH_EXPANDED = 280;

const PRIMARY_VIEW_ITEMS: Array<{ paneType: PaneType; label: string; icon: typeof LayoutList }> = [
  { paneType: 'views', label: 'Nodes', icon: LayoutList },
  { paneType: 'skills', label: 'Skills', icon: BookOpen },
  { paneType: 'map', label: 'Map', icon: Map },
  { paneType: 'table', label: 'Table', icon: Table2 },
];

function NavButton({
  icon: Icon,
  label,
  expanded,
  active,
  onClick,
  trailing,
  activeTone = 'neutral',
  title,
}: {
  icon: typeof Search;
  label: string;
  expanded: boolean;
  active?: boolean;
  onClick: () => void;
  trailing?: ReactNode;
  activeTone?: 'neutral' | 'green';
  title?: string;
}) {
  const [hovered, setHovered] = useState(false);
  const activeColor = activeTone === 'green' ? 'var(--rah-accent-green)' : 'var(--rah-text-active)';

  return (
    <button
      onClick={onClick}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      title={title ?? (expanded ? undefined : label)}
      style={{
        width: '100%',
        height: '36px',
        borderRadius: '8px',
        border: 'none',
        background: active ? 'var(--rah-bg-hover)' : (hovered ? 'var(--rah-bg-subtle)' : 'transparent'),
        color: active ? activeColor : (hovered ? 'var(--rah-text-secondary)' : 'var(--rah-text-muted)'),
        cursor: 'pointer',
        display: 'flex',
        alignItems: 'center',
        justifyContent: expanded ? 'space-between' : 'center',
        gap: '10px',
        padding: expanded ? '0 10px' : '0',
        transition: 'all 0.15s ease',
      }}
    >
      <span style={{ display: 'flex', alignItems: 'center', gap: '10px', minWidth: 0 }}>
        <Icon size={18} />
        {expanded ? (
          <span style={{ fontSize: '13px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
            {label}
          </span>
        ) : null}
      </span>
      {expanded ? trailing : null}
    </button>
  );
}

export default function LeftToolbar({
  onSearchClick,
  onAddStuffClick,
  onRefreshClick,
  visiblePaneCount,
  onVisiblePaneCountChange,
  onSettingsClick,
  onPaneTypeClick,
  isExpanded,
  onToggleExpanded,
  openTabTypes,
  activeTabType,
  focusedSkill,
  theme,
  onThemeToggle,
}: LeftToolbarProps) {
  const [paneSelectorOpen, setPaneSelectorOpen] = useState(false);

  const renderPaneGlyph = (count: 1 | 2 | 3, active: boolean) => (
    <span style={{ display: 'flex', width: '100%', gap: '3px', height: '12px', maxWidth: '24px' }}>
      {Array.from({ length: count }).map((_, index) => (
        <span
          key={`${count}-${index}`}
          style={{
            flex: 1,
            borderRadius: '3px',
            background: active ? 'var(--rah-text-active)' : 'var(--rah-text-muted)',
            opacity: active ? 1 : 0.7,
          }}
        />
      ))}
    </span>
  );

  const renderPaneCountButton = (count: 1 | 2 | 3) => {
    const active = visiblePaneCount === count;

    return (
      <button
        key={count}
        type="button"
        onClick={() => {
          onVisiblePaneCountChange(count);
          setPaneSelectorOpen(false);
        }}
        title={`${count} pane${count === 1 ? '' : 's'}`}
        style={{
          width: isExpanded ? '100%' : '36px',
          height: '30px',
          borderRadius: '8px',
          border: `1px solid ${active ? 'var(--rah-border-stronger)' : 'var(--rah-border)'}`,
          background: active ? 'var(--rah-bg-hover)' : 'transparent',
          display: 'flex',
          alignItems: 'center',
          justifyContent: isExpanded ? 'space-between' : 'center',
          cursor: 'pointer',
          padding: isExpanded ? '0 8px' : '0 6px',
          transition: 'all 0.15s ease',
          alignSelf: isExpanded ? 'stretch' : 'center',
        }}
      >
        {renderPaneGlyph(count, active)}
        {isExpanded ? (
          <span style={{ fontSize: '11px', color: active ? 'var(--rah-text-active)' : 'var(--rah-text-muted)' }}>
            {count} pane{count === 1 ? '' : 's'}
          </span>
        ) : null}
      </button>
    );
  };

  const renderPaneSelector = () => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
      <button
        type="button"
        onClick={() => setPaneSelectorOpen((prev) => !prev)}
        title={isExpanded ? undefined : 'Pane layout'}
        style={{
          width: '100%',
          height: '36px',
          borderRadius: '10px',
          border: '1px solid var(--rah-border-stronger)',
          background: paneSelectorOpen ? 'var(--rah-bg-hover)' : 'var(--rah-bg-elevated)',
          color: 'var(--rah-text-active)',
          cursor: 'pointer',
          display: 'flex',
          alignItems: 'center',
          justifyContent: isExpanded ? 'space-between' : 'center',
          padding: isExpanded ? '0 10px' : '0',
          transition: 'all 0.15s ease',
          boxShadow: paneSelectorOpen ? '0 0 0 1px color-mix(in srgb, var(--rah-text-active) 8%, transparent)' : 'none',
        }}
      >
        <span style={{ display: 'flex', alignItems: 'center', gap: '10px', minWidth: 0 }}>
          <span
            style={{
              width: '18px',
              display: 'inline-flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'var(--rah-text-active)',
              opacity: 0.98,
              flexShrink: 0,
            }}
          >
            {renderPaneGlyph(visiblePaneCount, true)}
          </span>
          {isExpanded ? (
            <span style={{ fontSize: '13px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
              Layout
            </span>
          ) : null}
        </span>
        {isExpanded ? (
          paneSelectorOpen ? <ChevronDown size={16} /> : <ChevronRight size={16} />
        ) : null}
      </button>

      {paneSelectorOpen ? (
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            gap: '4px',
            alignItems: 'center',
          }}
        >
          {([1, 2, 3] as const).map((count) => renderPaneCountButton(count))}
        </div>
      ) : null}
    </div>
  );

  const renderActionButtons = () => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
      <NavButton icon={Search} label="Search" title="Search (⌘K)" expanded={isExpanded} onClick={onSearchClick} />
      <NavButton icon={Plus} label="Add Stuff" title="New node (⌘N)" expanded={isExpanded} onClick={onAddStuffClick} />
      <NavButton icon={RefreshCw} label="Refresh" expanded={isExpanded} onClick={onRefreshClick} />
    </div>
  );

  return (
    <div
      style={{
        width: isExpanded ? `${NAV_WIDTH_EXPANDED}px` : `${NAV_WIDTH_COLLAPSED}px`,
        height: '100%',
        background: 'transparent',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        padding: '12px 8px',
        flexShrink: 0,
        transition: 'width 0.2s ease',
        overflow: 'hidden',
      }}
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', height: '100%' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
          <NavButton
            icon={isExpanded ? PanelLeftClose : PanelLeftOpen}
            label={isExpanded ? 'Collapse' : 'Expand'}
            expanded={isExpanded}
            onClick={onToggleExpanded}
          />

          {renderPaneSelector()}

          <div style={{ marginTop: '8px' }}>
          {renderActionButtons()}
          </div>
        </div>

        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', minHeight: 0 }}>
          <div style={{ borderTop: '1px solid var(--rah-border)', paddingTop: '14px' }}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '4px', paddingTop: '4px' }}>
              {PRIMARY_VIEW_ITEMS.map((item) => (
                <NavButton
                  key={`${item.paneType}-${item.label}`}
                  icon={item.icon}
                  label={item.label}
                  expanded={isExpanded}
                  active={
                    item.paneType === 'skills'
                      ? focusedSkill != null || activeTabType === 'skills' || openTabTypes.has('skills')
                      : activeTabType === item.paneType || openTabTypes.has(item.paneType)
                  }
                  onClick={() => onPaneTypeClick(item.paneType)}
                  activeTone="green"
                />
              ))}
            </div>
          </div>
        </div>
      </div>

      <div style={{ borderTop: '1px solid var(--rah-border)', paddingTop: '8px' }}>
        <NavButton
          icon={theme === 'dark' ? Sun : Moon}
          label={theme === 'dark' ? 'Light Mode' : 'Dark Mode'}
          expanded={isExpanded}
          onClick={onThemeToggle}
        />
        <NavButton icon={Settings} label="Settings" expanded={isExpanded} onClick={onSettingsClick} />
      </div>
    </div>
  );
}
