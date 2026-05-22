"use client";

import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';

export default function SkillMarkdown({ content }: { content: string }) {
  return (
    <div className="skill-content" style={{ color: 'var(--rah-text-secondary)', fontSize: '13px', lineHeight: '1.6' }}>
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        components={{
          h1: ({ children }) => (
            <h1 style={{ fontSize: '18px', fontWeight: 600, color: 'var(--rah-text-active)', margin: '0 0 16px 0' }}>{children}</h1>
          ),
          h2: ({ children }) => (
            <h2 style={{ fontSize: '15px', fontWeight: 600, color: 'var(--rah-text-base)', margin: '20px 0 8px 0' }}>{children}</h2>
          ),
          h3: ({ children }) => (
            <h3 style={{ fontSize: '14px', fontWeight: 600, color: 'var(--rah-text-secondary)', margin: '16px 0 6px 0' }}>{children}</h3>
          ),
          p: ({ children }) => (
            <p style={{ margin: '0 0 12px 0' }}>{children}</p>
          ),
          ul: ({ children }) => (
            <ul style={{ margin: '0 0 12px 0', paddingLeft: '20px' }}>{children}</ul>
          ),
          ol: ({ children }) => (
            <ol style={{ margin: '0 0 12px 0', paddingLeft: '20px' }}>{children}</ol>
          ),
          li: ({ children }) => (
            <li style={{ margin: '0 0 4px 0' }}>{children}</li>
          ),
          code: ({ className, children, ...props }) => {
            const isInline = !className;
            if (isInline) {
              return (
                <code
                  style={{
                    background: 'var(--rah-bg-active)',
                    padding: '2px 6px',
                    borderRadius: '4px',
                    fontSize: '12px',
                    color: 'var(--rah-accent-green)',
                  }}
                  {...props}
                >
                  {children}
                </code>
              );
            }
            return (
              <code
                style={{
                  display: 'block',
                  background: 'var(--rah-bg-panel)',
                  padding: '12px',
                  borderRadius: '6px',
                  fontSize: '12px',
                  overflowX: 'auto',
                  margin: '0 0 12px 0',
                  color: 'var(--rah-text-soft)',
                  whiteSpace: 'pre-wrap',
                }}
                {...props}
              >
                {children}
              </code>
            );
          },
          pre: ({ children }) => (
            <pre style={{ margin: '0 0 12px 0' }}>{children}</pre>
          ),
          strong: ({ children }) => (
            <strong style={{ color: 'var(--rah-text-active)', fontWeight: 600 }}>{children}</strong>
          ),
          hr: () => (
            <hr style={{ border: 'none', borderTop: '1px solid var(--rah-border-strong)', margin: '16px 0' }} />
          ),
          blockquote: ({ children }) => (
            <blockquote
              style={{
                borderLeft: '3px solid var(--rah-border-strong)',
                paddingLeft: '12px',
                margin: '0 0 12px 0',
                color: 'var(--rah-text-muted)',
              }}
            >
              {children}
            </blockquote>
          ),
        }}
      >
        {content}
      </ReactMarkdown>
    </div>
  );
}
