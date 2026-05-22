"use client";

import { useEffect, useRef, useState, type DragEvent } from 'react';
import { Trash2, Loader, Database, RefreshCw, Pencil, X, Save, Plus, Link2, Tag, Share2, AlignLeft, ChevronDown, ChevronRight, Check } from 'lucide-react';
import { parseAndRenderContent } from '@/components/helpers/NodeLabelRenderer';
import { Node, NodeConnection } from '@/types/database';
import { getNodeIcon } from '@/utils/nodeIcons';
import ConfirmDialog from '../common/ConfirmDialog';
import { SourceReader } from './source';
import SourceEditor from './source/SourceEditor';
import { openExternalUrl, shouldOpenExternally } from '@/utils/openExternalUrl';
import { normalizeNodeLink } from '@/utils/nodeLink';
import NodeSearchModal from './edges/NodeSearchModal';
import { getNodeProcessedState, parseNodeMetadata } from '@/services/nodes/metadata';

interface FocusPanelProps {
  openTabs: number[];
  activeTab: number | null;
  onTabSelect: (nodeId: number) => void;
  onNodeClick?: (nodeId: number) => void;
  onOpenInMap?: () => void;
  onTabClose: (nodeId: number) => void;
  refreshTrigger?: number;
  onTextSelect?: (nodeId: number, nodeTitle: string, text: string) => void;
  highlightedPassage?: { nodeId: number; selectedText: string } | null;
}

type HoverSection = 'description' | 'source' | null;

