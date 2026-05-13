/**
 * Shared visual constants — icons, colors, and glyphs.
 *
 * Centralizes Unicode characters and color mappings so every component
 * references one source of truth instead of redeclaring locally.
 */

// ── Unicode glyphs ──────────────────────────────────────────────────

/** Filled circle (●) — header dots, activity pulses. */
export const GLYPH_DOT = "\u25CF";

/** Dentistry light down and horizontal (⎿) — connector/activity lines. */
export const GLYPH_HOOK = "\u23BF";

/** Middle dot (·) — inline separator. */
export const GLYPH_SEP = " \u00B7 ";

/** Tree branch characters for nested lists. */
export const TREE = {
  branch: "\u251C\u2500",    // ├─
  last: "\u2514\u2500",      // └─
  pipe: "\u2502",            // │
  blank: " ",                // (alignment spacer)
} as const;

/** Horizontal ellipsis (…). */
export const GLYPH_ELLIPSIS = "\u2026";

// ── Status icons ────────────────────────────────────────────────────

export interface StatusStyle {
  icon: string;
  color: string;
}

/** Objective / task status → icon + color. */
export const STATUS_ICON: Record<string, StatusStyle> = {
  completed: { icon: "\u2713", color: "green" },
  "in-progress": { icon: "\u25FC", color: "yellow" },
  blocked: { icon: "\u2717", color: "red" },
  pending: { icon: "\u25FB", color: "gray" },
};

/** Todo status → icon + color (uses underscored keys). */
export const TODO_ICON: Record<string, StatusStyle> = {
  completed: { icon: "\u2713", color: "green" },
  in_progress: { icon: "\u2610", color: "white" },
  pending: { icon: "\u2610", color: "gray" },
};

// ── Agent colors ────────────────────────────────────────────────────

/** Kill-chain agent name → display color. */
export const AGENT_COLORS: Record<string, string> = {
  decepticon: "blue",
  recon: "cyan",
  exploit: "red",
  postexploit: "magenta",
  soundwave: "yellow",
};
