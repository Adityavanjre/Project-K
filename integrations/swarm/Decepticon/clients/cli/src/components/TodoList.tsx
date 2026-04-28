import React from "react";
import { Box, Text } from "ink";
import { TODO_ICON } from "../utils/theme.js";

interface TodoItem {
  content: string;
  status: "pending" | "in_progress" | "completed";
  activeForm?: string;
}

interface TodoListProps {
  todos: TodoItem[];
}

/** Parse todo items from write_todos tool args. */
export function parseTodos(toolArgs: Record<string, unknown>): TodoItem[] {
  const raw = toolArgs.todos;
  if (!Array.isArray(raw)) return [];
  return raw
    .filter(
      (item): item is Record<string, unknown> =>
        typeof item === "object" && item !== null && "content" in item,
    )
    .map((item) => ({
      content: String(item.content ?? ""),
      status: (item.status as TodoItem["status"]) ?? "pending",
      activeForm: item.activeForm ? String(item.activeForm) : undefined,
    }));
}

/** Render a todo checklist from write_todos tool output. */
export const TodoList = React.memo(function TodoList({ todos }: TodoListProps) {
  const counts = { completed: 0, in_progress: 0, pending: 0 };
  for (const t of todos) counts[t.status]++;

  const statsParts: string[] = [];
  if (counts.in_progress > 0) statsParts.push(`${counts.in_progress} active`);
  if (counts.pending > 0) statsParts.push(`${counts.pending} pending`);
  if (counts.completed > 0) statsParts.push(`${counts.completed} done`);

  return (
    <Box flexDirection="column">
      {todos.map((todo, i) => {
        const { icon, color } = TODO_ICON[todo.status] ?? TODO_ICON.pending!;
        return (
          <Text key={i} wrap="wrap">
            {"  "}
            <Text color={color}>{icon}</Text>
            <Text color={todo.status === "completed" ? "gray" : "white"}>
              {` ${todo.content}`}
            </Text>
          </Text>
        );
      })}
    </Box>
  );
});
