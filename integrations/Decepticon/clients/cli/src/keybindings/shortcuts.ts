/**
 * Keybinding action registry.
 *
 * Maps semantic action names to default key combinations.
 * Follows Claude Code's action-based keybinding pattern:
 *   useKeybinding("app:toggleTranscript", handler)
 */

export type KeyAction =
  | "app:toggleTranscript"
  | "app:cancel";

export interface KeyCombo {
  key: string;
  ctrl?: boolean;
  shift?: boolean;
  escape?: boolean;
}

export const DEFAULT_KEYBINDINGS: Record<KeyAction, KeyCombo> = {
  "app:toggleTranscript": { key: "o", ctrl: true },
  "app:cancel": { key: "c", ctrl: true },
};

/** Display string for a key combo (e.g. "ctrl+o"). */
export function formatKeyCombo(combo: KeyCombo): string {
  const parts: string[] = [];
  if (combo.ctrl) parts.push("ctrl");
  if (combo.shift) parts.push("shift");
  if (combo.escape) return "Esc";
  parts.push(combo.key);
  return parts.join("+");
}

/** Get display string for an action (e.g. "ctrl+o"). */
export function getShortcutDisplay(action: KeyAction): string {
  return formatKeyCombo(DEFAULT_KEYBINDINGS[action]);
}
