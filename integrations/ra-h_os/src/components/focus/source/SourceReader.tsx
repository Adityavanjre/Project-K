"use client";

import { useMemo, useState, useEffect, useCallback, useRef } from 'react';
import { detectContentType } from './ContentDetector';
import RawFormatter from './formatters/RawFormatter';
import TranscriptFormatter from './formatters/TranscriptFormatter';
import BookFormatter from './formatters/BookFormatter';
import MarkdownFormatter from './formatters/MarkdownFormatter';
import SourceSearchBar from './SourceSearchBar';

interface SourceReaderProps {
  content: string;
  onTextSelect?: (text: string) => void;
  highlightedText?: string | null;
  onContentClick?: () => void;
}

export default function SourceReader({
  content,
  onTextSelect,
  highlightedText,
  onContentClick,
}: SourceReaderProps) {
  const [showSearch, setShowSearch] = useState(false);
  const [searchHighlight, setSearchHighlight] = useState<string | null>(null);
  const [searchMatchIndex, setSearchMatchIndex] = useState(0);
  const [scrollTrigger, setScrollTrigger] = useState(0);
  const contentRef = useRef<HTMLDivElement>(null);

  const contentType = useMemo(() => detectContentType(content), [content]);
  const activeHighlight = searchHighlight || highlightedText;

  // Cmd+F to open search
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'f') {
        e.preventDefault();
        setShowSearch(true);
      }
    };
    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, []);

  // Scroll to current search match
  useEffect(() => {
    if (!searchHighlight || !contentRef.current) return;
    const timer = setTimeout(() => {
      const currentMatch = contentRef.current?.querySelector('mark[data-search-match="current"]');
      currentMatch?.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }, 50);
    return () => clearTimeout(timer);
  }, [searchHighlight, scrollTrigger]);

  const handleSearchClose = useCallback(() => {
    setShowSearch(false);
    setSearchHighlight(null);
    setSearchMatchIndex(0);
  }, []);

  const handleHighlightChange = useCallback((text: string | null, matchIndex: number) => {
    setSearchHighlight(text);
    setSearchMatchIndex(matchIndex);
    setScrollTrigger(prev => prev + 1);
  }, []);

  const renderContent = () => {
    const highlightIndex = showSearch ? searchMatchIndex : undefined;
    switch (contentType) {
      case 'transcript':
        return <TranscriptFormatter content={content} onTextSelect={onTextSelect} highlightedText={activeHighlight} highlightMatchIndex={highlightIndex} />;
      case 'book':
      case 'article':
        return <BookFormatter content={content} onTextSelect={onTextSelect} highlightedText={activeHighlight} highlightMatchIndex={highlightIndex} />;
      case 'markdown':
        return <MarkdownFormatter content={content} onTextSelect={onTextSelect} highlightedText={activeHighlight} highlightMatchIndex={highlightIndex} />;
      default:
        return <RawFormatter content={content} onTextSelect={onTextSelect} highlightedText={activeHighlight} highlightMatchIndex={highlightIndex} />;
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column' }}>
      {/* Search bar — only visible when active (Cmd+F) */}
      {showSearch && content && (
        <SourceSearchBar
          content={content}
          onClose={handleSearchClose}
          onHighlightChange={handleHighlightChange}
        />
      )}

      {/* Content — no chrome, no background, just the text */}
      <div
        ref={contentRef}
        onClick={() => {
          if (!onContentClick) return;
          const selected = window.getSelection?.()?.toString().trim();
          if (selected) return;
          onContentClick();
        }}
        style={{ cursor: onContentClick ? 'text' : 'default' }}
      >
        {renderContent()}
      </div>
    </div>
  );
}
