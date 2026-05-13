import React from "react";
import { Box, Text } from "ink";

interface Props {
  content: string;
}

export const SystemMessage = React.memo(function SystemMessage({
  content,
}: Props) {
  return (
    <Box marginTop={1}>
      <Text dimColor wrap="wrap">
        {content}
      </Text>
    </Box>
  );
});
