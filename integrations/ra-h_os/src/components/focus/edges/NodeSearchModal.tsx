"use client";

import { useEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';

interface NodeSearchModalProps {
  isOpen: boolean;
  onClose: () => void;
  onEdgeCreate: (nodeId: number, explanation?: string) => Promise<void>;
  excludeNodeId?: number | null;
}

interface NodeSuggestion {
  id: number;
  title: string;
}

export default function NodeSearchModal({
  isOpen,
  onClose,
  onEdgeCreate,
  excludeNodeId,
}: NodeSearchModalProps) {
  const [mounted, setMounted] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [suggestions, setSuggestions] = useState<NodeSuggestion[]>([]);
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [selectedNode, setSelectedNode] = useState<NodeSuggestion | null>(null);
  const [explanation, setExplanation] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const inputRef = useRef<HTMLInputElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    setMounted(true);
  }, []);

  const resetState = () => {
    setSearchQuery('');
    setSuggestions([]);
    setSelectedIndex(0);
    setSelectedNode(null);
    setExplanation('');
    setSubmitting(false);
  };

  const closeModal = () => {
    resetState();
    onClose();
  };

  useEffect(() => {
    if (!isOpen) {
      resetState();
      return;
    }

    const timer = setTimeout(() => inputRef.current?.focus(), 50);

    const handleEscape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        event.preventDefault();
        if (selectedNode) {
          setSelectedNode(null);
          setExplanation('');
        } else {
          closeModal();
        }
      }
    };

    document.addEventListener('keydown', handleEscape);
    return () => {
      clearTimeout(timer);
      document.removeEventListener('keydown', handleEscape);
    };
  }, [isOpen, selectedNode]);

  useEffect(() => {
    if (!isOpen) return;
    if (!searchQuery.trim()) {
      setSuggestions([]);
      setSelectedIndex(0);
      return;
    }

    const timeoutId = setTimeout(async () => {
      try {
        const response = await fetch(`/api/nodes/search?q=${encodeURIComponent(searchQuery)}&limit=20`);
        const result = await response.json();
        if (response.ok && result.success) {
          const nextSuggestions = (result.data as NodeSuggestion[])
            .filter((node) => node.id !== excludeNodeId)
            .map((node) => ({
              id: node.id,
              title: node.title,
            }));
          setSuggestions(nextSuggestions);
          setSelectedIndex(0);
        } else {
          setSuggestions([]);
        }
      } catch (error) {
        console.error('Error fetching node suggestions:', error);
        setSuggestions([]);
      }
    }, 150);

    return () => clearTimeout(timeoutId);
  }, [searchQuery, isOpen, excludeNodeId]);

  useEffect(() => {
    if (selectedNode) {
      setTimeout(() => textareaRef.current?.focus(), 50);
    }
  }, [selectedNode]);

  const handleCreate = async (node: NodeSuggestion, nextExplanation?: string) => {
    setSubmitting(true);
    try {
      await onEdgeCreate(node.id, nextExplanation?.trim() || undefined);
      closeModal();
    } catch (err) {
      console.error('Failed to create edge:', err);
    } finally {
      setSubmitting(false);
    }
  };

  const handleSearchKeyDown = async (event: React.KeyboardEvent<HTMLInputElement>) => {
    if (event.key === 'ArrowDown') {
      event.preventDefault();
      setSelectedIndex((prev) => Math.min(prev + 1, suggestions.length - 1));
      return;
    }
    if (event.key === 'ArrowUp') {
      event.preventDefault();
      setSelectedIndex((prev) => Math.max(prev - 1, 0));
      return;
    }
    if (event.key === 'Enter' && suggestions[selectedIndex]) {
      event.preventDefault();
      setSelectedNode(suggestions[selectedIndex]);
      setExplanation('');
    }
  };

  if (!mounted || !isOpen) return null;

  const modal = (
    <div
      onClick={(e) => { if (e.target === e.currentTarget) closeModal(); }}
      style={{
        position: 'fixed',
        inset: 0,
        background: 'rgba(0,0,0,0.7)',
        backdropFilter: 'blur(6px)',
        display: 'flex',
        justifyContent: 'center',
        paddingTop: '15vh',
        zIndex: 9999,
      }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          width: '100%',
          maxWidth: selectedNode ? '480px' : '560px',
          maxHeight: '70vh',
          display: 'flex',
          flexDirection: 'column',
          gap: '8px',
          alignSelf: 'flex-start',
        }}
      >
        {!selectedNode && (
          <div style={{
            display: 'flex',
            alignItems: 'center',
            gap: '12px',
            background: '#141414',
            border: '1px solid #2a2a2a',
            borderRadius: '12px',
            padding: '14px 18px',
            boxShadow: '0 24px 48px -12px rgba(0,0,0,0.6)',
          }}>
            <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor" style={{ color: '#555', flexShrink: 0 }}>
              <path fillRule="evenodd" d="M9 3.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zM2 9a7 7 0 1112.452 4.391l3.328 3.329a.75.75 0 11-1.06 1.06l-3.329-3.328A7 7 0 012 9z" clipRule="evenodd" />
            </svg>
            <input
              ref={inputRef}
              type="text"
              value={searchQuery}
              onChange={(e) => {
                setSearchQuery(e.target.value);
                setSelectedNode(null);
                setExplanation('');
              }}
              onKeyDown={(e) => { void handleSearchKeyDown(e); }}
              placeholder="Search nodes to connect..."
              style={{
                flex: 1,
                background: 'none',
                border: 'none',
                outline: 'none',
                color: '#f0f0f0',
                fontSize: '15px',
                fontFamily: 'inherit',
              }}
            />
            <kbd style={{
              display: 'inline-flex',
              alignItems: 'center',
              padding: '3px 7px',
              background: '#222',
              border: '1px solid #333',
              borderRadius: '5px',
              fontSize: '11px',
              color: '#666',
            }}>esc</kbd>
          </div>
        )}

        {/* Results */}
        {!selectedNode && suggestions.length > 0 && (
          <div style={{
            background: '#141414',
            border: '1px solid #2a2a2a',
            borderRadius: '12px',
            overflowX: 'hidden',
            overflowY: 'auto',
            maxHeight: 'min(60vh, 560px)',
            boxShadow: '0 24px 48px -12px rgba(0,0,0,0.6)',
          }}>
            {suggestions.map((suggestion, index) => (
              <button
                key={suggestion.id}
                type="button"
                onClick={() => { setSelectedNode(suggestion); setExplanation(''); }}
                onMouseEnter={() => setSelectedIndex(index)}
                style={{
                  width: '100%',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '12px',
                  padding: '12px 16px',
                  background: index === selectedIndex ? '#1e1e1e' : 'transparent',
                  border: 'none',
                  borderBottom: index < suggestions.length - 1 ? '1px solid #1f1f1f' : 'none',
                  cursor: 'pointer',
                  textAlign: 'left',
                  fontFamily: 'inherit',
                }}
              >
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ color: '#e0e0e0', fontSize: '13px', marginBottom: '2px' }}>
                    {suggestion.title}
                  </div>
                </div>
                <span style={{ color: '#444', fontSize: '11px', fontFamily: 'monospace', flexShrink: 0 }}>
                  #{suggestion.id}
                </span>
                {index === selectedIndex && (
                  <span style={{ color: '#444', fontSize: '12px', flexShrink: 0 }}>↵</span>
                )}
              </button>
            ))}
          </div>
        )}

        {/* Selected node — explanation step */}
        {selectedNode && (
          <div style={{
            background: '#141414',
            border: '1px solid #2a2a2a',
            borderRadius: '12px',
            padding: '16px',
            boxShadow: '0 24px 48px -12px rgba(0,0,0,0.6)',
          }}>
            <div style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'flex-start',
              gap: '12px',
              marginBottom: '14px',
            }}>
              <div>
                <div style={{ color: '#777', fontSize: '12px', marginBottom: '5px' }}>
                  Connecting to
                </div>
                <div style={{ color: '#e0e0e0', fontSize: '14px' }}>{selectedNode.title}</div>
              </div>
              <button
                type="button"
                onClick={() => setSelectedNode(null)}
                style={{
                  border: '1px solid #333',
                  background: 'transparent',
                  color: '#888',
                  padding: '5px 10px',
                  borderRadius: '7px',
                  cursor: 'pointer',
                  fontSize: '11px',
                  fontFamily: 'inherit',
                  flexShrink: 0,
                }}
              >
                Change
              </button>
            </div>

            <div style={{ position: 'relative', marginBottom: '10px' }}>
              <textarea
                ref={textareaRef}
                value={explanation}
                onChange={(e) => setExplanation(e.target.value.slice(0, 500))}
                onKeyDown={(e) => {
                  if ((e.metaKey || e.ctrlKey) && e.key === 'Enter' && explanation.trim()) {
                    e.preventDefault();
                    void handleCreate(selectedNode, explanation);
                  }
                }}
                placeholder="Describe this connection in one clear sentence"
                rows={3}
                style={{
                  width: '100%',
                  padding: '10px',
                  background: '#0e0e0e',
                  border: '1px solid #2a2a2a',
                  borderRadius: '8px',
                  color: '#d0d0d0',
                  fontSize: '13px',
                  fontFamily: 'inherit',
                  resize: 'none',
                  outline: 'none',
                  boxSizing: 'border-box',
                }}
              />
              <span style={{
                position: 'absolute',
                bottom: '8px',
                right: '10px',
                fontSize: '10px',
                color: '#444',
                fontFamily: 'monospace',
              }}>
                {explanation.length}/500
              </span>
            </div>

            <button
              type="button"
              onClick={() => { void handleCreate(selectedNode, explanation); }}
              disabled={submitting || !explanation.trim()}
              style={{
                width: '100%',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                padding: '10px 16px',
                background: '#1a1a1a',
                border: '1px solid #2a2a2a',
                borderRadius: '8px',
                cursor: submitting ? 'wait' : 'pointer',
                fontFamily: 'inherit',
                color: '#22c55e',
                fontSize: '13px',
                opacity: submitting ? 0.6 : 1,
              }}
            >
              {submitting ? 'Creating…' : 'Create connection'}
            </button>
          </div>
        )}

        {!searchQuery && suggestions.length === 0 && !selectedNode && (
          <div style={{
            padding: '28px 20px',
            textAlign: 'center',
            color: '#555',
            fontSize: '13px',
          }}>
            Start typing to search nodes
          </div>
        )}
      </div>
    </div>
  );

  return createPortal(modal, document.body);
}
