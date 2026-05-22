"use client";

import { useState, useEffect, type CSSProperties } from 'react';
import { openExternalUrl } from '@/utils/openExternalUrl';

type ActiveProfile = {
  llmProfile: string;
  llmModel: string | null;
  llmBaseUrl: string | null;
  embeddingProfile: string;
  embeddingModel: string | null;
  embeddingBaseUrl: string | null;
  embeddingDimensions: string;
};

export default function ApiKeysViewer() {
  const [status, setStatus] = useState<'checking' | 'configured' | 'not-set'>('checking');
  const [keyInput, setKeyInput] = useState('');
  const [maskedKey, setMaskedKey] = useState<string | null>(null);
  const [envPath, setEnvPath] = useState<string>('.env.local');
  const [openAiKeyWritable, setOpenAiKeyWritable] = useState(true);
  const [activeProfile, setActiveProfile] = useState<ActiveProfile | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    fetch('/api/settings/openai-key')
      .then(res => res.json())
      .then(data => {
        setStatus(data.configured ? 'configured' : 'not-set');
        setMaskedKey(data.maskedKey ?? null);
        setEnvPath(data.envPath ?? '.env.local');
        setOpenAiKeyWritable(data.openAiKeyWritable !== false);
        setActiveProfile(data.activeProfile ?? null);
      })
      .catch(() => setStatus('not-set'));
  }, []);

  const saveKey = async () => {
    setSaving(true);
    setMessage(null);
    setError(null);

    try {
      const response = await fetch('/api/settings/openai-key', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ key: keyInput }),
      });
      const payload = await response.json();
      if (!response.ok) {
        throw new Error(payload.error || 'Failed to save API key');
      }

      setStatus('configured');
      setMaskedKey(payload.maskedKey ?? null);
      setEnvPath(payload.envPath ?? envPath);
      setOpenAiKeyWritable(payload.openAiKeyWritable !== false);
      setActiveProfile(payload.activeProfile ?? activeProfile);
      setKeyInput('');
      setMessage('Saved to .env.local and updated the running app.');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save API key');
    } finally {
      setSaving(false);
    }
  };

  const removeKey = async () => {
    setSaving(true);
    setMessage(null);
    setError(null);

    try {
      const response = await fetch('/api/settings/openai-key', {
        method: 'DELETE',
      });
      const payload = await response.json();
      if (!response.ok) {
        throw new Error(payload.error || 'Failed to remove API key');
      }

      setStatus('not-set');
      setMaskedKey(null);
      setKeyInput('');
      setEnvPath(payload.envPath ?? envPath);
      setOpenAiKeyWritable(payload.openAiKeyWritable !== false);
      setActiveProfile(payload.activeProfile ?? activeProfile);
      setMessage('Removed from .env.local and cleared the running app key.');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to remove API key');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div style={containerStyle}>
      {activeProfile && (
        <div style={profileBoxStyle}>
          <div style={featuresHeaderStyle}>
            {openAiKeyWritable ? 'OpenAI profile active' : 'Local model profile active'}
          </div>
          <div style={profileGridStyle}>
            <div>
              <div style={profileLabelStyle}>Utility LLM</div>
              <code style={codeInlineStyle}>{activeProfile.llmProfile}</code>
              {activeProfile.llmModel && <span style={profileValueStyle}> {activeProfile.llmModel}</span>}
            </div>
            <div>
              <div style={profileLabelStyle}>Embeddings</div>
              <code style={codeInlineStyle}>{activeProfile.embeddingProfile}</code>
              {activeProfile.embeddingModel && <span style={profileValueStyle}> {activeProfile.embeddingModel}</span>}
            </div>
            <div>
              <div style={profileLabelStyle}>Embedding width</div>
              <span style={profileValueStyle}>{activeProfile.embeddingDimensions}</span>
            </div>
          </div>
          {!openAiKeyWritable && (
            <p style={profileNoteStyle}>
              This install is already configured for local models. OpenAI key entry is disabled here so the app does not drift away from the setup profile. To switch providers, edit <code style={codeInlineStyle}>{envPath}</code> and run <code style={codeInlineStyle}>npm run rebuild:embeddings</code>.
            </p>
          )}
        </div>
      )}

      {/* Features explanation */}
      {openAiKeyWritable && (
        <div style={featuresBoxStyle}>
        <div style={featuresHeaderStyle}>OpenAI API Key enables:</div>
        <ul style={featuresListStyle}>
          <li>Auto-generated descriptions for new nodes</li>
          <li>Edge explanation inference</li>
          <li>Semantic search via embeddings</li>
        </ul>
        <div style={noteStyle}>
          Without a key, you can still create and organise nodes manually.
        </div>
      </div>
      )}

      {/* Status */}
      {openAiKeyWritable ? (
        <div style={cardStyle}>
        <div style={cardHeaderStyle}>
          <span style={cardTitleStyle}>OpenAI API Key</span>
          <span style={{
            fontSize: 12,
            color: status === 'checking'
              ? 'var(--settings-muted)'
              : status === 'configured'
                ? 'var(--settings-text)'
                : 'var(--settings-danger)'
          }}>
            {status === 'configured' ? 'Configured' :
             status === 'checking' ? 'Checking...' : 'Not configured'}
          </span>
        </div>

        <div style={instructionsStyle}>
          <p style={{ margin: 0, marginBottom: 8 }}>
            Save your key here to write it into <code style={codeInlineStyle}>{envPath}</code>.
            You can still edit the file directly if you prefer.
          </p>
          <div style={codeBlockStyle}>
            <code>OPENAI_API_KEY=sk-your-key-here</code>
          </div>
          <label style={fieldLabelStyle}>
            {status === 'configured' ? 'Replace OpenAI API key' : 'OpenAI API key'}
          </label>
          <input
            type="password"
            value={keyInput}
            onChange={(e) => setKeyInput(e.target.value)}
            placeholder={status === 'configured' ? 'Paste a new key to replace the current one' : 'sk-...'}
            style={inputStyle}
            autoCapitalize="off"
            autoCorrect="off"
            spellCheck={false}
          />
          <div style={actionsStyle}>
            <button
              type="button"
              onClick={saveKey}
              disabled={saving || keyInput.trim().length === 0}
              style={{
                ...primaryButtonStyle,
                opacity: saving || keyInput.trim().length === 0 ? 0.5 : 1,
                cursor: saving || keyInput.trim().length === 0 ? 'not-allowed' : 'pointer',
              }}
            >
              {saving ? 'Saving…' : status === 'configured' ? 'Replace key' : 'Save key'}
            </button>
            <button
              type="button"
              onClick={removeKey}
              disabled={saving || status !== 'configured'}
              style={{
                ...secondaryButtonStyle,
                opacity: saving || status !== 'configured' ? 0.5 : 1,
                cursor: saving || status !== 'configured' ? 'not-allowed' : 'pointer',
              }}
            >
              Remove key
            </button>
          </div>
          {maskedKey && (
            <p style={{ margin: '10px 0 0', fontSize: 12, color: 'var(--settings-muted)' }}>
              Current key: <code style={codeInlineStyle}>{maskedKey}</code>
            </p>
          )}
          {message && (
            <p style={{ margin: '10px 0 0', fontSize: 12, color: 'var(--settings-text)' }}>
              {message}
            </p>
          )}
          {error && (
            <p style={{ margin: '10px 0 0', fontSize: 12, color: 'var(--settings-danger)' }}>
              {error}
            </p>
          )}
          <p style={{ margin: '10px 0 0', fontSize: 12, color: 'var(--settings-muted)' }}>
            This open-source build uses your own local key only. No Railway key path is used here.
          </p>
        </div>
      </div>
      ) : (
        <div style={cardStyle}>
          <div style={cardHeaderStyle}>
            <span style={cardTitleStyle}>OpenAI API Key</span>
            <span style={{ fontSize: 12, color: 'var(--settings-muted)' }}>Disabled</span>
          </div>
          <div style={instructionsStyle}>
            <p style={{ margin: 0 }}>
              This workspace is using the local model profile selected during setup. The app will call the configured OpenAI-compatible local endpoints for descriptions and embeddings instead of using an OpenAI API key.
            </p>
            {activeProfile?.llmBaseUrl && (
              <p style={{ margin: '10px 0 0', fontSize: 12, color: 'var(--settings-muted)' }}>
                Local endpoint: <code style={codeInlineStyle}>{activeProfile.llmBaseUrl}</code>
              </p>
            )}
          </div>
        </div>
      )}

      {/* Get key link */}
      {openAiKeyWritable && (
        <div style={helpStyle}>
        <button
          type="button"
          onClick={() => {
            void openExternalUrl('https://platform.openai.com/api-keys').catch((error) => {
              console.error('[ApiKeysViewer] Failed to open OpenAI API keys page', error);
              window.alert('Unable to open the OpenAI API keys page automatically.');
            });
          }}
          style={linkStyle}
        >
          Get your API key from OpenAI →
        </button>
      </div>
      )}
    </div>
  );
}

