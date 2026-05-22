import { NextResponse } from 'next/server';
import { TOOL_GROUP_ASSIGNMENTS, TOOL_GROUPS } from '@/tools/infrastructure/groups';
import { getHelperTools } from '@/tools/infrastructure/registry';

export async function GET() {
  try {
    const grouped: Record<string, { name: string; description: string }[]> = {
      core: [],
      orchestration: [],
      execution: [],
    };

    Object.entries(TOOL_GROUP_ASSIGNMENTS).forEach(([toolName, groupId]) => {
      const tools = getHelperTools([toolName]);
      const tool = tools[toolName];
      if (tool) {
        grouped[groupId]?.push({
          name: toolName,
          description: tool.description || 'No description available',
        });
      }
    });

    return NextResponse.json({
      success: true,
      data: {
        groups: TOOL_GROUPS,
        tools: grouped,
      },
    });
  } catch (error) {
    console.error('Error fetching tools:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to fetch tools' },
      { status: 500 }
    );
  }
}
