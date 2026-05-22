"use client";

import { useState, useCallback, useMemo, useRef } from 'react';
import { createPortal } from 'react-dom';

interface QuickAddSubmitPayload {
  input: string;
  mode: 'link' | 'text';
  description?: string;
}

interface QuickAddInputProps {
  onSubmit: (payload: QuickAddSubmitPayload) => Promise<void>;
  isOpen?: boolean;
  onClose?: () => void;
}

type SourceType = 'link' | 'text' | 'upload';

function detectSourceType(raw: string): Exclude<SourceType, 'upload'> {
  const trimmed = raw.trim();
  if (!trimmed) return 'text';
  const isSingleLine = !trimmed.includes('\n');
  if (isSingleLine) {
    if (/^https?:\/\//i.test(trimmed)) return 'link';
  }
  return 'text';
}

const SOURCE_LABELS: Record<SourceType, string> = {
  link: 'Link',
  text: 'Text',
  upload: 'Upload',
};

const SOURCE_COLORS: Record<SourceType, string> = {
  link: '#3b82f6',
  text: '#22c55e',
  upload: '#f59e0b',
};

export default function QuickAddInput({ onSubmit, isOpen, onClose }: QuickAddInputProps) {
  const [input, setInput] = useState('');
  const [isPosting, setIsPosting] = useState(false);
  const [isExpandedInternal, setIsExpandedInternal] = useState(false);
  const [dragOver, setDragOver] = useState(false);
  const [uploadedFile, setUploadedFile] = useState<File | null>(null);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [sourceOverride, setSourceOverride] = useState<Exclude<SourceType, 'upload'> | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  const isControlled = isOpen !== undefined;
  const isExpanded = isControlled ? isOpen : isExpandedInternal;
  const setIsExpanded = isControlled
    ? (value: boolean) => { if (!value && onClose) onClose(); }
    : setIsExpandedInternal;

  const detectedSource = useMemo(() => detectSourceType(input), [input]);
  const effectiveSource: SourceType = uploadedFile ? 'upload' : (sourceOverride ?? detectedSource);

  const handleFileUpload = useCallback(async (file: File) => {
    setIsPosting(true);
    setUploadError(null);
    try {
      const formData = new FormData();
      formData.append('file', file);
      const response = await fetch('/api/extract/pdf/upload', {
        method: 'POST',
        body: formData,
      });
      const result = await response.json();
      if (!response.ok || !result.success) {
        throw new Error(result.error || 'Upload failed');
      }
      setUploadedFile(null);
      setInput('');
      setSourceOverride(null);
      setIsExpanded(false);
    } catch (error) {
      console.error('[QuickAddInput] Upload error:', error);
      setUploadError(error instanceof Error ? error.message : 'Upload failed');
    } finally {
      setIsPosting(false);
    }
  }, []);

  const handleSubmit = async () => {
    if (uploadedFile) {
      await handleFileUpload(uploadedFile);
      return;
    }
    if (!input.trim() || isPosting) return;
    setIsPosting(true);
    try {
      await onSubmit({
        input: input.trim(),
        mode: effectiveSource === 'link' ? 'link' : 'text',
      });
      setInput('');
      setSourceOverride(null);
      setIsExpanded(false);
    } catch (error) {
      console.error('[QuickAddInput] Submit error:', error);
    } finally {
      setIsPosting(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) {
      e.preventDefault();
      handleSubmit();
    }
    if (e.key === 'Escape') {
      setIsExpanded(false);
      setInput('');
      setUploadedFile(null);
      setUploadError(null);
      setSourceOverride(null);
    }
  };

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setDragOver(true);
  }, []);

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setDragOver(false);
  }, []);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setDragOver(false);
    setUploadError(null);
    const file = e.dataTransfer?.files[0];
    if (!file) return;
    if (file.type !== 'application/pdf' && !file.name.toLowerCase().endsWith('.pdf')) {
      setUploadError('Only PDF files are supported');
      return;
    }
    if (file.size > 50 * 1024 * 1024) {
      setUploadError(`File too large (${Math.round(file.size / 1024 / 1024)}MB). Max 50MB.`);
      return;
    }
    setUploadedFile(file);
    setInput('');
    setSourceOverride(null);
  }, []);

  const hasContent = input.trim() || uploadedFile;

  const handleClose = () => {
    setIsExpanded(false);
    setInput('');
    setUploadedFile(null);
    setUploadError(null);
    setSourceOverride(null);
  };

  const handleSourceSelect = (source: Exclude<SourceType, 'upload'>) => {
    setSourceOverride(source);
    setUploadedFile(null);
    setUploadError(null);
  };

  const handleUploadClick = () => {
    setUploadError(null);
    fileInputRef.current?.click();
  };

  const handleFileInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;
    if (file.type !== 'application/pdf' && !file.name.toLowerCase().endsWith('.pdf')) {
      setUploadError('Only PDF files are supported');
      event.target.value = '';
      return;
    }
    if (file.size > 50 * 1024 * 1024) {
      setUploadError(`File too large (${Math.round(file.size / 1024 / 1024)}MB). Max 50MB.`);
      event.target.value = '';
      return;
    }
    setUploadedFile(file);
    setInput('');
    setSourceOverride(null);
    event.target.value = '';
  };

  if (!isExpanded) {
    if (isControlled) return null;
    return (
      <button
        onClick={() => setIsExpanded(true)}
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          gap: '8px',
          padding: '10px 16px',
          background: 'rgba(34, 197, 94, 0.1)',
          border: '1px solid rgba(34, 197, 94, 0.3)',
          borderRadius: '8px',
          color: '#22c55e',
          fontSize: '11px',
          fontWeight: 600,
          letterSpacing: '0.08em',
          textTransform: 'uppercase',
          cursor: 'pointer',
          transition: 'all 0.2s ease',
          whiteSpace: 'nowrap',
          boxShadow: '0 0 12px rgba(34, 197, 94, 0.15)'
        }}
        onMouseEnter={(e) => {
          e.currentTarget.style.background = 'rgba(34, 197, 94, 0.2)';
          e.currentTarget.style.borderColor = '#22c55e';
        }}
        onMouseLeave={(e) => {
          e.currentTarget.style.background = 'rgba(34, 197, 94, 0.1)';
          e.currentTarget.style.borderColor = 'rgba(34, 197, 94, 0.3)';
        }}
      >
        <span style={{
          width: '18px', height: '18px', borderRadius: '50%',
          background: '#22c55e', color: '#0a0a0a',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: '12px', fontWeight: 700
        }}>+</span>
        Add Stuff
      </button>
    );
  }

  const modalContent = (
    <div
      className="qa-card"
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
      onClick={(e) => e.stopPropagation()}
    >
      <input
        ref={fileInputRef}
        type="file"
        accept=".pdf,application/pdf"
        style={{ display: 'none' }}
        onChange={handleFileInputChange}
      />

      {uploadedFile && (
        <div className="qa-file-row">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#ef4444" strokeWidth="1.5">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" strokeLinecap="round" strokeLinejoin="round"/>
            <polyline points="14 2 14 8 20 8" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
          <span className="qa-file-name">{uploadedFile.name}</span>
          <span className="qa-file-size">
            {uploadedFile.size < 1024 * 1024
              ? `${Math.round(uploadedFile.size / 1024)} KB`
              : `${(uploadedFile.size / 1024 / 1024).toFixed(1)} MB`}
          </span>
          <button onClick={() => { setUploadedFile(null); setUploadError(null); }} className="qa-file-remove">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M18 6L6 18M6 6l12 12" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </button>
        </div>
      )}

      {uploadError && (
        <div className="qa-error">{uploadError}</div>
      )}

      {!uploadedFile && (
        <div className={`qa-input-area ${dragOver ? 'dragging' : ''}`}>
          {dragOver && (
            <div className="qa-drag-overlay">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#22c55e" strokeWidth="1.5">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" strokeLinecap="round" strokeLinejoin="round"/>
                <polyline points="14 2 14 8 20 8" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
              <span>Drop PDF</span>
            </div>
          )}
          <textarea
            value={input}
            onChange={(e) => {
              const nextValue = e.target.value;
              setInput(nextValue);
              if (nextValue.trim()) {
                setUploadedFile(null);
              }
              if (!nextValue.trim()) {
                setSourceOverride(null);
              }
            }}
            onKeyDown={handleKeyDown}
            placeholder="Paste a link, write/paste text, or upload a PDF..."
            disabled={isPosting}
            autoFocus
            className="qa-textarea"
            style={{ opacity: dragOver ? 0.2 : 1 }}
          />
        </div>
      )}

      <div className="qa-footer">
        <div className="qa-footer-left">
          <div className="qa-source-row">
            <button
              type="button"
              className={`qa-control-chip qa-source-chip ${effectiveSource === 'link' ? 'active' : ''}`}
              onClick={() => handleSourceSelect('link')}
            >
              {SOURCE_LABELS.link}
            </button>
            <button
              type="button"
              className={`qa-control-chip qa-source-chip ${effectiveSource === 'text' ? 'active' : ''}`}
              onClick={() => handleSourceSelect('text')}
            >
              {SOURCE_LABELS.text}
            </button>
            <button
              type="button"
              className={`qa-control-chip qa-source-chip ${effectiveSource === 'upload' ? 'active upload' : 'upload'}`}
              onClick={handleUploadClick}
            >
              {SOURCE_LABELS.upload}
            </button>
          </div>
        </div>
        <div className="qa-footer-right">
          <span className="qa-type-pill" style={{
            color: SOURCE_COLORS[effectiveSource],
            borderColor: SOURCE_COLORS[effectiveSource] + '30',
            background: SOURCE_COLORS[effectiveSource] + '0a',
          }}>
            {effectiveSource === 'upload' ? 'Process as Upload' : `Process as ${SOURCE_LABELS[effectiveSource]}`}
          </span>
          <span className="qa-hint">
            {uploadedFile
              ? 'Ready to upload'
              : <><kbd>{'\u2318\u21B5'}</kbd><span className="qa-hint-sep">send</span><kbd>esc</kbd><span className="qa-hint-sep">close</span></>
            }
          </span>
        </div>
        <button
          onClick={handleSubmit}
          disabled={!hasContent || isPosting}
          className={`qa-submit ${hasContent && !isPosting ? 'active' : ''}`}
        >
          {isPosting ? (
            <span className="qa-spinner" />
          ) : (
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <path d="M5 12h14"/>
              <path d="M12 5l7 7-7 7"/>
            </svg>
          )}
        </button>
      </div>

      <style jsx>{`
        .qa-card {
          display: flex;
          flex-direction: column;
          gap: 0;
          background: #111111;
          border-radius: 16px;
          border: 1px solid rgba(255, 255, 255, 0.06);
          overflow: hidden;
          box-shadow:
            0 0 0 1px rgba(255, 255, 255, 0.03),
            0 24px 80px -12px rgba(0, 0, 0, 0.8),
            0 0 60px -10px rgba(34, 197, 94, 0.06);
          animation: qaIn 250ms cubic-bezier(0.16, 1, 0.3, 1);
          width: ${isControlled ? '600px' : 'auto'};
          max-width: ${isControlled ? '90vw' : 'none'};
        }

        .qa-input-area {
          position: relative;
          transition: all 0.2s ease;
        }

        .qa-input-area.dragging {
          background: rgba(34, 197, 94, 0.03);
        }

        .qa-drag-overlay {
          position: absolute;
          inset: 0;
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 8px;
          color: #22c55e;
          font-size: 13px;
          font-weight: 500;
          z-index: 10;
          pointer-events: none;
        }

        .qa-textarea {
          width: 100%;
          min-height: 120px;
          max-height: 300px;
          padding: 20px 22px;
          background: transparent;
          border: none;
          color: #e5e5e5;
          font-size: 15px;
          font-family: inherit;
          outline: none;
          resize: none;
          line-height: 1.6;
          transition: opacity 0.15s ease;
        }

        .qa-textarea::placeholder {
          color: #444;
        }

        .qa-file-row {
          display: flex;
          align-items: center;
          gap: 10px;
          padding: 16px 20px;
          border-bottom: 1px solid rgba(255, 255, 255, 0.04);
        }

        .qa-file-name {
          flex: 1;
          min-width: 0;
          color: #e5e5e5;
          font-size: 13px;
          font-weight: 500;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }

        .qa-file-size {
          color: #555;
          font-size: 11px;
          flex-shrink: 0;
        }

        .qa-file-remove {
          padding: 4px;
          background: transparent;
          border: none;
          color: #555;
          cursor: pointer;
          border-radius: 4px;
          display: flex;
          transition: color 0.15s ease;
        }

        .qa-file-remove:hover {
          color: #ef4444;
        }

        .qa-error {
          padding: 10px 20px;
          color: #ef4444;
          font-size: 12px;
          background: rgba(239, 68, 68, 0.06);
          border-bottom: 1px solid rgba(239, 68, 68, 0.1);
        }

        .qa-footer {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 12px 14px 12px 18px;
          border-top: 1px solid rgba(255, 255, 255, 0.04);
        }

        .qa-source-row {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: 8px;
        }

        .qa-control-chip {
          border: 1px solid rgba(255, 255, 255, 0.08);
          background: rgba(255, 255, 255, 0.03);
          color: #8a8a8a;
          border-radius: 10px;
          padding: 6px 12px;
          font-size: 11px;
          font-weight: 600;
          letter-spacing: 0.04em;
          text-transform: uppercase;
          cursor: pointer;
          transition: all 0.15s ease;
        }

        .qa-control-chip:hover {
          border-color: rgba(255, 255, 255, 0.16);
          color: #cfcfcf;
        }

        .qa-source-chip.active {
          color: #f5f5f5;
          border-color: rgba(255, 255, 255, 0.2);
          background: rgba(255, 255, 255, 0.08);
        }

        .qa-source-chip.upload.active {
          border-color: rgba(245, 158, 11, 0.35);
          background: rgba(245, 158, 11, 0.12);
          color: #fbbf24;
        }

        .qa-footer-left {
          display: flex;
          align-items: center;
          gap: 12px;
          min-width: 0;
        }

        .qa-footer-right {
          display: flex;
          align-items: center;
          gap: 10px;
          margin-left: auto;
        }

        .qa-type-pill {
          display: inline-flex;
          align-items: center;
          font-size: 10px;
          font-weight: 600;
          letter-spacing: 0.04em;
          padding: 2px 8px;
          border-radius: 4px;
          border: 1px solid;
          text-transform: uppercase;
          animation: pillIn 150ms ease-out;
        }

        .qa-hint {
          font-size: 11px;
          color: #3a3a3a;
          display: flex;
          align-items: center;
          gap: 4px;
        }

        .qa-hint kbd {
          display: inline-flex;
          align-items: center;
          padding: 1px 5px;
          background: rgba(255, 255, 255, 0.04);
          border-radius: 3px;
          font-size: 10px;
          font-family: inherit;
          color: #444;
        }

        .qa-hint-sep {
          margin: 0 1px;
          color: #333;
        }

        .qa-submit {
          width: 34px;
          height: 34px;
          display: flex;
          align-items: center;
          justify-content: center;
          padding: 0;
          background: rgba(255, 255, 255, 0.04);
          border: none;
          border-radius: 10px;
          color: #333;
          cursor: default;
          transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
        }

        .qa-submit.active {
          background: #22c55e;
          color: #052e16;
          cursor: pointer;
        }

        .qa-submit.active:hover {
          background: #16a34a;
          transform: scale(1.05);
          box-shadow: 0 0 20px rgba(34, 197, 94, 0.3);
        }

        .qa-spinner {
          width: 14px;
          height: 14px;
          border: 2px solid #052e16;
          border-top-color: transparent;
          border-radius: 50%;
          animation: qaSpin 0.8s linear infinite;
        }

        @keyframes qaIn {
          from {
            opacity: 0;
            transform: scale(0.97) translateY(-6px);
          }
          to {
            opacity: 1;
            transform: scale(1) translateY(0);
          }
        }

        @keyframes pillIn {
          from { opacity: 0; transform: scale(0.9); }
          to { opacity: 1; transform: scale(1); }
        }

        @keyframes qaSpin {
          to { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  );

  if (isControlled) {
    const backdrop = (
      <div className="qa-backdrop" onClick={handleClose}>
        <div className="qa-container">
          {modalContent}
        </div>
        <style jsx>{`
          .qa-backdrop {
            position: fixed;
            inset: 0;
            background: rgba(0, 0, 0, 0.7);
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 9999;
            animation: qaFadeIn 200ms ease-out;
          }
          .qa-container {
            width: 100%;
            max-width: 600px;
            height: fit-content;
          }
          @keyframes qaFadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
          }
        `}</style>
      </div>
    );
    return typeof window !== 'undefined' ? createPortal(backdrop, document.body) : null;
  }

  return (
    <div style={{ position: 'absolute', top: '60px', left: '20px', right: '20px', zIndex: 100 }}>
      {modalContent}
    </div>
  );
}
