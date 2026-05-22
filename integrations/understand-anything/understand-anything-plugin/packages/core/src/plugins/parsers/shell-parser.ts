import type { AnalyzerPlugin, StructuralAnalysis, ReferenceResolution } from "../../types.js";

/**
 * Parses shell scripts (.sh, .bash) to extract function definitions and source references.
 * Handles both `name() {` and `function name {` styles, including brace on next line.
 * Does not extract variable declarations, aliases, or trap handlers.
 */
export class ShellParser implements AnalyzerPlugin {
  name = "shell-parser";
  languages = ["shell"];

  analyzeFile(_filePath: string, content: string): StructuralAnalysis {
    const functions = this.extractFunctions(content);
    return {
      functions,
      classes: [],
      imports: [],
      exports: [],
    };
  }

  extractReferences(filePath: string, content: string): ReferenceResolution[] {
    const refs: ReferenceResolution[] = [];
    const lines = content.split("\n");
    for (let i = 0; i < lines.length; i++) {
      // Match source/. commands
      const sourceMatch = lines[i].match(/^\s*(?:source|\.)[ \t]+["']?([^"'\s]+)["']?/);
      if (sourceMatch) {
        refs.push({
          source: filePath,
          target: sourceMatch[1],
          referenceType: "file",
          line: i + 1,
        });
      }
    }
    return refs;
  }

  private extractFunctions(content: string): Array<{ name: string; lineRange: [number, number]; params: string[] }> {
    const functions: Array<{ name: string; lineRange: [number, number]; params: string[] }> = [];
    const lines = content.split("\n");

    for (let i = 0; i < lines.length; i++) {
      // Match function name() { or function name {
      const match = lines[i].match(/^(?:function\s+)?(\w+)\s*\(\s*\)\s*\{?/) ||
                    lines[i].match(/^function\s+(\w+)\s*\{?/);
      if (match) {
        const name = match[1];
        // Find closing brace (handle brace on same line or next line)
        let endLine = i;
        if (lines[i].includes("{") || (i + 1 < lines.length && lines[i + 1]?.trim() === "{")) {
          const startBraceLine = lines[i].includes("{") ? i : i + 1;
          let depth = 0;
          for (let j = startBraceLine; j < lines.length; j++) {
            for (const ch of lines[j]) {
              if (ch === "{") depth++;
              if (ch === "}") depth--;
            }
            if (depth === 0) {
              endLine = j;
              break;
            }
          }
        }
        functions.push({
          name,
          lineRange: [i + 1, endLine + 1],
          params: [],
        });
      }
    }

    return functions;
  }
}
