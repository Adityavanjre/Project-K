"use client";

interface ConfirmDialogProps {
  open: boolean;
  title: string;
  message: string;
  confirmLabel?: string;
  cancelLabel?: string;
  onConfirm: () => void;
  onCancel: () => void;
}

export default function ConfirmDialog({
  open,
  title,
  message,
  confirmLabel = 'Confirm',
  cancelLabel = 'Cancel',
  onConfirm,
  onCancel,
}: ConfirmDialogProps) {
  if (!open) return null;

  return (
    <div
      className="modal-backdrop"
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        background: 'var(--rah-backdrop)',
        backdropFilter: 'blur(6px)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 9999,
        padding: '20px'
      }}
    >
      <div
        className="modal-content"
        style={{
          width: '420px',
          maxWidth: '100%',
          background: 'var(--rah-bg-modal)',
          border: '1px solid var(--rah-border-strong)',
          borderRadius: '12px',
          padding: '20px',
          boxShadow: 'var(--rah-shadow-modal)'
        }}
      >
        <div style={{ 
          fontSize: '15px', 
          fontWeight: 600, 
          color: 'var(--rah-text-base)', 
          marginBottom: '12px',
          letterSpacing: '0.01em',
          fontFamily: "'Geist', 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
        }}>
          {title}
        </div>
        <div style={{ 
          fontSize: '13px', 
          color: 'var(--rah-text-soft)', 
          marginBottom: '24px', 
          lineHeight: 1.6,
          wordWrap: 'break-word',
          overflowWrap: 'break-word'
        }}>
          {message}
        </div>
        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
          <button
            onClick={onCancel}
            style={{
              padding: '10px 16px',
              borderRadius: '8px',
              border: '1px solid var(--rah-border)',
              background: 'transparent',
              color: 'var(--rah-text-soft)',
              fontSize: '12px',
              fontWeight: 600,
              cursor: 'pointer',
              transition: 'all 0.2s'
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.background = 'var(--rah-bg-base)';
              e.currentTarget.style.borderColor = 'var(--rah-border-strong)';
              e.currentTarget.style.color = 'var(--rah-text-secondary)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.background = 'transparent';
              e.currentTarget.style.borderColor = 'var(--rah-border)';
              e.currentTarget.style.color = 'var(--rah-text-soft)';
            }}
          >
            {cancelLabel}
          </button>
          <button
            onClick={onConfirm}
            style={{
              padding: '10px 16px',
              borderRadius: '8px',
              border: '1px solid #dc2626',
              background: '#7f1d1d',
              color: '#fca5a5',
              fontSize: '12px',
              fontWeight: 600,
              cursor: 'pointer',
              transition: 'all 0.2s'
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.background = '#991b1b';
              e.currentTarget.style.borderColor = '#b91c1c';
              e.currentTarget.style.color = '#fecaca';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.background = '#7f1d1d';
              e.currentTarget.style.borderColor = '#dc2626';
              e.currentTarget.style.color = '#fca5a5';
            }}
          >
            {confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
}