export default function FocusPanel({
  openTabs,
  activeTab,
  onTabSelect,
  onNodeClick,
  onOpenInMap,
  onTabClose,
  refreshTrigger,
  onTextSelect,
  highlightedPassage,
}: FocusPanelProps) {
  const [nodesData, setNodesData] = useState<Record<number, Node>>({});
  const [edgesData, setEdgesData] = useState<Record<number, NodeConnection[]>>({});
  const [loadingNodes, setLoadingNodes] = useState<Set<number>>(new Set());
  const [loadingEdges, setLoadingEdges] = useState<Set<number>>(new Set());
  const [embeddingNode, setEmbeddingNode] = useState<number | null>(null);
  const [deletingNode, setDeletingNode] = useState<number | null>(null);
  const [pendingDeleteNodeId, setPendingDeleteNodeId] = useState<number | null>(null);
  const [deletingEdge, setDeletingEdge] = useState<number | null>(null);
  const [edgeEditingId, setEdgeEditingId] = useState<number | null>(null);
  const [edgeEditingValue, setEdgeEditingValue] = useState('');
  const [edgeSavingId, setEdgeSavingId] = useState<number | null>(null);
  const [edgesExpanded, setEdgesExpanded] = useState<Record<number, boolean>>({});
  const [edgeSearchOpen, setEdgeSearchOpen] = useState(false);
  const [hoveredConnectionId, setHoveredConnectionId] = useState<number | null>(null);
  const [metadataCollapsed, setMetadataCollapsed] = useState(true);

  const [titleEditMode, setTitleEditMode] = useState(false);
  const [titleEditValue, setTitleEditValue] = useState('');
  const [titleSaving, setTitleSaving] = useState(false);
  const [linkEditMode, setLinkEditMode] = useState(false);
  const [linkEditValue, setLinkEditValue] = useState('');
  const [linkSaving, setLinkSaving] = useState(false);
  const [descEditMode, setDescEditMode] = useState(false);
  const [descEditValue, setDescEditValue] = useState('');
  const [descSaving, setDescSaving] = useState(false);
  const [regeneratingDescription, setRegeneratingDescription] = useState<number | null>(null);
  const [sourceEditMode, setSourceEditMode] = useState(false);
  const [sourceEditValue, setSourceEditValue] = useState('');
  const [sourceSaving, setSourceSaving] = useState(false);
  const [hoveredSection, setHoveredSection] = useState<HoverSection>(null);

  const titleInputRef = useRef<HTMLInputElement>(null);
  const linkInputRef = useRef<HTMLInputElement>(null);
  const descTextareaRef = useRef<HTMLTextAreaElement>(null);
  const sourceTextareaRef = useRef<HTMLTextAreaElement>(null);
  const skipTitleBlurRef = useRef(false);
  const skipLinkBlurRef = useRef(false);

  const currentNode = activeTab !== null ? nodesData[activeTab] : undefined;
  const normalizedCurrentLink = normalizeNodeLink(currentNode?.link || null);
  const currentProcessedState = getNodeProcessedState(currentNode?.metadata);
  const currentNodeMetadata = parseNodeMetadata(currentNode?.metadata);
  const currentEdges = activeTab !== null ? edgesData[activeTab] || [] : [];
  const currentEdgesExpanded = activeTab !== null ? Boolean(edgesExpanded[activeTab]) : false;
  const visibleEdges = currentEdgesExpanded ? currentEdges : currentEdges.slice(0, 3);

  useEffect(() => {
    if (titleEditMode) titleInputRef.current?.focus();
  }, [titleEditMode]);

  useEffect(() => {
    if (linkEditMode) linkInputRef.current?.focus();
  }, [linkEditMode]);

  useEffect(() => {
    if (descEditMode) descTextareaRef.current?.focus();
  }, [descEditMode]);

  useEffect(() => {
    if (sourceEditMode) sourceTextareaRef.current?.focus();
  }, [sourceEditMode]);

  useEffect(() => {
    openTabs.forEach((tabId) => {
      if (!nodesData[tabId] && !loadingNodes.has(tabId)) {
        void fetchNodeData(tabId);
      }
    });
  }, [openTabs, nodesData, loadingNodes]);

  useEffect(() => {
    openTabs.forEach((tabId) => {
      if (nodesData[tabId] && !edgesData[tabId] && !loadingEdges.has(tabId)) {
        void fetchEdgesData(tabId);
      }
    });
  }, [openTabs, nodesData, edgesData, loadingEdges]);

  useEffect(() => {
    if (refreshTrigger !== undefined && refreshTrigger > 0 && activeTab) {
      void fetchNodeData(activeTab);
      void fetchEdgesData(activeTab);
    }
  }, [refreshTrigger, activeTab]);

  useEffect(() => {
    setTitleEditMode(false);
    setTitleEditValue('');
    setLinkEditMode(false);
    setLinkEditValue('');
    setDescEditMode(false);
    setDescEditValue('');
    setSourceEditMode(false);
    setSourceEditValue('');
    setEdgeSearchOpen(false);
    setEdgeEditingId(null);
    setEdgeEditingValue('');
    setHoveredSection(null);
    setMetadataCollapsed(true);
  }, [activeTab]);

  const fetchNodeData = async (id: number) => {
    setLoadingNodes(prev => new Set(prev).add(id));
    try {
      const response = await fetch(`/api/nodes/${id}`);
      if (response.status === 404) {
        setNodesData(prev => {
          const next = { ...prev };
          delete next[id];
          return next;
        });
        setEdgesData(prev => {
          const next = { ...prev };
          delete next[id];
          return next;
        });
        onTabClose(id);
        return;
      }
      const data = await response.json();
      if (response.ok && data.node) {
        setNodesData(prev => ({ ...prev, [id]: data.node }));
      }
    } catch (error) {
      console.warn(`Failed to fetch node ${id}:`, error);
    } finally {
      setLoadingNodes(prev => {
        const next = new Set(prev);
        next.delete(id);
        return next;
      });
    }
  };

  const fetchEdgesData = async (nodeId: number) => {
    setLoadingEdges(prev => new Set(prev).add(nodeId));
    try {
      const response = await fetch(`/api/nodes/${nodeId}/edges`);
      const data = await response.json();
      if (response.ok && data.success && data.data) {
        setEdgesData(prev => ({ ...prev, [nodeId]: data.data }));
      }
    } catch (error) {
      console.error(`Error fetching edges for node ${nodeId}:`, error);
    } finally {
      setLoadingEdges(prev => {
        const next = new Set(prev);
        next.delete(nodeId);
        return next;
      });
    }
  };

  const updateNode = async (nodeId: number, updates: Record<string, unknown>) => {
    const response = await fetch(`/api/nodes/${nodeId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(updates),
    });

    if (!response.ok) {
      throw new Error('Failed to update node');
    }

    const result = await response.json();
    if (result.node) {
      setNodesData(prev => ({ ...prev, [nodeId]: result.node }));
      return result.node as Node;
    }

    throw new Error('Missing updated node in response');
  };

  const renderMetadataSection = () => {
    const metadataEntries = Object.entries(currentNodeMetadata).filter(([, value]) => value !== undefined);
    const rawJson = metadataEntries.length > 0 ? JSON.stringify(currentNodeMetadata, null, 2) : '';

    return (
      <section style={{ ...S.section, minWidth: 0, width: '100%', overflow: 'hidden' }}>
        <div style={S.sectionHeader}>
          <button
            type="button"
            className="metadata-toggle"
            onClick={() => setMetadataCollapsed((current) => !current)}
            aria-expanded={!metadataCollapsed}
          >
            {metadataCollapsed ? <ChevronRight size={12} /> : <ChevronDown size={12} />}
            <span style={S.sectionLabel}>Metadata</span>
          </button>
          <div style={S.sectionRule} />
        </div>

        {metadataCollapsed ? null : metadataEntries.length === 0 ? (
          <div style={{ color: 'var(--rah-text-muted)', fontSize: '12px', fontStyle: 'italic' }}>
            No metadata stored for this node.
          </div>
        ) : (
          <div className="metadata-group">
            <div className="metadata-group-label">raw</div>
            <pre className="metadata-raw">{rawJson}</pre>
          </div>
        )}
      </section>
    );
  };

  const startTitleEdit = () => {
    if (!currentNode) return;
    setTitleEditValue(currentNode.title || '');
    setTitleEditMode(true);
  };

  const saveTitle = async () => {
    if (!activeTab) return;
    const nextTitle = titleEditValue.trim();
    if (!nextTitle) {
      window.alert('Title cannot be empty');
      return;
    }

    setTitleSaving(true);
    try {
      await updateNode(activeTab, { title: nextTitle });
      setTitleEditMode(false);
      setTitleEditValue('');
    } catch (error) {
      console.error('Error saving title:', error);
      window.alert('Failed to save title. Please try again.');
    } finally {
      setTitleSaving(false);
    }
  };

  const startLinkEdit = () => {
    setLinkEditValue(currentNode?.link || '');
    setLinkEditMode(true);
  };

  const saveLink = async () => {
    if (!activeTab) return;
    setLinkSaving(true);
    try {
      await updateNode(activeTab, { link: linkEditValue.trim() || null });
      setLinkEditMode(false);
      setLinkEditValue('');
    } catch (error) {
      console.error('Error saving link:', error);
      window.alert('Failed to save URL. Please try again.');
    } finally {
      setLinkSaving(false);
    }
  };

  const startDescEdit = () => {
    setDescEditValue(currentNode?.description || '');
    setDescEditMode(true);
  };

  const saveDesc = async () => {
    if (!activeTab) return;
    setDescSaving(true);
    try {
      await updateNode(activeTab, { description: descEditValue });
      setDescEditMode(false);
      setDescEditValue('');
    } catch (error) {
      console.error('Error saving description:', error);
      window.alert('Failed to save description. Please try again.');
    } finally {
      setDescSaving(false);
    }
  };

  const regenerateDescription = async (nodeId: number) => {
    setRegeneratingDescription(nodeId);
    try {
      const response = await fetch(`/api/nodes/${nodeId}/regenerate-description`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      });

      if (!response.ok) {
        throw new Error('Failed to regenerate description');
      }

      const result = await response.json();
      if (result.node) {
        setNodesData(prev => ({ ...prev, [nodeId]: result.node }));
      }
    } catch (error) {
      console.error('Error regenerating description:', error);
      window.alert('Failed to regenerate description. Please try again.');
    } finally {
      setRegeneratingDescription(null);
    }
  };

  const startSourceEdit = () => {
    setSourceEditValue(currentNode?.source || '');
    setSourceEditMode(true);
  };

  const saveSource = async () => {
    if (!activeTab) return;
    setSourceSaving(true);
    try {
      await updateNode(activeTab, { source: sourceEditValue });
      setSourceEditMode(false);
      setSourceEditValue('');
    } catch (error) {
      console.error('Error saving source:', error);
      window.alert('Failed to save source. Please try again.');
    } finally {
      setSourceSaving(false);
    }
  };

  const embedContent = async (nodeId: number) => {
    setEmbeddingNode(nodeId);
    try {
      const response = await fetch('/api/ingestion', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ nodeId }),
      });

      const result = await response.json();
      if (!response.ok) {
        throw new Error(result.error || 'Failed to embed content');
      }

      await fetchNodeData(nodeId);
    } catch (error) {
      console.error('Error embedding content:', error);
      window.alert(`Failed to embed content: ${error instanceof Error ? error.message : 'Unknown error'}`);
    } finally {
      setEmbeddingNode(null);
    }
  };

  const createEdgeWithExplanation = async (targetNodeId: number, explanation: string) => {
    if (activeTab === null) return;
    try {
      const response = await fetch('/api/edges', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          from_node_id: activeTab,
          to_node_id: targetNodeId,
          source: 'user',
          explanation: explanation || '',
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to create edge');
      }

      await fetchEdgesData(activeTab);
    } catch (error) {
      console.error('Error creating edge:', error);
      window.alert('Failed to create connection. Please try again.');
      throw error;
    }
  };

  const startEditEdgeExplanation = (edgeId: number, currentExplanation?: string) => {
    setEdgeEditingId(edgeId);
    setEdgeEditingValue(currentExplanation || '');
  };

  const cancelEditEdgeExplanation = () => {
    setEdgeEditingId(null);
    setEdgeEditingValue('');
  };

  const saveEdgeExplanation = async (
    edgeId: number,
    currentContext: Record<string, unknown> | null | undefined
  ) => {
    if (activeTab === null) return;
    setEdgeSavingId(edgeId);
    try {
      const response = await fetch(`/api/edges/${edgeId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          context: {
            ...(currentContext ?? {}),
            explanation: edgeEditingValue,
          },
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to update edge');
      }

      await fetchEdgesData(activeTab);
      cancelEditEdgeExplanation();
    } catch (error) {
      console.error('Failed updating edge explanation:', error);
      window.alert('Failed to update connection explanation.');
    } finally {
      setEdgeSavingId(null);
    }
  };

  const deleteEdge = async (edgeId: number) => {
    if (activeTab === null) return;
    setDeletingEdge(edgeId);
    try {
      const response = await fetch(`/api/edges/${edgeId}`, {
        method: 'DELETE',
      });

      if (!response.ok) {
        throw new Error('Failed to delete edge');
      }

      await fetchEdgesData(activeTab);
    } catch (error) {
      console.error('Error deleting edge:', error);
      window.alert('Failed to delete connection. Please try again.');
    } finally {
      setDeletingEdge(null);
    }
  };

  const executeDeleteNode = async (nodeId: number) => {
    setDeletingNode(nodeId);
    try {
      const response = await fetch(`/api/nodes/${nodeId}`, {
        method: 'DELETE',
      });

      if (!response.ok) {
        throw new Error('Failed to delete node');
      }

      onTabClose(nodeId);
      setNodesData(prev => {
        const next = { ...prev };
        delete next[nodeId];
        return next;
      });
    } catch (error) {
      console.error('Error deleting node:', error);
      window.alert('Failed to delete node. Please try again.');
    } finally {
      setDeletingNode(null);
    }
  };

  const renderStatusIndicator = () => {
    if (!currentNode || activeTab === null) return null;

    const chunkStatus = currentNode.chunk_status ?? null;
    if (embeddingNode === activeTab || chunkStatus === 'chunking') {
      return <Loader size={12} className="animate-spin" style={{ color: '#facc15', flexShrink: 0 }} />;
    }

    if (chunkStatus === 'error') {
      return (
        <button
          onClick={() => void embedContent(activeTab)}
          className="status-button"
          title="Embedding failed - click to retry"
        >
          <Database size={10} />
          Retry
        </button>
      );
    }

    if (chunkStatus === 'not_chunked') {
      return (
        <span className="status-chip" title="Source changed and is queued for embedding">
          Pending embed
        </span>
      );
    }

    return null;
  };

  // ── Shared inline style constants (styled-jsx doesn't apply inside helper fns) ──
  const S = {
    section: {
      display: 'flex' as const,
      flexDirection: 'column' as const,
      gap: '10px',
      paddingTop: '18px',
      marginTop: '4px',
    },
    sectionHeader: {
      display: 'flex' as const,
      alignItems: 'center' as const,
      gap: '10px',
      marginBottom: '2px',
    },
    sectionLabel: {
      fontSize: '9.5px',
      letterSpacing: '0.1em',
      textTransform: 'uppercase' as const,
      color: 'var(--rah-text-muted)',
      fontWeight: 600,
      flexShrink: 0,
    },
    sectionRule: {
      flex: 1,
      height: '1px',
      background: 'var(--rah-border)',
    },
    iconBtn: {
      display: 'inline-flex' as const,
      alignItems: 'center' as const,
      justifyContent: 'center' as const,
      width: '22px',
      height: '22px',
      background: 'transparent',
      border: '1px solid transparent',
      borderRadius: '5px',
      color: 'var(--rah-text-muted)',
      cursor: 'pointer',
      padding: 0,
    },
    editorBlock: {
      display: 'flex' as const,
      flexDirection: 'column' as const,
      gap: '10px',
    },
    textarea: {
      display: 'block' as const,
      width: '100%',
      boxSizing: 'border-box' as const,
      background: 'var(--rah-bg-surface)',
      border: '1px solid var(--rah-border-strong)',
      borderRadius: '8px',
      color: 'var(--rah-text-base)',
      fontFamily: 'inherit',
      outline: 'none',
      padding: '12px',
    },
    editorActions: {
      display: 'flex' as const,
      justifyContent: 'flex-end' as const,
      gap: '8px',
    },
    primaryBtn: {
      display: 'inline-flex' as const,
      alignItems: 'center' as const,
      gap: '5px',
      padding: '6px 12px',
      border: 'none',
      background: 'var(--rah-accent-green)',
      color: 'var(--rah-text-inverse)',
      fontSize: '11px',
      fontWeight: 600,
      borderRadius: '6px',
      cursor: 'pointer',
      fontFamily: 'inherit',
    },
    secondaryBtn: {
      display: 'inline-flex' as const,
      alignItems: 'center' as const,
      gap: '5px',
      padding: '6px 12px',
      border: '1px solid var(--rah-border-strong)',
      background: 'transparent',
      color: 'var(--rah-text-soft)',
      fontSize: '11px',
      borderRadius: '6px',
      cursor: 'pointer',
      fontFamily: 'inherit',
    },
  };

  const renderDescriptionSection = () => (
    <section
      style={S.section}
      onMouseEnter={() => setHoveredSection('description')}
      onMouseLeave={() => setHoveredSection(prev => prev === 'description' ? null : prev)}
    >
      {/* Section header with extending rule */}
      <div style={S.sectionHeader}>
        <span style={S.sectionLabel}>Description</span>
        <div style={S.sectionRule} />
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', opacity: hoveredSection === 'description' || descEditMode ? 1 : 0, transition: 'opacity 150ms ease' }}>
          {!descEditMode && (
            <>
              <button type="button" style={S.iconBtn} onClick={startDescEdit} title="Edit">
                <Pencil size={11} />
              </button>
              {activeTab !== null && (
                <button
                  type="button"
                  style={S.iconBtn}
                  onClick={() => void regenerateDescription(activeTab)}
                  disabled={regeneratingDescription === activeTab}
                  title="Regenerate"
                >
                  {regeneratingDescription === activeTab
                    ? <Loader size={11} className="animate-spin" />
                    : <RefreshCw size={11} />}
                </button>
              )}
            </>
          )}
        </div>
      </div>

      {descEditMode ? (
        <div style={S.editorBlock}>
          <textarea
            ref={descTextareaRef}
            value={descEditValue}
            onChange={(e) => setDescEditValue(e.target.value)}
            onKeyDown={(e) => {
              if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') { e.preventDefault(); void saveDesc(); }
              if (e.key === 'Escape') { e.preventDefault(); setDescEditMode(false); setDescEditValue(''); }
            }}
            disabled={descSaving}
            style={{ ...S.textarea, minHeight: '90px', lineHeight: '1.6', fontSize: '13.5px' }}
            rows={4}
            placeholder="Add a concise description..."
          />
          <div style={S.editorActions}>
            <button type="button" style={S.secondaryBtn} onClick={() => { setDescEditMode(false); setDescEditValue(''); }} disabled={descSaving}>
              <X size={13} /> Cancel
            </button>
            <button type="button" style={S.primaryBtn} onClick={() => void saveDesc()} disabled={descSaving}>
              {descSaving ? <Loader size={13} className="animate-spin" /> : <Save size={13} />} Save
            </button>
          </div>
        </div>
      ) : (
        <div
          onClick={startDescEdit}
          style={{ color: 'var(--rah-text-base)', fontSize: '13.5px', lineHeight: '1.65', cursor: 'text' }}
        >
          {currentNode?.description
            ? parseAndRenderContent(currentNode.description, onNodeClick || onTabSelect)
            : <span style={{ color: 'var(--rah-text-muted)', fontStyle: 'italic' }}>Add a description...</span>}
        </div>
      )}
    </section>
  );

  const renderConnectionsSection = () => (
    <section style={S.section}>
      {/* Section header */}
      <div style={S.sectionHeader}>
        <span style={S.sectionLabel}>Connections</span>
        <div style={S.sectionRule} />
      </div>

      {loadingEdges.has(activeTab ?? -1) ? (
        <span style={{ color: 'var(--rah-text-muted)', fontSize: '12px' }}>Loading…</span>
      ) : currentEdges.length === 0 ? (
        <button
          type="button"
          onClick={() => setEdgeSearchOpen(true)}
          style={{
            display: 'inline-flex', alignItems: 'center', gap: '6px',
            alignSelf: 'flex-start',
            background: 'transparent',
            border: '1px dashed var(--rah-border-strong)',
            borderRadius: '8px',
            color: 'var(--rah-text-muted)',
            fontSize: '12px',
            fontFamily: 'inherit',
            cursor: 'pointer',
            padding: '7px 12px',
          }}
        >
          <Plus size={13} />
          Add connection
        </button>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column' }}>
          {visibleEdges.map((connection) => {
            const isOutgoing = connection.edge.from_node_id === activeTab;
            const explanation = typeof connection.edge.context?.explanation === 'string'
              ? connection.edge.context.explanation
              : '';
            const isHovered = hoveredConnectionId === connection.id;

            return (
              <div
                key={connection.id}
                onMouseEnter={() => setHoveredConnectionId(connection.id)}
                onMouseLeave={() => setHoveredConnectionId(null)}
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '2px',
                  padding: '6px 8px',
                  borderRadius: '6px',
                  background: isHovered ? 'var(--rah-bg-hover)' : 'transparent',
                  transition: 'background 120ms ease',
                  margin: '0 -8px',
                }}
              >
                {/* Title row */}
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', minWidth: 0 }}>
                  <span style={{
                    fontSize: '11px',
                    color: isOutgoing ? 'var(--rah-accent-green)' : '#f59e0b',
                    flexShrink: 0,
                    width: '12px',
                    textAlign: 'center',
                  }}>
                    {isOutgoing ? '↗' : '↙'}
                  </span>
                  <span style={{ display: 'inline-flex', alignItems: 'center', flexShrink: 0 }}>
                    {getNodeIcon(connection.connected_node, 12)}
                  </span>
                  <button
                    type="button"
                    onClick={() => (onNodeClick || onTabSelect)(connection.connected_node.id)}
                    title={connection.connected_node.title}
                    style={{
                      flex: 1,
                      minWidth: 0,
                      background: 'transparent',
                      border: 'none',
                      padding: 0,
                      color: 'var(--rah-text-base)',
                      fontSize: '13px',
                      fontWeight: 500,
                      textAlign: 'left',
                      cursor: 'pointer',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                      whiteSpace: 'nowrap',
                      fontFamily: 'inherit',
                    }}
                  >
                    {connection.connected_node.title}
                  </button>
                  <button
                    type="button"
                    onClick={() => void deleteEdge(connection.edge.id)}
                    disabled={deletingEdge === connection.edge.id}
                    title="Remove"
                    style={{
                      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
                      background: 'transparent',
                      border: 'none',
                      color: 'var(--rah-text-muted)',
                      cursor: 'pointer',
                      padding: '2px',
                      borderRadius: '4px',
                      flexShrink: 0,
                      opacity: isHovered ? 1 : 0,
                      transition: 'opacity 120ms ease, color 120ms ease',
                    }}
                  >
                    {deletingEdge === connection.edge.id ? '…' : <Trash2 size={11} />}
                  </button>
                </div>

                {/* Explanation row */}
                {edgeEditingId === connection.edge.id ? (
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginLeft: '18px' }}>
                    <input
                      value={edgeEditingValue}
                      onChange={(e) => setEdgeEditingValue(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter') { e.preventDefault(); void saveEdgeExplanation(connection.edge.id, connection.edge.context); }
                        if (e.key === 'Escape') { e.preventDefault(); cancelEditEdgeExplanation(); }
                      }}
                      placeholder="Describe this connection..."
                      autoFocus
                      style={{
                        flex: 1,
                        minWidth: 0,
                        background: 'var(--rah-bg-surface)',
                        border: '1px solid var(--rah-border-strong)',
                        borderRadius: '6px',
                        padding: '5px 8px',
                        color: 'var(--rah-text-base)',
                        fontSize: '12px',
                        outline: 'none',
                        fontFamily: 'inherit',
                      }}
                    />
                    <button
                      type="button"
                      onClick={() => void saveEdgeExplanation(connection.edge.id, connection.edge.context)}
                      disabled={edgeSavingId === connection.edge.id}
                      style={{ padding: '5px 8px', fontSize: '10px', border: 'none', background: 'var(--rah-accent-green)', color: 'var(--rah-text-inverse)', borderRadius: '5px', cursor: 'pointer', fontFamily: 'inherit', flexShrink: 0 }}
                    >
                      Save
                    </button>
                    <button
                      type="button"
                      onClick={cancelEditEdgeExplanation}
                      style={{ padding: '5px 8px', fontSize: '10px', border: '1px solid var(--rah-border-strong)', background: 'transparent', color: 'var(--rah-text-soft)', borderRadius: '5px', cursor: 'pointer', fontFamily: 'inherit', flexShrink: 0 }}
                    >
                      Cancel
                    </button>
                  </div>
                ) : (explanation || isHovered) ? (
                  <button
                    type="button"
                    onClick={() => startEditEdgeExplanation(connection.edge.id, explanation)}
                    title={explanation || 'Add a note about this connection'}
                    style={{
                      display: 'block',
                      marginLeft: '18px',
                      padding: 0,
                      border: 'none',
                      background: 'transparent',
                      color: explanation ? 'var(--rah-text-muted)' : 'var(--rah-border-stronger)',
                      fontSize: '11.5px',
                      lineHeight: 1.4,
                      textAlign: 'left',
                      cursor: 'pointer',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                      whiteSpace: 'nowrap',
                      maxWidth: '100%',
                      fontFamily: 'inherit',
                      fontStyle: explanation ? 'normal' : 'italic',
                      opacity: isHovered ? 1 : explanation ? 0.7 : 0,
                      transition: 'opacity 120ms ease',
                    }}
                  >
                    {explanation || 'Add note…'}
                  </button>
                ) : null}
              </div>
            );
          })}
        </div>
      )}

      {/* Expand / collapse */}
      {currentEdges.length > 3 && (
        <button
          type="button"
          onClick={() => {
            if (activeTab === null) return;
            setEdgesExpanded(prev => ({ ...prev, [activeTab]: !currentEdgesExpanded }));
          }}
          style={{
            display: 'block',
            background: 'transparent',
            border: 'none',
            color: 'var(--rah-text-muted)',
            fontSize: '11px',
            fontFamily: 'inherit',
            cursor: 'pointer',
            padding: '2px 0',
            textAlign: 'left',
          }}
        >
          {currentEdgesExpanded ? '↑ Show less' : `+ ${currentEdges.length - 3} more`}
        </button>
      )}

      {/* Add connection */}
      {currentEdges.length > 0 && (
        <button
          type="button"
          onClick={() => setEdgeSearchOpen(true)}
          style={{
            display: 'inline-flex', alignItems: 'center', gap: '5px',
            alignSelf: 'flex-start',
            background: 'transparent',
            border: 'none',
            color: 'var(--rah-text-muted)',
            fontSize: '11px',
            fontFamily: 'inherit',
            cursor: 'pointer',
            padding: '2px 0',
          }}
        >
          <Plus size={11} />
          Add connection
        </button>
      )}
    </section>
  );

  const renderSourceSection = () => {
    const sourceContent = currentNode?.source || '';

    return (
      <section
        style={S.section}
        onMouseEnter={() => setHoveredSection('source')}
        onMouseLeave={() => setHoveredSection(prev => prev === 'source' ? null : prev)}
      >
        {/* Section header with extending rule */}
        <div style={S.sectionHeader}>
          <span style={S.sectionLabel}>Source</span>
          <div style={S.sectionRule} />
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', opacity: hoveredSection === 'source' || sourceEditMode ? 1 : 0, transition: 'opacity 150ms ease' }}>
            {!sourceEditMode && (
              <button type="button" style={S.iconBtn} onClick={startSourceEdit} title="Edit source">
                <Pencil size={11} />
              </button>
            )}
          </div>
        </div>

        {sourceEditMode ? (
          <div style={S.editorBlock}>
            <SourceEditor
              value={sourceEditValue}
              onChange={setSourceEditValue}
              disabled={sourceSaving}
            />
            <div style={S.editorActions}>
              <button type="button" style={S.secondaryBtn} onClick={() => { setSourceEditMode(false); setSourceEditValue(''); }} disabled={sourceSaving}>
                <X size={13} /> Cancel
              </button>
              <button type="button" style={S.primaryBtn} onClick={() => void saveSource()} disabled={sourceSaving}>
                {sourceSaving ? <Loader size={13} className="animate-spin" /> : <Save size={13} />} Save
              </button>
            </div>
          </div>
        ) : sourceContent ? (
          <div style={{ minHeight: '240px' }}>
            <SourceReader
              content={sourceContent}
              onTextSelect={onTextSelect ? (text) => onTextSelect(activeTab!, currentNode?.title || 'Untitled', text) : undefined}
              highlightedText={highlightedPassage?.nodeId === activeTab ? highlightedPassage.selectedText : null}
              onContentClick={startSourceEdit}
            />
          </div>
        ) : (
          <button
            type="button"
            onClick={startSourceEdit}
            style={{
              display: 'block',
              width: '100%',
              background: 'transparent',
              border: '1px dashed var(--rah-border-strong)',
              borderRadius: '8px',
              fontFamily: 'inherit',
              fontSize: '13px',
              fontStyle: 'italic',
              color: 'var(--rah-text-muted)',
              cursor: 'text',
              padding: '16px',
              textAlign: 'left',
            }}
          >
            Add source content...
          </button>
        )}
      </section>
    );
  };

  return (
    <>
      <div className="focus-panel">
        {!activeTab ? (
          <div className="empty-state">Select a node from the left panel to view details</div>
        ) : loadingNodes.has(activeTab) ? (
          <div className="empty-state">Loading...</div>
        ) : !currentNode ? (
          <div className="empty-state">Node not found.</div>
        ) : (
          <div className="document-view">

            {/* ── Title ── */}
            <div className="title-row">
              <div className="title-stack">
                <div className="title-heading-row">
                  {titleEditMode ? (
                    <input
                      ref={titleInputRef}
                      type="text"
                      value={titleEditValue}
                      onChange={(e) => setTitleEditValue(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter') { e.preventDefault(); void saveTitle(); }
                        if (e.key === 'Escape') { e.preventDefault(); skipTitleBlurRef.current = true; setTitleEditMode(false); setTitleEditValue(''); }
                      }}
                      onBlur={() => {
                        if (skipTitleBlurRef.current) { skipTitleBlurRef.current = false; return; }
                        void saveTitle();
                      }}
                      disabled={titleSaving}
                      className="title-input"
                      placeholder="Enter title..."
                    />
                  ) : (
                    <button type="button" className="title-button" onClick={startTitleEdit}>
                      {currentNode.title || 'Untitled'}
                    </button>
                  )}
                </div>
              </div>
            </div>

            {/* ── Properties block ── */}
            <div className="props-block">

              {/* Status indicator row (only when relevant) */}
              {renderStatusIndicator() !== null && (
                <div className="prop-row">
                  <div className="prop-label">embed</div>
                  <div className="prop-value">{renderStatusIndicator()}</div>
                </div>
              )}

              <div className="prop-row">
                <div className="prop-label">node</div>
                <div className="prop-value node-row-value">
                  <span className="title-node-label">#{currentNode.id}</span>
                  {currentProcessedState === 'processed' ? (
                    <span className="node-processed-indicator" title="Processed">
                      <Check size={11} strokeWidth={3} />
                    </span>
                  ) : null}
                  {onOpenInMap ? (
                    <button
                      type="button"
                      className="node-map-button"
                      onClick={onOpenInMap}
                      title="Open this node in the map"
                    >
                      Map
                    </button>
                  ) : null}
                  <button
                    type="button"
                    className="delete-node-button node-delete-button"
                    onClick={() => setPendingDeleteNodeId(activeTab)}
                    disabled={deletingNode === activeTab}
                    title="Delete node"
                  >
                    {deletingNode === activeTab ? '…' : <Trash2 size={11} />}
                  </button>
                </div>
              </div>

              {/* Link */}
              <div className="prop-row">
                <div className="prop-label">link</div>
                <div className="prop-value">
                  {linkEditMode ? (
                    <input
                      ref={linkInputRef}
                      type="url"
                      value={linkEditValue}
                      onChange={(e) => setLinkEditValue(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter') { e.preventDefault(); void saveLink(); }
                        if (e.key === 'Escape') { e.preventDefault(); skipLinkBlurRef.current = true; setLinkEditMode(false); setLinkEditValue(''); }
                      }}
                      onBlur={() => {
                        if (skipLinkBlurRef.current) { skipLinkBlurRef.current = false; return; }
                        void saveLink();
                      }}
                      disabled={linkSaving}
                      className="prop-input"
                      placeholder="https://..."
                    />
                  ) : (
                    <div className="link-inline-row">
                      {currentNode.link ? (
                        normalizedCurrentLink ? (
                          <a
                            href={normalizedCurrentLink}
                            className="prop-link"
                            onClick={(e) => {
                              if (!shouldOpenExternally(normalizedCurrentLink)) return;
                              e.preventDefault();
                              void openExternalUrl(normalizedCurrentLink).catch(() => window.alert(`Unable to open ${currentNode.link}`));
                            }}
                            title={normalizedCurrentLink}
                          >
                            {currentNode.link}
                          </a>
                        ) : (
                          <button type="button" className="prop-empty-btn" onClick={startLinkEdit} title="Invalid link. Click to edit.">
                            {currentNode.link}
                          </button>
                        )
                      ) : (
                        <button type="button" className="prop-empty-btn" onClick={startLinkEdit}>
                          Empty
                        </button>
                      )}
                      <button
                        type="button"
                        className="context-inline-button"
                        onClick={startLinkEdit}
                        title={currentNode.link ? 'Edit link' : 'Add link'}
                      >
                        <Pencil size={12} />
                      </button>
                    </div>
                  )}
                </div>
              </div>

              {/* Connections */}
              <div className="prop-row prop-row-top">
                <div className="prop-label">edge</div>
                <div className="prop-value">
                  {loadingEdges.has(activeTab) ? (
                    <span className="prop-muted">Loading…</span>
                  ) : currentEdges.length === 0 ? (
                    <button type="button" className="prop-empty-btn" onClick={() => setEdgeSearchOpen(true)}>
                      Empty
                    </button>
                  ) : (
                    <div className="conn-list">
                      {visibleEdges.map((connection) => {
                        const isOut = connection.edge.from_node_id === activeTab;
                        return (
                          <div
                            key={connection.id}
                            className="conn-row"
                            onMouseEnter={() => setHoveredConnectionId(connection.id)}
                            onMouseLeave={() => setHoveredConnectionId(null)}
                          >
                            <span className={`conn-dir ${isOut ? 'out' : 'in'}`}>{isOut ? '↗' : '↙'}</span>
                            <span className="conn-icon">{getNodeIcon(connection.connected_node, 12)}</span>
                            <button
                              type="button"
                              className="conn-title-btn"
                              onClick={() => (onNodeClick || onTabSelect)(connection.connected_node.id)}
                              title={connection.connected_node.title}
                            >
                              {connection.connected_node.title}
                            </button>
                            <button
                              type="button"
                              className="conn-del-btn"
                              style={{ opacity: hoveredConnectionId === connection.id ? 1 : 0 }}
                              onClick={() => void deleteEdge(connection.edge.id)}
                              disabled={deletingEdge === connection.edge.id}
                              title="Remove"
                            >
                              <Trash2 size={10} />
                            </button>
                          </div>
                        );
                      })}
                      {currentEdges.length > 3 && (
                        <button
                          type="button"
                          className="conn-more-btn"
                          onClick={() => setEdgesExpanded(prev => ({ ...prev, [activeTab]: !currentEdgesExpanded }))}
                        >
                          {currentEdgesExpanded ? '↑ Show less' : `+ ${currentEdges.length - 3} more`}
                        </button>
                      )}
                      <div className="conn-add-inline">
                        <span className="conn-add-label">Add connection</span>
                        <button type="button" className="context-inline-button" onClick={() => setEdgeSearchOpen(true)} title="Add connection">
                          <Plus size={12} />
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              </div>

              {/* Description */}
              <div className="prop-row prop-row-top">
                <div className="prop-label">desc</div>
                <div className="prop-value">
                  {descEditMode ? (
                    <div className="desc-edit-block">
                      <textarea
                        ref={descTextareaRef}
                        value={descEditValue}
                        onChange={(e) => setDescEditValue(e.target.value)}
                        onKeyDown={(e) => {
                          if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') { e.preventDefault(); void saveDesc(); }
                          if (e.key === 'Escape') { e.preventDefault(); setDescEditMode(false); setDescEditValue(''); }
                        }}
                        disabled={descSaving}
                        className="desc-textarea"
                        placeholder="Add a description..."
                        rows={4}
                      />
                      <div className="desc-actions">
                        <button type="button" className="btn-secondary" onClick={() => { setDescEditMode(false); setDescEditValue(''); }} disabled={descSaving}>
                          <X size={12} /> Cancel
                        </button>
                        <button type="button" className="btn-primary" onClick={() => void saveDesc()} disabled={descSaving}>
                          {descSaving ? <Loader size={12} className="animate-spin" /> : <Save size={12} />} Save
                        </button>
                      </div>
                    </div>
                  ) : (
                    <div className="desc-read-wrap">
                      <div className="desc-text" onClick={startDescEdit}>
                        {currentNode.description
                          ? parseAndRenderContent(currentNode.description, onNodeClick || onTabSelect)
                          : <span className="prop-empty-btn" style={{ display: 'block' }}>Empty</span>}
                      </div>
                      <div className="desc-hover-actions">
                        <button type="button" className="icon-btn" onClick={startDescEdit} title="Edit">
                          <Pencil size={11} />
                        </button>
                        <button
                          type="button"
                          className="icon-btn"
                          onClick={() => void regenerateDescription(activeTab)}
                          disabled={regeneratingDescription === activeTab}
                          title="Regenerate"
                        >
                          {regeneratingDescription === activeTab ? <Loader size={11} className="animate-spin" /> : <RefreshCw size={11} />}
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              </div>

              {/* Drag handle / ID (hidden, for drag-to-chat) */}
              <span
                draggable
                onDragStart={(e: DragEvent<HTMLSpanElement>) => {
                  const title = currentNode.title || 'Untitled';
                  e.dataTransfer.effectAllowed = 'copyMove';
                  e.dataTransfer.setData('application/x-rah-node', JSON.stringify({ id: activeTab, title }));
                  e.dataTransfer.setData('application/node-info', JSON.stringify({ id: activeTab, title }));
                  e.dataTransfer.setData('text/plain', `[NODE:${activeTab}:"${title}"]`);
                }}
                className="node-drag-handle"
                title={`Node ${activeTab} — drag to chat`}
              >
                {activeTab}
              </span>
            </div>

            {renderSourceSection()}
            {renderMetadataSection()}
          </div>
        )}
      </div>

      <NodeSearchModal
        isOpen={edgeSearchOpen}
        onClose={() => setEdgeSearchOpen(false)}
        excludeNodeId={activeTab}
        onEdgeCreate={async (nodeId, explanation) => {
          if (!explanation || !explanation.trim()) {
            window.alert('Add a short explanation for the relationship before creating the edge.');
            return;
          }
          await createEdgeWithExplanation(nodeId, explanation.trim());
        }}
      />

      <ConfirmDialog
        open={pendingDeleteNodeId !== null}
        title="Delete this node?"
        message="This will permanently remove the node and its data."
        confirmLabel="Delete"
        onConfirm={() => {
          if (pendingDeleteNodeId === null) return;
          void executeDeleteNode(pendingDeleteNodeId);
          setPendingDeleteNodeId(null);
        }}
        onCancel={() => setPendingDeleteNodeId(null)}
      />

      <style jsx>{`
        /* ── Layout ── */
        .focus-panel {
          height: 100%;
          overflow: auto;
          padding: 24px 20px 32px;
        }

        .document-view {
          display: flex;
          flex-direction: column;
          min-height: 100%;
          width: 100%;
          max-width: 980px;
          margin: 0 auto;
        }

        .empty-state {
          color: var(--rah-text-muted);
          font-size: 13px;
          text-align: center;
          margin-top: 40px;
        }

        /* ── Title row ── */
        .title-row {
          display: block;
          margin-bottom: 18px;
        }

        .title-stack {
          display: block;
          min-width: 0;
        }

        .title-node-label {
          font-size: 11px;
          font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
          color: var(--rah-text-muted);
          line-height: 1.2;
          letter-spacing: 0.04em;
          display: inline;
          vertical-align: baseline;
        }

        .title-heading-row {
          min-width: 0;
          display: block;
          line-height: 1.35;
        }

        .title-button,
        .title-input {
          min-width: 0;
          background: transparent;
          border: none;
          color: var(--rah-text-active);
          font-family: inherit;
          text-align: left;
        }

        .title-button {
          display: inline;
          padding: 0;
          font-size: 22px;
          font-weight: 700;
          line-height: 1.25;
          cursor: text;
          white-space: normal;
          word-break: break-word;
          letter-spacing: -0.01em;
        }

        .title-input {
          display: inline-block;
          width: calc(100% - 34px);
          font-size: 22px;
          font-weight: 700;
          line-height: 1.25;
          letter-spacing: -0.01em;
          padding: 0;
          outline: none;
        }

        .delete-node-button {
          color: #ef4444;
          background: transparent;
          border: none;
          width: 26px;
          height: 26px;
          display: inline-flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          flex-shrink: 0;
          border-radius: 5px;
          transition: color 120ms ease, background 120ms ease, transform 120ms ease;
        }

        .node-row-value {
          display: inline-flex;
          align-items: center;
          gap: 8px;
        }

        .node-processed-indicator {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          width: 16px;
          height: 16px;
          border-radius: 999px;
          color: var(--rah-accent-green);
          background: color-mix(in srgb, var(--rah-accent-green) 14%, transparent);
          border: 1px solid color-mix(in srgb, var(--rah-accent-green) 32%, transparent);
          flex-shrink: 0;
        }

        .node-map-button {
          border: 1px solid var(--rah-border-strong);
          background: var(--rah-bg-panel);
          color: var(--rah-text-muted);
          border-radius: 999px;
          font-size: 10px;
          font-weight: 700;
          letter-spacing: 0.03em;
          padding: 3px 8px;
          cursor: pointer;
          flex-shrink: 0;
        }

        .node-map-button:hover {
          border-color: var(--rah-accent-green-soft-strong);
          color: var(--rah-accent-green);
          background: var(--rah-accent-green-soft);
        }

        .node-delete-button {
          width: 20px;
          height: 20px;
          border-radius: 4px;
        }

        .delete-node-button:hover:enabled {
          color: #ef4444;
          background: rgba(239, 68, 68, 0.12);
          transform: scale(1.05);
        }

        /* ── Properties block ── */
        .props-block {
          margin-bottom: 6px;
        }

        .prop-row {
          display: flex;
          align-items: flex-start;
          min-height: 32px;
          padding: 0;
        }

        .prop-row-top {
        }

        .prop-label {
          width: 58px;
          flex-shrink: 0;
          padding: 7px 8px 7px 0;
          color: var(--rah-text-muted);
          font-size: 11px;
          line-height: 1.5;
        }

        .prop-value {
          flex: 1;
          min-width: 0;
          padding: 7px 12px 7px 0;
          overflow: hidden;
          font-size: 12px;
          line-height: 1.5;
        }

        .context-prop-value {
          overflow: visible;
        }

        /* Link */
        .prop-link {
          color: var(--rah-text-soft);
          text-decoration: none;
          font-size: 12px;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
          display: block;
          min-width: 0;
          max-width: 100%;
          transition: color 120ms ease;
        }

        .prop-link:hover { color: #3b82f6; }

        .link-inline-row {
          display: inline-flex;
          align-items: center;
          gap: 8px;
          min-width: 0;
          max-width: 100%;
        }

        .prop-input {
          width: 100%;
          background: transparent;
          border: none;
          border-bottom: 1px solid var(--rah-border-strong);
          color: var(--rah-text-base);
          font-size: 12px;
          outline: none;
          padding: 0 0 3px 0;
          font-family: inherit;
        }

        .context-select-shell {
          position: relative;
          z-index: 4;
        }

        .context-inline-row {
          display: inline-flex;
          align-items: center;
          gap: 8px;
          min-width: 0;
          max-width: 100%;
        }

        .context-inline-button {
          width: 20px;
          height: 20px;
          display: inline-flex;
          align-items: center;
          justify-content: center;
          padding: 0;
          border: 1px solid var(--rah-border);
          border-radius: 5px;
          background: transparent;
          color: var(--rah-text-muted);
          cursor: pointer;
          flex-shrink: 0;
          transition: color 120ms ease, border-color 120ms ease, background 120ms ease;
        }

        .context-inline-button:hover:enabled {
          color: var(--rah-text-soft);
          border-color: var(--rah-border-strong);
          background: var(--rah-bg-hover);
        }

        .context-select-name,
        .context-select-empty {
          font-size: 12px;
          line-height: 1.2;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }

        .context-select-name {
          color: var(--rah-text-primary);
          font-weight: 600;
        }

        .context-select-empty {
          color: var(--rah-text-muted);
          font-style: italic;
        }

        .context-select-menu {
          position: absolute;
          top: calc(100% + 8px);
          left: 0;
          min-width: 220px;
          max-width: min(320px, 100vw - 48px);
          display: flex;
          flex-direction: column;
          gap: 2px;
          padding: 6px;
          border: 1px solid var(--rah-border);
          border-radius: 12px;
          background: var(--rah-bg-surface);
          box-shadow: var(--rah-shadow-floating);
        }

        .context-option {
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 10px;
          width: 100%;
          min-height: 32px;
          padding: 0 10px;
          border: none;
          border-radius: 8px;
          background: transparent;
          color: var(--rah-text-secondary);
          font-size: 12px;
          text-align: left;
          cursor: pointer;
        }

        .context-option.active {
          background: color-mix(in srgb, var(--rah-accent-green) 10%, var(--rah-bg-panel));
          color: var(--rah-text-primary);
        }

        .context-option-count {
          font-size: 10px;
          color: var(--rah-text-muted);
          flex-shrink: 0;
        }

        .prop-empty-btn {
          background: transparent;
          border: none;
          color: var(--rah-text-muted);
          font-size: 12px;
          font-style: italic;
          padding: 0;
          cursor: pointer;
          font-family: inherit;
        }

        .prop-muted {
          color: var(--rah-text-muted);
          font-size: 12px;
        }

        /* Status chips */
        .status-button,
        .status-chip {
          display: inline-flex;
          align-items: center;
          gap: 4px;
          padding: 2px 6px;
          font-size: 10px;
          border-radius: 999px;
          flex-shrink: 0;
        }

        .status-button {
          color: #ef4444;
          background: transparent;
          border: 1px solid #7f1d1d;
          cursor: pointer;
        }

        .status-chip {
          color: #f59e0b;
          border: 1px solid #3d3500;
          background: rgba(245, 158, 11, 0.06);
        }

        /* ── Connections in property ── */
        .conn-list {
          display: flex;
          flex-direction: column;
          gap: 1px;
          width: 100%;
        }

        .conn-row {
          display: flex;
          align-items: center;
          gap: 5px;
          padding: 2px 4px;
          border-radius: 4px;
          min-width: 0;
        }

        .conn-row:hover { background: var(--rah-bg-hover); }

        .conn-dir {
          font-size: 10px;
          flex-shrink: 0;
          width: 12px;
          text-align: center;
        }

        .conn-dir.out { color: var(--rah-accent-green); }
        .conn-dir.in { color: #f59e0b; }

        .conn-icon {
          display: inline-flex;
          align-items: center;
          flex-shrink: 0;
        }

        .conn-title-btn {
          flex: 1;
          min-width: 0;
          background: transparent;
          border: none;
          padding: 0;
          color: var(--rah-text-base);
          font-size: 12px;
          font-weight: 500;
          text-align: left;
          cursor: pointer;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
          font-family: inherit;
          transition: color 120ms ease;
        }

        .conn-title-btn:hover { color: var(--rah-accent-green); }

        .conn-del-btn {
          background: transparent;
          border: none;
          color: var(--rah-text-muted);
          cursor: pointer;
          padding: 2px;
          border-radius: 3px;
          flex-shrink: 0;
          display: inline-flex;
          align-items: center;
          transition: opacity 120ms ease, color 120ms ease;
        }

        .conn-del-btn:hover:enabled { color: #dc2626; }

        .conn-more-btn {
          background: transparent;
          border: none;
          color: var(--rah-text-muted);
          font-size: 11px;
          font-family: inherit;
          cursor: pointer;
          padding: 3px 4px;
          text-align: left;
          transition: color 120ms ease;
        }

        .conn-more-btn:hover { color: var(--rah-text-soft); }

        .conn-add-inline {
          display: inline-flex;
          align-items: center;
          gap: 8px;
        }

        .conn-add-label {
          color: var(--rah-text-muted);
          font-size: 12px;
        }

        .metadata-toggle {
          display: inline-flex;
          align-items: center;
          gap: 6px;
          padding: 0;
          border: none;
          background: transparent;
          color: var(--rah-text-muted);
          cursor: pointer;
          font-family: inherit;
        }

        .metadata-toggle:hover {
          color: var(--rah-text-soft);
        }

        .metadata-group {
          display: flex;
          flex-direction: column;
          gap: 8px;
          min-width: 0;
          width: 100%;
          overflow: hidden;
        }

        .metadata-group-label {
          font-size: 10px;
          color: var(--rah-text-muted);
          text-transform: uppercase;
          letter-spacing: 0.08em;
          font-weight: 600;
        }

        .metadata-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
          gap: 8px;
          width: 100%;
          min-width: 0;
          overflow: hidden;
        }

        .metadata-card {
          display: flex;
          flex-direction: column;
          gap: 4px;
          padding: 10px 12px;
          border-radius: 10px;
          background: rgba(255, 255, 255, 0.025);
          border: 1px solid var(--rah-border);
          min-width: 0;
          overflow: hidden;
        }

        .metadata-key {
          font-size: 10px;
          color: var(--rah-text-muted);
          text-transform: uppercase;
          letter-spacing: 0.08em;
          font-weight: 600;
        }

        .metadata-value {
          font-size: 12px;
          color: var(--rah-text-base);
          line-height: 1.45;
          word-break: break-word;
          overflow-wrap: anywhere;
          min-width: 0;
        }

        .metadata-raw {
          margin: 0;
          padding: 12px 14px;
          border-radius: 12px;
          background: rgba(0, 0, 0, 0.24);
          border: 1px solid var(--rah-border);
          color: var(--rah-text-soft);
          font-size: 11px;
          line-height: 1.55;
          white-space: pre-wrap;
          word-break: break-word;
          overflow-wrap: anywhere;
          overflow: hidden;
          width: 100%;
          min-width: 0;
          max-width: 100%;
          box-sizing: border-box;
          display: block;
          font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
        }

        /* ── Description in property ── */
        .desc-read-wrap {
          position: relative;
          width: 100%;
        }

        .desc-text {
          color: var(--rah-text-base);
          font-size: 12px;
          line-height: 1.5;
          cursor: text;
          padding-right: 44px;
          display: -webkit-box;
          -webkit-line-clamp: 2;
          -webkit-box-orient: vertical;
          overflow: hidden;
        }

        .desc-hover-actions {
          position: absolute;
          top: 0;
          right: 0;
          display: flex;
          align-items: center;
          gap: 2px;
          opacity: 0;
          transition: opacity 120ms ease;
        }

        .desc-read-wrap:hover .desc-hover-actions { opacity: 1; }

        .icon-btn {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          width: 20px;
          height: 20px;
          background: transparent;
          border: none;
          color: var(--rah-text-muted);
          cursor: pointer;
          border-radius: 4px;
          transition: color 120ms ease, background 120ms ease;
        }

        .icon-btn:hover:enabled {
          color: var(--rah-text-base);
          background: var(--rah-bg-active);
        }

        .desc-edit-block {
          display: flex;
          flex-direction: column;
          gap: 8px;
          width: 100%;
        }

        .desc-textarea {
          width: 100%;
          background: var(--rah-bg-base);
          border: 1px solid var(--rah-border-strong);
          border-radius: 6px;
          color: var(--rah-text-base);
          font-family: inherit;
          font-size: 13px;
          line-height: 1.6;
          outline: none;
          padding: 8px 10px;
          resize: vertical;
          min-height: 88px;
          box-sizing: border-box;
        }

        .desc-textarea:focus { border-color: var(--rah-border-stronger); }

        .desc-actions {
          display: flex;
          justify-content: flex-end;
          gap: 6px;
        }

        .btn-primary {
          display: inline-flex;
          align-items: center;
          gap: 4px;
          padding: 5px 10px;
          border: none;
          background: var(--rah-accent-green);
          color: var(--rah-text-inverse);
          font-size: 11px;
          font-weight: 600;
          border-radius: 5px;
          cursor: pointer;
          font-family: inherit;
        }

        .btn-primary:hover:enabled { background: var(--rah-accent-green-hover); }

        .btn-secondary {
          display: inline-flex;
          align-items: center;
          gap: 4px;
          padding: 5px 10px;
          border: 1px solid var(--rah-border-strong);
          background: transparent;
          color: var(--rah-text-soft);
          font-size: 11px;
          border-radius: 5px;
          cursor: pointer;
          font-family: inherit;
        }

        .btn-secondary:hover:enabled {
          border-color: var(--rah-border-stronger);
          color: var(--rah-text-base);
        }

        /* ── Drag handle (invisible but functional) ── */
        .node-drag-handle {
          display: none;
          position: absolute;
        }
      `}</style>
    </>
  );
}
