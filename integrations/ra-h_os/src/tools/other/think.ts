import { tool } from 'ai';
import { z } from 'zod';

export const thinkTool = tool({
  description: 'Log reasoning without side effects',
  inputSchema: z.object({
    purpose: z.string().describe('What you are working toward (problem/goal)'),
    thoughts: z.string().describe('Current reasoning step or reflection'),
    next_action: z
      .string()
      .optional()
      .describe('Planned next action or investigation step'),
    step: z
      .number()
      .int()
      .min(1)
      .optional()
      .describe('Optional step index in the sequence'),
    done: z
      .boolean()
      .optional()
      .describe('Signal completion if the plan is finished or stalled'),
  }),
  execute: async (params) => {
    return {
      success: true,
      data: {
        logged: true,
        continue: params.done ? false : true,
        trace: {
          ...params,
          timestamp: new Date().toISOString(),
        },
      },
    };
  },
});
