/**
 * DelegateMessage — sub-agent delegation display.
 *
 * Prompt mode:  ● Delegate(recon)           — compact, no description
 * Transcript:   ● Delegate(recon)
 *                 ⎿  Scan target network for open ports...
 */

import React from "react";
import { Box, Text } from "ink";
import { GLYPH_DOT, GLYPH_HOOK } from "../../utils/theme.js";
import { useScreen } from "../shell/ScreenContext.js";

interface Props {
  agent: string;
  content: string;
}

export const DelegateMessage = React.memo(function DelegateMessage({
  agent,
  content,
}: Props) {
  const screen = useScreen();

  return (
    <Box flexDirection="column" marginTop={1}>
      <Text>
        <Text color="cyan">{`${GLYPH_DOT} `}</Text>
        <Text color="white" bold>{"Delegate"}</Text>
        <Text color="gray" italic>{` (${agent})`}</Text>
      </Text>
      {screen === "transcript" && content && (
        <Text dimColor wrap="wrap">{`  ${GLYPH_HOOK}  ${content}`}</Text>
      )}
    </Box>
  );
});
