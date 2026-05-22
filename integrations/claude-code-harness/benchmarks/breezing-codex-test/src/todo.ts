export interface Todo {
  id: string;
  title: string;
  completed: boolean;
  createdAt: number; // Date.now()
}

export class TodoStore {
  private todos = new Map<string, Todo>();
  /**
   * Used as a deterministic tie-breaker for `listSorted()` when two todos share
   * the same `createdAt` (possible when created in the same millisecond).
   */
  private orderById = new Map<string, number>();
  private nextOrder = 0;

  private sanitize(text: string): string {
    return text
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  add(title: string): Todo {
    if (title.trim() === "") {
      throw new Error("Todo title cannot be empty");
    }

    const todo: Todo = {
      id: crypto.randomUUID(),
      title: this.sanitize(title),
      completed: false,
      createdAt: Date.now(),
    };

    this.todos.set(todo.id, todo);
    this.orderById.set(todo.id, this.nextOrder++);
    return { ...todo };
  }

  list(): Todo[] {
    return Array.from(this.todos.values(), (todo) => ({ ...todo }));
  }

  get(id: string): Todo | undefined {
    const todo = this.todos.get(id);
    return todo ? { ...todo } : undefined;
  }

  toggle(id: string): void {
    const todo = this.todos.get(id);
    if (!todo) return;
    todo.completed = !todo.completed;
  }

  delete(id: string): void {
    this.todos.delete(id);
    this.orderById.delete(id);
  }

  listSorted(): Todo[] {
    const items: Array<{ todo: Todo; order: number }> = [];

    for (const todo of this.todos.values()) {
      items.push({
        todo: { ...todo },
        order: this.orderById.get(todo.id) ?? -1,
      });
    }

    items.sort((a, b) => {
      const createdAtDiff = b.todo.createdAt - a.todo.createdAt;
      if (createdAtDiff !== 0) return createdAtDiff;
      return b.order - a.order;
    });

    return items.map((item) => item.todo);
  }
}

/*
 * AGENTS_SUMMARY
 * task: Implement Todo type and TodoStore class
 * files_changed: src/todo.ts
 * hash: e6a33c54
 */