const containerStyle: CSSProperties = {
  padding: 24,
  height: '100%',
  overflow: 'auto',
};

const featuresBoxStyle: CSSProperties = {
  background: 'var(--settings-card-bg)',
  border: '1px solid var(--settings-border)',
  borderRadius: 8,
  padding: 16,
  marginBottom: 20,
};

const profileBoxStyle: CSSProperties = {
  background: 'var(--settings-card-bg)',
  border: '1px solid var(--settings-border)',
  borderRadius: 8,
  padding: 16,
  marginBottom: 20,
};

const profileGridStyle: CSSProperties = {
  display: 'grid',
  gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))',
  gap: 12,
};

const profileLabelStyle: CSSProperties = {
  fontSize: 11,
  color: 'var(--settings-muted)',
  marginBottom: 6,
};

const profileValueStyle: CSSProperties = {
  fontSize: 12,
  color: 'var(--settings-subtext)',
};

const profileNoteStyle: CSSProperties = {
  margin: '12px 0 0',
  fontSize: 12,
  color: 'var(--settings-muted)',
  lineHeight: 1.5,
};

const featuresHeaderStyle: CSSProperties = {
  fontSize: 13,
  fontWeight: 500,
  color: 'var(--settings-text)',
  marginBottom: 8,
};

const featuresListStyle: CSSProperties = {
  margin: 0,
  paddingLeft: 20,
  fontSize: 13,
  color: 'var(--settings-subtext)',
  lineHeight: 1.6,
};

