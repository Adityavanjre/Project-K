/**
 * ScreenContext — propagates current screen mode to child components.
 *
 * Follows Claude Code's pattern of passing screen mode via React Context
 * so deeply nested components can render differently in prompt vs transcript mode.
 */

import { createContext, useContext } from "react";
import type { ScreenMode } from "../../types.js";

const ScreenContext = createContext<ScreenMode>("prompt");

export const ScreenProvider = ScreenContext.Provider;

/** Read the current screen mode (prompt or transcript). */
export function useScreen(): ScreenMode {
  return useContext(ScreenContext);
}
