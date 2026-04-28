/**
 * ExpandOutputContext — controls bash/tool output expansion.
 *
 * Follows Claude Code's ExpandShellOutputContext pattern:
 * - In transcript mode: all outputs expanded
 * - In prompt mode: only the most recent bash output is expanded,
 *   older outputs are collapsed to a few lines
 *
 * Components use `useExpandOutput()` to check if they should render fully.
 */

import { createContext, useContext } from "react";

const ExpandOutputContext = createContext(false);

export const ExpandOutputProvider = ExpandOutputContext.Provider;

/** Whether the current output should be rendered in expanded (full) form. */
export function useExpandOutput(): boolean {
  return useContext(ExpandOutputContext);
}
