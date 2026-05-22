import { describe, it, expect } from "vitest";
import { Counter } from "./counter.js";

describe("Counter", () => {
  it("should start at 0", () => {
    const c = new Counter();
    expect(c.value).toBe(0);
  });

  it("should increment", () => {
    const c = new Counter();
    c.increment();
    c.increment();
    expect(c.value).toBe(2);
  });

  it("should decrement", () => {
    const c = new Counter();
    c.increment();
    c.decrement();
    expect(c.value).toBe(0);
  });

  it("should undo last operation", () => {
    const c = new Counter();
    c.increment();
    c.increment();
    c.undo();
    expect(c.value).toBe(1);
  });

  it("should redo after undo", () => {
    const c = new Counter();
    c.increment();
    c.undo();
    c.redo();
    expect(c.value).toBe(1);
  });

  it("should reset to 0", () => {
    const c = new Counter();
    c.increment();
    c.reset();
    expect(c.value).toBe(0);
  });
});
