"use client";

import { useEffect, useState, type CSSProperties } from 'react';
import { createPortal } from 'react-dom';
import ApiKeysViewer from './ApiKeysViewer';
import ExternalAgentsPanel from './ExternalAgentsPanel';

export type SettingsTab = 'apikeys' | 'agents';

interface SettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
  initialTab?: SettingsTab;
}

const DEFAULT_TAB: SettingsTab = 'apikeys';
const TAB_ORDER: SettingsTab[] = ['apikeys', 'agents'];

const TAB_LABELS: Record<SettingsTab, string> = {
  apikeys: 'API Keys',
  agents: 'Agents',
};

function isSettingsTab(value: unknown): value is SettingsTab {
  return typeof value === 'string' && TAB_ORDER.includes(value as SettingsTab);
}

export default function SettingsModal({ isOpen, onClose, initialTab }: SettingsModalProps) {
  const [activeTab, setActiveTab] = useState<SettingsTab>(DEFAULT_TAB);

  useEffect(() => {
    if (!isOpen) return;
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    window.addEventListener('keydown', handleEscape);
    return () => window.removeEventListener('keydown', handleEscape);
  }, [isOpen, onClose]);

  useEffect(() => {
    if (!isOpen) return;
    setActiveTab(isSettingsTab(initialTab) ? initialTab : DEFAULT_TAB);
  }, [initialTab, isOpen]);

  if (!isOpen) return null;

  return createPortal(
    <div style={backdropStyle} onClick={onClose}>
      <div style={modalStyle} onClick={(e) => e.stopPropagation()}>
        {/* Sidebar */}
        <div style={sidebarStyle}>
          <div style={logoStyle}>Settings</div>

          <nav style={navStyle}>
            {TAB_ORDER.map((tab) => (
              <div
                key={tab}
                onClick={() => setActiveTab(tab)}
                style={{
                  ...navItemStyle,
                  color: activeTab === tab ? 'var(--settings-text)' : 'var(--settings-muted)',
                  background: activeTab === tab ? 'var(--settings-active-bg)' : 'transparent',
                  border: activeTab === tab ? '1px solid var(--settings-active-border)' : '1px solid transparent',
                }}
              >
                {TAB_LABELS[tab]}
              </div>
            ))}
          </nav>

          <div style={userSectionStyle}>
            <div style={userLabelStyle}>Local Mode</div>
            <div style={userEmailStyle}>Bring your own API keys for descriptions, embeddings, and agent workflows.</div>
          </div>
        </div>

        {/* Content */}
        <div style={contentStyle}>
          <div style={headerStyle}>
            <h2 style={titleStyle}>{TAB_LABELS[activeTab]}</h2>
            <button
              onClick={onClose}
              style={closeBtnStyle}
              onMouseEnter={(e) => { e.currentTarget.style.color = 'var(--settings-text)'; }}
              onMouseLeave={(e) => { e.currentTarget.style.color = 'var(--settings-muted)'; }}
            >
              ×
            </button>
          </div>
          <div style={contentAreaStyle}>
            {activeTab === 'apikeys' && <ApiKeysViewer />}
            {activeTab === 'agents' && <ExternalAgentsPanel />}
          </div>
        </div>
      </div>
    </div>,
    document.body
  );
}

// Styles
const backdropStyle: CSSProperties = {
  position: 'fixed',
  inset: 0,
  background: 'var(--rah-backdrop)',
  backdropFilter: 'blur(8px)',
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  zIndex: 1000,
};

const modalStyle: CSSProperties = {
  width: '88vw',
  height: '90vh',
  maxWidth: '1400px',
  background: 'var(--settings-bg)',
  border: '1px solid var(--settings-border)',
  borderRadius: '12px',
  boxShadow: 'var(--rah-shadow-modal)',
  display: 'flex',
  overflow: 'hidden',
};

const sidebarStyle: CSSProperties = {
  width: '200px',
  background: 'var(--settings-sidebar-bg)',
  borderRight: '1px solid var(--settings-border)',
  display: 'flex',
  flexDirection: 'column',
  padding: '20px 0',
};

const logoStyle: CSSProperties = {
  padding: '0 20px 20px',
  fontSize: '15px',
  fontWeight: 600,
  color: 'var(--settings-text)',
  letterSpacing: '-0.01em',
};

const navStyle: CSSProperties = {
  flex: 1,
  display: 'flex',
  flexDirection: 'column',
  gap: '6px',
  padding: '0 12px',
};

const navItemStyle: CSSProperties = {
  padding: '10px 12px',
  fontSize: '13px',
  cursor: 'pointer',
  transition: 'all 0.15s ease',
  borderRadius: '8px',
};

const userSectionStyle: CSSProperties = {
  padding: '16px 20px',
  borderTop: '1px solid var(--settings-border)',
  display: 'flex',
  flexDirection: 'column',
  gap: '8px',
};

const userLabelStyle: CSSProperties = {
  fontSize: '10px',
  fontWeight: 500,
  textTransform: 'uppercase',
  letterSpacing: '0.05em',
  color: 'var(--settings-muted)',
};

const userEmailStyle: CSSProperties = {
  fontSize: '12px',
  color: 'var(--settings-subtext)',
  wordBreak: 'break-all',
};

const signOutBtnStyle: CSSProperties = {
  marginTop: '4px',
  padding: '8px 12px',
  background: 'transparent',
  color: 'var(--settings-text)',
  border: '1px solid var(--settings-border-strong)',
  borderRadius: '6px',
  fontSize: '12px',
  fontWeight: 500,
  cursor: 'pointer',
  transition: 'background 0.15s ease, border-color 0.15s ease',
};

const contentStyle: CSSProperties = {
  flex: 1,
  display: 'flex',
  flexDirection: 'column',
  minWidth: 0,
};

const headerStyle: CSSProperties = {
  padding: '16px 24px',
  borderBottom: '1px solid var(--settings-border)',
  display: 'flex',
  justifyContent: 'space-between',
  alignItems: 'center',
};

const titleStyle: CSSProperties = {
  margin: 0,
  fontSize: '14px',
  fontWeight: 500,
  color: 'var(--settings-text)',
};

const closeBtnStyle: CSSProperties = {
  background: 'none',
  border: 'none',
  color: 'var(--settings-muted)',
  fontSize: '20px',
  cursor: 'pointer',
  padding: '4px 8px',
  lineHeight: 1,
  transition: 'color 0.15s ease',
};

const contentAreaStyle: CSSProperties = {
  flex: 1,
  overflow: 'hidden',
};
