/**
 * ErrorMessage — structured error display with truncation.
 *
 * Claude Code pattern: MAX_API_ERROR_CHARS = 1000, head/tail split,
 * red color coding, "(ctrl+o to expand)" hint on truncation.
 */

import React from "react";
import { Box, Text } from "ink";
import { CtrlOToExpand } from "../shell/CtrlOToExpand.js";

const MAX_ERROR_CHARS = 1000;

interface Props {
  content: string;
}

export const ErrorMessage = React.memo(function ErrorMessage({
  content,
}: Props) {
  const isTruncated = content.length > MAX_ERROR_CHARS;
  const headLen = Math.floor(MAX_ERROR_CHARS * 0.6);
  const tailLen = MAX_ERROR_CHARS - headLen;

  const display = isTruncated
    ? content.slice(0, headLen) + "\n...\n" + content.slice(-tailLen)
    : content;

  return (
    <Box flexDirection="column" marginTop={1}>
      <Text>
        <Text color="red" bold>{"error> "}</Text>
        <Text color="red" wrap="wrap">{display}</Text>
      </Text>
      {isTruncated && <CtrlOToExpand />}
    </Box>
  );
});
