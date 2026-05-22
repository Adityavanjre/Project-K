"use client";

import { useState } from 'react';
import PaneHeader from './PaneHeader';
import DatabaseTableView from '../views/DatabaseTableView';
import type { BasePaneProps } from './types';

export interface TablePaneProps extends BasePaneProps {
  onNodeClick: (nodeId: number) => void;
  refreshToken?: number;
}

export default function TablePane({
  slot,
  isActive,
  onPaneAction,
  onCollapse,
  onSwapPanes,
  tabBar,
  onNodeClick,
  refreshToken
}: TablePaneProps) {
  const [toolbarHost, setToolbarHost] = useState<HTMLDivElement | null>(null);
  return (
    <div style={{
      display: 'flex',
      flexDirection: 'column',
      height: '100%',
      background: 'transparent',
      overflow: 'hidden'
    }}>
      <PaneHeader
        slot={slot}
        onCollapse={onCollapse}
        onSwapPanes={onSwapPanes}
        tabBar={tabBar}
        toolbarHostRef={setToolbarHost}
      />
      <div style={{ flex: 1, overflow: 'hidden' }}>
        <DatabaseTableView
          onNodeClick={onNodeClick}
          refreshToken={refreshToken}
          toolbarHost={toolbarHost}
        />
      </div>
    </div>
  );
}
