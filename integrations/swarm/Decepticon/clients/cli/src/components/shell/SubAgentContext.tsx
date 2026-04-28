/**
 * SubAgentContext — suppresses UI hints inside sub-agent views.
 *
 * Claude Code pattern: when rendering inside a sub-agent's expanded view,
 * "(ctrl+o to expand)" hints are hidden to reduce noise.
 */

import { createContext, useContext } from "react";

const SubAgentContext = createContext(false);

export const SubAgentProvider = SubAgentContext.Provider;

/** Returns true when rendering inside a sub-agent's expanded view. */
export function useIsInSubAgent(): boolean {
  return useContext(SubAgentContext);
}
