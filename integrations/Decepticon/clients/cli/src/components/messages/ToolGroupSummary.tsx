/**
 * ToolGroupSummary — collapsed display for consecutive read/search operations.
 *
 * Shows: "● 3 searches · 2 reads" in a single line,
 * replacing the individual tool call displays.
 */

import React from "react";
import { Box, Text } from "ink";
import type { ToolGroup } from "../../utils/groupEvents.js";
import { formatToolGroup } from "../../utils/groupEvents.js";
import { CtrlOToExpand } from "../shell/CtrlOToExpand.js";
import { GLYPH_DOT } from "../../utils/theme.js";

interface Props {
  group: ToolGroup;
}

export const ToolGroupSummary = React.memo(function ToolGroupSummary({
  group,
}: Props) {
  const summary = formatToolGroup(group);
  return (
    <Box flexDirection="column" marginTop={1}>
      <Text>
        <Text color="green">{`${GLYPH_DOT} `}</Text>
        <Text dimColor>{summary}</Text>
        <CtrlOToExpand />
      </Text>
    </Box>
  );
});
