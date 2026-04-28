import { describe, expect, it } from "vitest";
import {
  extractSkillName,
  formatDuration,
  formatNumber,
  shortPath,
  truncateLines,
} from "./format.js";

describe("shortPath", () => {
  it("strips /workspace/ prefix", () => {
    expect(shortPath("/workspace/scans/nmap.txt")).toBe("scans/nmap.txt");
  });

  it("renders bare /workspace as /", () => {
    expect(shortPath("/workspace")).toBe("/");
  });

  it("leaves unrelated paths intact", () => {
    expect(shortPath("/etc/hosts")).toBe("/etc/hosts");
  });
});

describe("formatDuration", () => {
  it("renders sub-minute as Ns", () => {
    expect(formatDuration(45_000)).toBe("45s");
  });

  it("renders multi-minute with seconds", () => {
    expect(formatDuration(83_000)).toBe("1m 23s");
  });

  it("drops zero-second remainder", () => {
    expect(formatDuration(120_000)).toBe("2m");
  });

  it("rounds down to nearest second", () => {
    expect(formatDuration(45_999)).toBe("45s");
  });
});

describe("formatNumber", () => {
  it("renders < 1K as plain integer", () => {
    expect(formatNumber(42)).toBe("42");
    expect(formatNumber(999)).toBe("999");
  });

  it("renders thousands with K suffix", () => {
    expect(formatNumber(1_500)).toBe("1.5K");
    expect(formatNumber(12_345)).toBe("12.3K");
  });

  it("renders millions with M suffix", () => {
    expect(formatNumber(1_500_000)).toBe("1.5M");
  });
});

describe("extractSkillName", () => {
  it("returns null for non-skill paths", () => {
    expect(extractSkillName({ file_path: "/workspace/foo.txt" })).toBeNull();
  });

  it("returns null when file_path is missing", () => {
    expect(extractSkillName({})).toBeNull();
  });

  it("extracts skill directory name", () => {
    const name = extractSkillName({ file_path: "/skills/recon/nmap/SKILL.md" });
    expect(name).toBe("nmap");
  });

  it("handles top-level skill path", () => {
    const name = extractSkillName({ file_path: "/skills/recon/SKILL.md" });
    expect(name).toBe("recon");
  });
});

describe("truncateLines", () => {
  it("returns all lines when under limit", () => {
    const result = truncateLines("a\nb\nc", 5);
    expect(result).toEqual(["a", "b", "c"]);
  });

  it("truncates with summary line when over limit", () => {
    const content = Array.from({ length: 10 }, (_, i) => `line${i}`).join("\n");
    const result = truncateLines(content, 3);
    expect(result.length).toBe(4); // 3 lines + summary
    expect(result[0]).toBe("line0");
    expect(result[3]).toBe("... (7 more lines)");
  });
});
