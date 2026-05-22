import { describe, it, expect } from "vitest";
import { TodoStore, type Todo } from "./todo.js";

describe("TodoStore", () => {
  it("should create a new todo", () => {
    const store = new TodoStore();
    const todo = store.add("Buy milk");
    expect(todo.id).toBeDefined();
    expect(todo.title).toBe("Buy milk");
    expect(todo.completed).toBe(false);
    expect(typeof todo.createdAt).toBe("number");
  });

  it("should list all todos", () => {
    const store = new TodoStore();
    store.add("Task 1");
    store.add("Task 2");
    expect(store.list()).toHaveLength(2);
  });

  it("should toggle todo completion", () => {
    const store = new TodoStore();
    const todo = store.add("Test task");
    store.toggle(todo.id);
    expect(store.get(todo.id)?.completed).toBe(true);
  });

  it("should delete a todo", () => {
    const store = new TodoStore();
    const todo = store.add("Delete me");
    store.delete(todo.id);
    expect(store.list()).toHaveLength(0);
  });

  it("should throw on empty title", () => {
    const store = new TodoStore();
    expect(() => store.add("")).toThrow();
  });

  it("should sort by createdAt descending", () => {
    const store = new TodoStore();
    const a = store.add("First");
    const b = store.add("Second");
    const sorted = store.listSorted();
    expect(sorted[0].title).toBe("Second");
    expect(sorted[1].title).toBe("First");
  });
});
