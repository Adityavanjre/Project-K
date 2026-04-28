/**
 * DiffResult — Claude Code-style diff display for edit_file tool results.
 *
 * Uses npm `diff` package (same as Claude Code) for proper line-level diffing
 * between old_string and new_string from edit_file tool args.
 *
 * Visual format (prompt mode — summary only):
 *   ● Update(src/components/TodoList.tsx)
 *     ⎿  Added 1 line, removed 6 lines
 *
 * Visual format (transcript mode — full diff):
 *   ● Update(src/components/TodoList.tsx)
 *     ⎿  Added 1 line, removed 6 lines
 *        -const STATUS_ICON: Record<string, …> = {
 *        -  completed: { icon: "✓", color: "green" },
 *        -  pending: { icon: "☐", color: "gray" },
 *        -};
 *        +import { TODO_ICON } from "../utils/theme.js";
 */

import React, { useMemo } from "react";
import { Box, Text } from "ink";
import { diffLines, type Change } from "diff";
import { GLYPH_DOT, GLYPH_HOOK } from "../../utils/theme.js";
import { shortPath } from "../../utils/format.js";
import { useScreen } from "../shell/ScreenContext.js";
import { CtrlOToExpand } from "../shell/CtrlOToExpand.js";

const MAX_DIFF_LINES_TRANSCRIPT = 40;

interface DiffResultProps {
  filePath: string;
  oldString: string;
  newString: string;
  status?: "success" | "error";
  content: string;
}

interface DiffLine {
  text: string;
  type: "add" | "remove" | "context";
  lineNum: number;
}

/** Compute structured diff lines with line numbers from Change[] */
function buildDiffLines(changes: Change[]): {
  lines: DiffLine[];
  added: number;
  removed: number;
} {
  const lines: DiffLine[] = [];
  let added = 0;
  let removed = 0;
  let lineNum = 1;

  for (const change of changes) {
    // diff package may include trailing newline — split and filter
    const rawLines = change.value.replace(/\n$/, "").split("\n");

    if (change.added) {
      added += rawLines.length;
      for (const text of rawLines) {
        lines.push({ text, type: "add", lineNum });
        lineNum++;
      }
    } else if (change.removed) {
      removed += rawLines.length;
      for (const text of rawLines) {
        lines.push({ text, type: "remove", lineNum });
        // removed lines don't advance new-file line numbers
      }
    } else {
      for (const text of rawLines) {
        lines.push({ text, type: "context", lineNum });
        lineNum++;
      }
    }
  }

  return { lines, added, removed };
}

/** Build summary: "Added 3 lines, removed 1 line" */
function summaryText(added: number, removed: number): string {
  const parts: string[] = [];
  if (added > 0) parts.push(`Added ${added} line${added !== 1 ? "s" : ""}`);
  if (removed > 0) parts.push(`removed ${removed} line${removed !== 1 ? "s" : ""}`);
  return parts.join(", ") || "No changes";
}

export const DiffResult = React.memo(function DiffResult({
  filePath,
  oldString,
  newString,
  status,
  content,
}: DiffResultProps) {
  const screen = useScreen();
  const isTranscript = screen === "transcript";

  // Compute diff using npm `diff` (same engine as Claude Code)
  const { lines, added, removed } = useMemo(() => {
    const changes = diffLines(oldString, newString);
    return buildDiffLines(changes);
  }, [oldString, newString]);

  const summary = summaryText(added, removed);

  // Error case — show raw content
  if (status === "error") {
    return (
      <Box flexDirection="column" marginTop={1}>
        <Text>
          <Text color="red">{`${GLYPH_DOT} `}</Text>
          <Text bold>Update</Text>
          <Text dimColor italic>{`(${shortPath(filePath)})`}</Text>
        </Text>
        <Text>
          <Text dimColor>{`  ${GLYPH_HOOK}  `}</Text>
          <Text color="red">{content}</Text>
        </Text>
      </Box>
    );
  }

  // Prompt mode: summary only + hint
  if (!isTranscript) {
    return (
      <Box flexDirection="column" marginTop={1}>
        <Text>
          <Text color="green">{`${GLYPH_DOT} `}</Text>
          <Text bold>Update</Text>
          <Text dimColor italic>{`(${shortPath(filePath)})`}</Text>
        </Text>
        <Text>
          <Text dimColor>{`  ${GLYPH_HOOK}  ${summary}`}</Text>
          <CtrlOToExpand />
        </Text>
      </Box>
    );
  }

  // Transcript mode: full diff with line numbers and +/- markers
  const maxLineNum = Math.max(...lines.map((l) => l.lineNum), 0);
  const gutterWidth = String(maxLineNum).length;

  // Truncate if too long
  const truncated = lines.length > MAX_DIFF_LINES_TRANSCRIPT;
  const visible = truncated
    ? lines.slice(0, MAX_DIFF_LINES_TRANSCRIPT)
    : lines;

  return (
    <Box flexDirection="column" marginTop={1}>
      {/* Header: ● Update(path) */}
      <Text>
        <Text color="green">{`${GLYPH_DOT} `}</Text>
        <Text bold>Update</Text>
        <Text dimColor italic>{`(${shortPath(filePath)})`}</Text>
      </Text>

      {/* Summary: ⎿  Added N lines, removed M lines */}
      <Text dimColor>{`  ${GLYPH_HOOK}  ${summary}`}</Text>

      {/* Diff lines with line numbers */}
      {visible.map((line, i) => {
        const num = String(line.lineNum).padStart(gutterWidth);

        switch (line.type) {
          case "remove":
            return (
              <Text key={i} wrap="truncate">
                <Text dimColor>{`     ${num} `}</Text>
                <Text color="red">{`-${line.text}`}</Text>
              </Text>
            );
          case "add":
            return (
              <Text key={i} wrap="truncate">
                <Text dimColor>{`     ${num} `}</Text>
                <Text color="green">{`+${line.text}`}</Text>
              </Text>
            );
          default:
            return (
              <Text key={i} wrap="truncate">
                <Text dimColor>{`     ${num}  ${line.text}`}</Text>
              </Text>
            );
        }
      })}

      {truncated && <CtrlOToExpand />}
    </Box>
  );
});
