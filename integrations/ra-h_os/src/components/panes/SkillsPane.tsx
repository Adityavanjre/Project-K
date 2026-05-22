"use client";

import { useCallback, useEffect, useRef, useState } from 'react';
import { ArrowLeft, Brain } from 'lucide-react';
import PaneHeader from './PaneHeader';
import type { BasePaneProps } from './types';
import type { FocusedSkill, Skill, SkillMeta } from '@/types/skills';
import SkillCard from '@/components/skills/SkillCard';
import SkillMarkdown from '@/components/skills/SkillMarkdown';

interface SkillsPaneProps extends BasePaneProps {
  focusedSkill?: FocusedSkill | null;
  onFocusSkill?: (skill: FocusedSkill | null) => void;
  autoOpenSkillName?: string | null;
  onAutoOpenHandled?: () => void;
}

export default function SkillsPane({
  slot,
  onCollapse,
  onSwapPanes,
  tabBar,
  focusedSkill,
  onFocusSkill,
  autoOpenSkillName,
  onAutoOpenHandled,
}: SkillsPaneProps) {
  const [skills, setSkills] = useState<SkillMeta[]>([]);
  const [selectedSkill, setSelectedSkill] = useState<Skill | null>(null);
  const [loading, setLoading] = useState(true);
  const [deleting, setDeleting] = useState<string | null>(null);
  const detailScrollRef = useRef<HTMLDivElement>(null);
  const isSelectedSkillFocused = !!selectedSkill && focusedSkill?.name === selectedSkill.name;

  const fetchSkills = useCallback(async () => {
    try {
      const res = await fetch('/api/skills');
      const data = await res.json();
      if (data.success) {
        setSkills(data.data);
      }
    } catch (err) {
      console.error('[SkillsPane] Failed to fetch skills:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  const handleSelectSkill = useCallback(async (name: string) => {
    try {
      const res = await fetch(`/api/skills/${encodeURIComponent(name)}`);
      const data = await res.json();
      if (data.success) {
        setSelectedSkill(data.data);
        onFocusSkill?.(data.data);
      }
    } catch (err) {
      console.error('[SkillsPane] Failed to fetch skill:', err);
    }
  }, [onFocusSkill]);

  useEffect(() => {
    fetchSkills();

    const handleSkillUpdated = () => {
      void fetchSkills();
    };
    window.addEventListener('skills:updated', handleSkillUpdated);

    return () => {
      window.removeEventListener('skills:updated', handleSkillUpdated);
    };
  }, [fetchSkills]);

  useEffect(() => {
    if (selectedSkill && detailScrollRef.current) {
      detailScrollRef.current.scrollTo({ top: 0, behavior: 'auto' });
    }
  }, [selectedSkill?.name]);

  useEffect(() => {
    if (!autoOpenSkillName || loading || selectedSkill) {
      return;
    }

    void (async () => {
      await handleSelectSkill(autoOpenSkillName);
      onAutoOpenHandled?.();
    })();
  }, [autoOpenSkillName, handleSelectSkill, loading, onAutoOpenHandled, selectedSkill]);

  const handleBack = () => {
    setSelectedSkill(null);
    onFocusSkill?.(null);
  };

  const handleDeleteSkill = async (name: string, e: React.MouseEvent<HTMLButtonElement>) => {
    e.stopPropagation();
    if (!confirm(`Delete skill "${name}"?`)) return;

    setDeleting(name);
    try {
      const res = await fetch(`/api/skills/${encodeURIComponent(name)}`, { method: 'DELETE' });
      const data = await res.json();
      if (data.success) {
        await fetchSkills();
        if (selectedSkill?.name === name) {
          setSelectedSkill(null);
        }
        if (focusedSkill?.name === name) {
          onFocusSkill?.(null);
        }
      }
    } catch (err) {
      console.error('[SkillsPane] Failed to delete skill:', err);
    } finally {
      setDeleting(null);
    }
  };

  return (
    <div
      style={{
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        background: 'transparent',
        overflow: 'hidden',
      }}
    >
      <PaneHeader slot={slot} onCollapse={onCollapse} onSwapPanes={onSwapPanes} tabBar={tabBar}>
        {selectedSkill ? (
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <button
              type="button"
              onClick={handleBack}
              style={{
                background: 'none',
                border: 'none',
                color: 'var(--rah-text-soft)',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                padding: '4px',
                borderRadius: '4px',
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.color = 'var(--rah-text-secondary)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.color = 'var(--rah-text-soft)';
              }}
            >
              <ArrowLeft size={16} />
            </button>
            <span style={{ color: 'var(--rah-text-base)', fontSize: '13px', fontWeight: 500 }}>{selectedSkill.name}</span>
          </div>
        ) : (
          <span style={{ color: 'var(--rah-text-muted)', fontSize: '11px' }}>{skills.length} skills</span>
        )}
      </PaneHeader>

      <div style={{ flex: 1, minHeight: 0, overflow: 'auto', padding: '12px' }} ref={detailScrollRef}>
        {loading ? (
          <div style={{ color: 'var(--rah-text-muted)', fontSize: '13px', textAlign: 'center', paddingTop: '24px' }}>Loading...</div>
        ) : selectedSkill ? (
          <div style={{ width: '100%', maxWidth: '980px', margin: '0 auto' }}>
            <div style={{ marginBottom: '12px' }}>
              <div style={{ color: 'var(--rah-text-active)', fontSize: '16px', fontWeight: 600 }}>{selectedSkill.name}</div>
              <div style={{ color: 'var(--rah-text-soft)', fontSize: '13px', lineHeight: 1.4, marginTop: '6px' }}>{selectedSkill.description}</div>
              {isSelectedSkillFocused && (
                <div
                  style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '6px',
                    marginTop: '10px',
                    padding: '4px 8px',
                    borderRadius: '999px',
                    background: 'var(--rah-accent-green-soft)',
                    border: '1px solid var(--rah-accent-green-soft-strong)',
                    color: 'var(--rah-accent-green)',
                    fontSize: '11px',
                    fontWeight: 500,
                  }}
                >
                  <Brain size={12} />
                  Active chat context
                </div>
              )}
            </div>
            <div style={{ borderTop: '1px solid var(--rah-border)', margin: '12px 0' }} />
            <SkillMarkdown content={selectedSkill.content} />
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
            {skills.length === 0 ? (
              <div style={{ color: 'var(--rah-text-muted)', fontSize: '13px', textAlign: 'center', paddingTop: '24px' }}>
                No skills found
              </div>
            ) : (
              skills.map((skill) => (
                <SkillCard
                  key={skill.name}
                  skill={skill}
                  onSelect={handleSelectSkill}
                  onDelete={handleDeleteSkill}
                  deleting={deleting}
                  isActive={focusedSkill?.name === skill.name}
                />
              ))
            )}
          </div>
        )}
      </div>
    </div>
  );
}
