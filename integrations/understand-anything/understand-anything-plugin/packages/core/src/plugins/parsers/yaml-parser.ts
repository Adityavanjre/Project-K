import type { AnalyzerPlugin, StructuralAnalysis, SectionInfo } from "../../types.js";
import { parse as parseYAML } from "yaml";

/**
 * Parses YAML configuration files to extract top-level key sections.
 * Uses the `yaml` library for parsing with a regex fallback for malformed input.
 * Only extracts top-level keys; does not descend into nested structures.
 */
export class YAMLConfigParser implements AnalyzerPlugin {
  name = "yaml-config-parser";
  languages = ["yaml"];

  analyzeFile(_filePath: string, content: string): StructuralAnalysis {
    const sections = this.extractSections(content);
    return {
      functions: [],
      classes: [],
      imports: [],
      exports: [],
      sections,
    };
  }

  private extractSections(content: string): SectionInfo[] {
    const sections: SectionInfo[] = [];
    try {
      const doc = parseYAML(content);
      if (doc && typeof doc === "object" && !Array.isArray(doc)) {
        const lines = content.split("\n");
        for (const key of Object.keys(doc)) {
          // Find the line where this top-level key appears
          const lineIdx = lines.findIndex((l) => l.match(new RegExp(`^${this.escapeRegex(key)}\\s*:`)));
          if (lineIdx !== -1) {
            sections.push({
              name: key,
              level: 1,
              lineRange: [lineIdx + 1, lineIdx + 1],
            });
          }
        }
        // Fix lineRange end
        for (let i = 0; i < sections.length; i++) {
          const next = sections[i + 1];
          sections[i].lineRange[1] = next ? next.lineRange[0] - 1 : lines.length;
        }
      }
    } catch (err) {
      console.warn(`[yaml-parser] YAML parse failed, falling back to regex extraction: ${err instanceof Error ? err.message : String(err)}`);
      // If YAML parsing fails, fall back to regex
      const lines = content.split("\n");
      for (let i = 0; i < lines.length; i++) {
        const match = lines[i].match(/^(\w[\w-]*)\s*:/);
        if (match) {
          sections.push({
            name: match[1],
            level: 1,
            lineRange: [i + 1, i + 1],
          });
        }
      }
      for (let i = 0; i < sections.length; i++) {
        const next = sections[i + 1];
        sections[i].lineRange[1] = next ? next.lineRange[0] - 1 : lines.length;
      }
    }
    return sections;
  }

  private escapeRegex(str: string): string {
    return str.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  }
}
