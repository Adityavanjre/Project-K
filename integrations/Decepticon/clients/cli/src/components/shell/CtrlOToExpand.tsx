/**
 * CtrlOToExpand — consistent "(ctrl+o to expand)" hint for truncated content.
 *
 * Claude Code pattern:
 * - Shows dim hint text after truncated output
 * - Suppressed inside sub-agent views (SubAgentContext)
 * - Suppressed in transcript mode (ScreenContext)
 */

import React from "react";
import { Text } from "ink";
import { useScreen } from "./ScreenContext.js";
import { useIsInSubAgent } from "./SubAgentContext.js";

export const CtrlOToExpand = React.memo(function CtrlOToExpand() {
  const screen = useScreen();
  const isInSubAgent = useIsInSubAgent();

  // Don't show hint in transcript (already expanded) or inside sub-agents
  if (screen === "transcript" || isInSubAgent) {
    return null;
  }

  return (
    <Text dimColor italic>
      {" (ctrl+o to expand)"}
    </Text>
  );
});
