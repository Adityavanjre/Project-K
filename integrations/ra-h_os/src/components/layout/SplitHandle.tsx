"use client";

import { useState, useCallback, useEffect } from 'react';

interface SplitHandleProps {
  onResize: (clientX: number) => void;
  title?: string;
}

export default function SplitHandle({
  onResize,
  title = 'Drag to resize panes',
}: SplitHandleProps) {
  const [isDragging, setIsDragging] = useState(false);
  const [isHovered, setIsHovered] = useState(false);

  const handleMouseDown = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    setIsDragging(true);
  }, []);

  useEffect(() => {
    if (!isDragging) return;

    const handleMouseMove = (e: MouseEvent) => {
      onResize(e.clientX);
    };

    const handleMouseUp = () => {
      setIsDragging(false);
    };

    document.addEventListener('mousemove', handleMouseMove);
    document.addEventListener('mouseup', handleMouseUp);
    document.body.style.cursor = 'col-resize';
    document.body.style.userSelect = 'none';

    return () => {
      document.removeEventListener('mousemove', handleMouseMove);
      document.removeEventListener('mouseup', handleMouseUp);
      document.body.style.cursor = '';
      document.body.style.userSelect = '';
    };
  }, [isDragging, onResize]);

  return (
    <div
      onMouseDown={handleMouseDown}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      title={title}
      style={{
        width: '4px',
        cursor: 'col-resize',
        background: isDragging ? 'var(--rah-accent-green)' : (isHovered ? 'var(--rah-bg-active)' : 'transparent'),
        transition: isDragging ? 'none' : 'background 0.15s ease',
        flexShrink: 0,
        borderRadius: '999px',
      }}
    />
  );
}
