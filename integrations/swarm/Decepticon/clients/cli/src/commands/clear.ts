import type { Command } from "./types.js";

const clear: Command = {
  name: "clear",
  description: "Clear conversation history",
  execute(_args, ctx) {
    ctx.clearEvents();
  },
};

export default clear;
