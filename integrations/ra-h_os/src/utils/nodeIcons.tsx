"use client";

import { useState } from 'react';
import { Video, FileText, File, Globe } from 'lucide-react';
import { Node } from '@/types/database';
import { normalizeNodeLink } from '@/utils/nodeLink';

interface FaviconIconProps {
  domain: string;
  size?: number;
}

const FaviconIcon = ({ domain, size = 16 }: FaviconIconProps) => {
  const [failed, setFailed] = useState(false);

  if (failed) {
    return <Globe size={size} color="#94a3b8" />;
  }

  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={`https://www.google.com/s2/favicons?domain=${domain}&sz=${size}`}
      width={size}
      height={size}
      alt=""
      referrerPolicy="no-referrer"
      onError={() => setFailed(true)}
    />
  );
};

/**
 * Resolve the icon for a node.
 *
 * Priority:
 * 1. URL-derived icon (favicon, YouTube, PDF) — if node has a link
 * 2. Fallback to generic File icon
 *
 * @param node - The database node
 * @param size - Icon size in px (default 16)
 */
export function getNodeIcon(
  node: Node,
  size: number = 16,
): React.ReactElement {
  // If node has a link, use URL-derived icon (primary)
  if (node.link) {
    const normalizedLink = normalizeNodeLink(node.link);
    const url = (normalizedLink || node.link).toLowerCase();

    // YouTube videos
    if (url.includes('youtube.com') || url.includes('youtu.be')) {
      return <Video size={size} color="#FF0000" />;
    }

    // PDFs and papers
    if (url.endsWith('.pdf') || node.metadata?.type === 'paper') {
      return <FileText size={size} color="#94a3b8" />;
    }

    // Website favicon with graceful fallback
    try {
      const domain = new URL(normalizedLink || node.link).hostname;
      return <FaviconIcon domain={domain} size={size} />;
    } catch {
      return <Globe size={size} color="#94a3b8" />;
    }
  }

  // Fallback
  return <File size={size} color="#94a3b8" />;
}
