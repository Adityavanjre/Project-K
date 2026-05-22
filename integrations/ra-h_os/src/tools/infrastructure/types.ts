import { Node } from '@/types/database';
import { SQLiteClient } from '@/services/database/sqlite-client';

export interface ToolContext {
  selectedNodes: Node[];
  database: SQLiteClient;
}

export interface ToolSchema {
  type: 'function';
  function: {
    name: string;
    description: string;
    parameters: {
      type: 'object';
      properties: Record<string, any>;
      required: string[];
    };
  };
}

export interface Tool {
  id: string;
  name: string;
  description: string;
  schema: ToolSchema;
  execute: (params: any, context: ToolContext) => Promise<any>;
}
