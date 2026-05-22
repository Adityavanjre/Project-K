"use client";

import { useCallback, useRef } from 'react';
import MarkdownWithNodeTokens from '@/components/helpers/MarkdownWithNodeTokens';

interface MarkdownFormatterProps {
  content: string;
  onTextSelect?: (text: string) => void;
  highlightedText?: string | null;
  highlightMatchIndex?: number;
}

/**
 * Markdown Formatter - Renders markdown content with good typography
 * Note: Search highlighting not yet implemented for markdown content
 */
export default function MarkdownFormatter({ content, onTextSelect }: MarkdownFormatterProps) {
  const containerRef = useRef<HTMLDivElement>(null);

  const handleMouseUp = useCallback(() => {
    if (!onTextSelect) return;

    const selection = window.getSelection();
    const text = selection?.toString().trim();

    if (text && text.length > 10) {
      const truncatedText = text.length > 2000 
        ? text.slice(0, 2000) + '...' 
        : text;
      onTextSelect(truncatedText);
      selection?.removeAllRanges();
    }
  }, [onTextSelect]);

  return (
    <div
      ref={containerRef}
      onMouseUp={handleMouseUp}
      style={{
        padding: '16px 0',
        fontFamily: 'inherit',
        fontSize: '15px',
        lineHeight: '1.7',
        color: 'var(--rah-text-base)',
      }}
    >
      <MarkdownWithNodeTokens content={content} />
    </div>
  );
}
