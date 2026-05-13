/**
 * Tool result grouping — collapses consecutive read/search tool calls.
 *
 * Claude Code pattern: consecutive read_file, grep, glob, ls calls in prompt
 * mode are collapsed into a single summary: "3 searches · 2 reads".
 */

import type { AgentEvent } from "../types.js";

/** Tool names that count as "search" operations. */
const SEARCH_TOOLS = new Set(["grep", "glob", "ls"]);

/** Tool names that count as "read" operations. */
const READ_TOOLS = new Set(["read_file"]);

/** All groupable tool names. */
const GROUPABLE_TOOLS = new Set([...SEARCH_TOOLS, ...READ_TOOLS]);

/** A group of consecutive tool_result events that were collapsed. */
export interface ToolGroup {
  id: string;
  searchCount: number;
  readCount: number;
  timestamp: number;
  /** Original event IDs in this group. */
  eventIds: string[];
}

/** Result of grouping: either a regular event or a collapsed group. */
export type GroupedItem =
  | { kind: "event"; event: AgentEvent }
  | { kind: "group"; group: ToolGroup };

/**
 * Groups consecutive groupable tool_result events in prompt mode.
 * Non-groupable events and single-item runs are kept as individual events.
 */
export function groupConsecutiveTools(events: AgentEvent[]): GroupedItem[] {
  const result: GroupedItem[] = [];
  let i = 0;

  while (i < events.length) {
    const event = events[i]!;

    // Check if this starts a groupable run
    if (event.type === "tool_result" && GROUPABLE_TOOLS.has(event.toolName ?? "")) {
      // Collect consecutive groupable events
      let searchCount = 0;
      let readCount = 0;
      const eventIds: string[] = [];
      const startTs = event.timestamp;
      let j = i;

      while (j < events.length) {
        const e = events[j]!;
        if (e.type !== "tool_result" || !GROUPABLE_TOOLS.has(e.toolName ?? "")) break;

        if (SEARCH_TOOLS.has(e.toolName ?? "")) searchCount++;
        if (READ_TOOLS.has(e.toolName ?? "")) readCount++;
        eventIds.push(e.id);
        j++;
      }

      const total = searchCount + readCount;
      if (total >= 3) {
        // Collapse into a group
        result.push({
          kind: "group",
          group: {
            id: `group-${eventIds[0]}`,
            searchCount,
            readCount,
            timestamp: startTs,
            eventIds,
          },
        });
      } else {
        // Too few to group — keep individual
        for (let k = i; k < j; k++) {
          result.push({ kind: "event", event: events[k]! });
        }
      }
      i = j;
    } else {
      result.push({ kind: "event", event });
      i++;
    }
  }

  return result;
}

/** Format a tool group into a summary string. */
export function formatToolGroup(group: ToolGroup): string {
  const parts: string[] = [];
  if (group.searchCount > 0) {
    parts.push(`${group.searchCount} search${group.searchCount !== 1 ? "es" : ""}`);
  }
  if (group.readCount > 0) {
    parts.push(`${group.readCount} read${group.readCount !== 1 ? "s" : ""}`);
  }
  return parts.join(" · ");
}
