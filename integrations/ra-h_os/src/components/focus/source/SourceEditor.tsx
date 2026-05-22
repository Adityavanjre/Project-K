"use client";

import { useEditor, EditorContent } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import { Markdown } from 'tiptap-markdown';
import { useEffect } from 'react';

interface SourceEditorProps {
  value: string;
  onChange: (value: string) => void;
  disabled?: boolean;
}

function getMarkdown(editor: ReturnType<typeof useEditor>): string {
  if (!editor) return '';
  // tiptap-markdown attaches getMarkdown to storage at runtime
  const storage = editor.storage as Record<string, any>;
  return storage?.markdown?.getMarkdown?.() ?? editor.getText();
}

export default function SourceEditor({ value, onChange, disabled = false }: SourceEditorProps) {
  const editor = useEditor({
    immediatelyRender: false,
    extensions: [
      StarterKit,
      Markdown.configure({
        html: false,
        transformPastedText: true,
        transformCopiedText: true,
      }),
    ],
    content: value,
    editable: !disabled,
    onUpdate({ editor }) {
      onChange(getMarkdown(editor));
    },
  });

  useEffect(() => {
    editor?.setEditable(!disabled);
  }, [editor, disabled]);

  // Re-sync if content changes externally (e.g. cancelled and re-opened)
  useEffect(() => {
    if (!editor || editor.isFocused) return;
    const current = getMarkdown(editor);
    if (current !== value) {
      // setContent is overridden by tiptap-markdown to parse markdown
      editor.commands.setContent(value, { emitUpdate: false });
    }
  }, [editor, value]);

  return (
    <>
      <EditorContent editor={editor} style={{ outline: 'none' }} />
      <style>{`
        .tiptap {
          outline: none;
          min-height: 200px;
          color: var(--rah-text-base);
          font-family: inherit;
          font-size: 15px;
          line-height: 1.7;
          caret-color: var(--rah-text-base);
        }

        .tiptap p {
          margin: 0 0 0.85em 0;
        }

        .tiptap p:last-child {
          margin-bottom: 0;
        }

        .tiptap h1, .tiptap h2, .tiptap h3, .tiptap h4 {
          font-weight: 600;
          line-height: 1.3;
          margin: 1.1em 0 0.3em 0;
          color: var(--rah-text-active);
        }

        .tiptap h1 { font-size: 22px; }
        .tiptap h2 { font-size: 18px; }
        .tiptap h3 { font-size: 16px; }
        .tiptap h4 { font-size: 15px; }

        .tiptap strong { font-weight: 600; color: var(--rah-text-active); }
        .tiptap em { font-style: italic; }

        .tiptap ul, .tiptap ol {
          padding-left: 1.3em;
          margin: 0 0 0.85em 0;
        }

        .tiptap li { margin-bottom: 0.2em; }
        .tiptap li p { margin: 0; }

        .tiptap blockquote {
          border-left: 2px solid var(--rah-border-strong);
          margin: 0 0 0.85em 0;
          padding-left: 1em;
          color: var(--rah-text-soft);
          font-style: italic;
        }

        .tiptap code {
          font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
          font-size: 11px;
          background: var(--rah-bg-surface);
          border: 1px solid var(--rah-border);
          border-radius: 3px;
          padding: 1px 4px;
          color: var(--rah-text-soft);
        }

        .tiptap pre {
          background: var(--rah-bg-surface);
          border: 1px solid var(--rah-border);
          border-radius: 6px;
          padding: 12px;
          margin: 0 0 0.85em 0;
          overflow-x: auto;
        }

        .tiptap pre code {
          background: none;
          border: none;
          padding: 0;
          font-size: 12px;
        }

        .tiptap hr {
          border: none;
          border-top: 1px solid var(--rah-border);
          margin: 1.4em 0;
        }
      `}</style>
    </>
  );
}
