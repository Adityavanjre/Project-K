/**
 * CoordinatorPanel — dynamic region sub-agent display.
 *
 * Shows currently running + recently completed sub-agent sessions
 * using Claude Code's inline format via AgentSessionGroup.
 */

import React, { useState, useEffect, useMemo } from "react";
import { Box } from "ink";
import { AgentSessionGroup } from "./AgentSessionGroup.js";
import type { AgentEvent, SubAgentSession } from "../../types.js";

/** How long completed sessions remain visible (ms). */
const LINGER_MS = 10_000;

interface Props {
  sessions: SubAgentSession[];
  events: AgentEvent[];
}

export const CoordinatorPanel = React.memo(function CoordinatorPanel({
  sessions,
  events,
}: Props) {
  // Tick every second to refresh linger expiry
  const [now, setNow] = useState(Date.now());
  useEffect(() => {
    if (sessions.length === 0) return;
    const interval = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(interval);
  }, [sessions.length]);

  // Visible sessions: running OR completed within LINGER_MS
  const visible = useMemo(
    () =>
      sessions.filter(
        (s) =>
          s.status === "running" ||
          (s.endTime != null && now - s.endTime < LINGER_MS),
      ),
    [sessions, now],
  );

  if (visible.length === 0) return null;

  return (
    <Box flexDirection="column">
      {visible.map((session) => (
        <AgentSessionGroup
          key={session.id}
          session={session}
          events={events}
          screen="prompt"
        />
      ))}
    </Box>
  );
});
