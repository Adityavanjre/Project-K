import React from "react";
import { Box, Text } from "ink";
import { STATUS_ICON, GLYPH_HOOK } from "../utils/theme.js";

export interface ObjectiveItem {
  id: string;
  title: string;
  phase: string;
  status: string;
  priority: number;
  owner?: string;
  blockedBy?: string[];
}

interface ObjectiveListProps {
  objectives: ObjectiveItem[];
  engagement?: string;
}

/** Parse objectives from list_objectives tool result content. */
export function parseObjectives(content: string): {
  objectives: ObjectiveItem[];
  engagement: string;
} {
  const objectives: ObjectiveItem[] = [];
  let engagement = "";

  const lines = content.split("\n");

  // Extract engagement name from "# OPPLAN: <name>" header
  const headerLine = lines.find((l) => l.startsWith("# OPPLAN:"));
  if (headerLine) {
    engagement = headerLine.replace("# OPPLAN:", "").trim();
  }

  // Parse markdown table rows (skip header + separator)
  const tableStart = lines.findIndex((l) => l.startsWith("| ID"));
  if (tableStart === -1) return { objectives, engagement };

  for (let i = tableStart + 2; i < lines.length; i++) {
    const line = lines[i];
    if (!line || !line.startsWith("|")) break;

    const cells = line
      .split("|")
      .map((c) => c.trim())
      .filter(Boolean);
    if (cells.length < 6) continue;

    objectives.push({
      id: cells[0],
      phase: cells[1],
      title: cells[2],
      status: cells[3],
      priority: parseInt(cells[4], 10) || 0,
      owner: cells[5] !== "-" ? cells[5] : undefined,
      blockedBy:
        cells[6] && cells[6] !== "-"
          ? cells[6].split(",").map((s) => s.trim())
          : undefined,
    });
  }

  return { objectives, engagement };
}

/**
 * Render OPPLAN objectives in Claude Code TODO style.
 *
 * Output format:
 *   ⎿  ◼ OBJ-001 Subdomain enumeration
 *      ◻ OBJ-002 Port scanning
 *      ✓ OBJ-003 SQL injection testing
 *      ✗ OBJ-004 Credential brute force
 */
export const ObjectiveList = React.memo(function ObjectiveList({
  objectives,
}: ObjectiveListProps) {
  return (
    <Box flexDirection="column">
      {objectives.map((obj, i) => {
        const { icon, color } =
          STATUS_ICON[obj.status] ?? STATUS_ICON.pending;
        const isDone = obj.status === "completed";
        // First line gets ⎿ connector (Claude Code style), rest get aligned indent
        const prefix = i === 0 ? `  ${GLYPH_HOOK}  ` : "     ";
        return (
          <Text key={obj.id} wrap="wrap">
            {prefix}
            <Text color={color}>{icon}</Text>
            <Text color={isDone ? "gray" : "white"}>{` ${obj.title}`}</Text>
          </Text>
        );
      })}
    </Box>
  );
});