const noteStyle: CSSProperties = {
  marginTop: 12,
  fontSize: 12,
  color: 'var(--settings-muted)',
  fontStyle: 'italic',
};

const cardStyle: CSSProperties = {
  background: 'var(--settings-card-bg)',
  border: '1px solid var(--settings-border)',
  borderRadius: 8,
  padding: 16,
  marginBottom: 12,
};

const cardHeaderStyle: CSSProperties = {
  display: 'flex',
  justifyContent: 'space-between',
  alignItems: 'center',
  marginBottom: 12,
};

const cardTitleStyle: CSSProperties = {
  fontSize: 13,
  fontWeight: 500,
  color: 'var(--settings-text)',
};

const instructionsStyle: CSSProperties = {
  fontSize: 13,
  color: 'var(--settings-subtext)',
  lineHeight: 1.5,
};

const fieldLabelStyle: CSSProperties = {
  display: 'block',
  fontSize: 12,
  fontWeight: 500,
  color: 'var(--settings-text)',
  marginBottom: 6,
};

const codeInlineStyle: CSSProperties = {
  background: 'var(--settings-code-bg)',
  padding: '2px 6px',
  borderRadius: 4,
  fontSize: 12,
  fontFamily: 'monospace',
  color: 'var(--settings-text)',
};

const codeBlockStyle: CSSProperties = {
  background: 'var(--settings-code-bg)',
  border: '1px solid var(--settings-border)',
  borderRadius: 6,
  padding: '10px 12px',
  fontSize: 13,
  fontFamily: 'monospace',
  color: 'var(--settings-text)',
  marginBottom: 8,
};

const inputStyle: CSSProperties = {
  width: '100%',
  background: 'var(--settings-code-bg)',
  border: '1px solid var(--settings-border)',
  borderRadius: 6,
  padding: '10px 12px',
  color: 'var(--settings-text)',
  fontSize: 13,
  fontFamily: 'monospace',
  marginBottom: 12,
};

const actionsStyle: CSSProperties = {
  display: 'flex',
  gap: 10,
  flexWrap: 'wrap',
};

const primaryButtonStyle: CSSProperties = {
  background: 'var(--settings-text)',
  color: 'var(--settings-bg)',
  border: '1px solid var(--settings-text)',
  borderRadius: 6,
  padding: '9px 14px',
  fontSize: 12,
  fontWeight: 600,
};

const secondaryButtonStyle: CSSProperties = {
  background: 'transparent',
  color: 'var(--settings-text)',
  border: '1px solid var(--settings-border-strong)',
  borderRadius: 6,
  padding: '9px 14px',
  fontSize: 12,
  fontWeight: 500,
};

const helpStyle: CSSProperties = {
  fontSize: 12,
  color: 'var(--settings-muted)',
};

const linkStyle: CSSProperties = {
  color: 'var(--settings-text)',
  textDecoration: 'none',
  background: 'transparent',
  border: '1px solid var(--settings-border-strong)',
  borderRadius: 6,
  padding: '10px 14px',
  cursor: 'pointer',
  font: 'inherit',
};
