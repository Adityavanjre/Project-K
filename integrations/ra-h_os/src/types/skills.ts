export interface SkillMeta {
  name: string;
  description: string;
  immutable: boolean;
}

export interface Skill extends SkillMeta {
  content: string;
}

export interface FocusedSkill {
  name: string;
  description: string;
  content: string;
}
