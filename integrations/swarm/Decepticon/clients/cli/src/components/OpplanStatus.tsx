/**
 * OpplanStatus — Claude Code inline task list pattern for OPPLAN objectives.
 *
 * Visual format:
 *   ● 6 objectives (2 completed, 1 active, 3 pending)
 *     ⎿  ✓ Subdomain enumeration
 *        ◼ Port scanning
 *        ◻ Web vuln assessment
 *        ◻ Credential harvesting
 *        … +2 more
 */

import React from "react";
import { Box, Text } from "ink";
import type { OpplanState } from "../hooks/useOpplan.js";
import { STATUS_ICON, GLYPH_DOT, GLYPH_HOOK, GLYPH_ELLIPSIS } from "../utils/theme.js";

const MAX_VISIBLE = 8;

export const OpplanStatus = React.memo(function OpplanStatus({
  opplan,
}: {
  opplan: OpplanState;
}) {
  const { objectives } = opplan;
  if (objectives.length === 0) return null;

  const completedCount = objectives.filter((o) => o.status === "completed").length;
  const inProgressCount = objectives.filter(
    (o) => o.status === "in-progress",
  ).length;
  const blockedCount = objectives.filter((o) => o.status === "blocked").length;
  const pendingCount = objectives.length - completedCount - inProgressCount - blockedCount;

  const allDone = completedCount === objectives.length;
  const dotColor = allDone ? "green" : "cyan";

  // Build summary parts
  const parts: string[] = [];
  if (completedCount > 0) parts.push(`${completedCount} completed`);
  if (inProgressCount > 0) parts.push(`${inProgressCount} active`);
  if (blockedCount > 0) parts.push(`${blockedCount} blocked`);
  if (pendingCount > 0) parts.push(`${pendingCount} pending`);

  // Truncate if too many objectives
  const visible = objectives.slice(0, MAX_VISIBLE);
  const hiddenCount = objectives.length - visible.length;

  return (
    <Box flexDirection="column" marginTop={1}>
      {/* Header: ● N objectives (summary) */}
      <Text>
        <Text color={dotColor}>{`${GLYPH_DOT} `}</Text>
        <Text>{objectives.length} objective{objectives.length !== 1 ? "s" : ""}</Text>
        <Text dimColor>{" ("}{parts.join(", ")}{")"}</Text>
      </Text>

      {/* Objective list with ⎿ connector on first line */}
      {visible.map((obj, i) => {
        const { icon, color } = STATUS_ICON[obj.status] ?? STATUS_ICON.pending!;
        const isDone = obj.status === "completed";
        const isActive = obj.status === "in-progress";
        const prefix = i === 0 ? `  ${GLYPH_HOOK}  ` : "     ";
        return (
          <Text key={obj.id} wrap="wrap">
            <Text dimColor>{prefix}</Text>
            <Text color={color}>{icon}</Text>
            <Text
              bold={isActive}
              strikethrough={isDone}
              dimColor={isDone || obj.status === "blocked"}
            >
              {` ${obj.title}`}
            </Text>
          </Text>
        );
      })}

      {/* Hidden count */}
      {hiddenCount > 0 && (
        <Text dimColor>{`     ${GLYPH_ELLIPSIS} +\u200A`}{hiddenCount}{" more"}</Text>
      )}
    </Box>
  );
});
