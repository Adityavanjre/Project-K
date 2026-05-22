"use client";

import { useState } from 'react';
import PaneHeader from './PaneHeader';
import ViewsOverlay from '../views/ViewsOverlay';
import type { BasePaneProps, PaneAction, PaneType } from './types';
import type { PendingNode } from '../layout/ThreePanelLayout';

export interface ViewsPaneProps extends BasePaneProps {
  onNodeClick: (nodeId: number) => void;
  onNodeOpenInOtherPane?: (nodeId: number) => void;
  refreshToken?: number;
  pendingNodes?: PendingNode[];
  onDismissPending?: (id: string) => void;
}

export default function ViewsPane({
  slot,
  isActive,
  onPaneAction,
  onCollapse,
  onSwapPanes,
  tabBar,
  onNodeClick,
  onNodeOpenInOtherPane,
  refreshToken,
  pendingNodes,
  onDismissPending,
}: ViewsPaneProps) {
  const [toolbarHost, setToolbarHost] = useState<HTMLDivElement | null>(null);

  const handleTypeChange = (type: PaneType) => {
    onPaneAction?.({ type: 'switch-pane-type', paneType: type });
  };

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
        <ViewsOverlay
          onNodeClick={onNodeClick}
          onNodeOpenInOtherPane={onNodeOpenInOtherPane}
          refreshToken={refreshToken}
          pendingNodes={pendingNodes}
          onDismissPending={onDismissPending}
          toolbarHost={toolbarHost}
        />
      </div>
    </div>
  );
}
