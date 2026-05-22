import type { AnalyzerPlugin, StructuralAnalysis, SectionInfo, ReferenceResolution } from "../../types.js";

/**
 * Parses JSON configuration files to extract top-level key sections and $ref references.
 * Handles package.json, tsconfig.json, JSON Schema, and OpenAPI spec files.
 * Does not descend into nested object structures beyond top-level keys.
 */
export class JSONConfigParser implements AnalyzerPlugin {
  name = "json-config-parser";
  languages = ["json"];

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

  extractReferences(filePath: string, content: string): ReferenceResolution[] {
    const refs: ReferenceResolution[] = [];
    // Match $ref values (JSON Schema / OpenAPI)
    const refRegex = /"\$ref"\s*:\s*"([^"]+)"/g;
    let match;
    while ((match = refRegex.exec(content)) !== null) {
      const target = match[1];
      if (target.startsWith("#")) continue; // Skip internal refs
      const line = content.slice(0, match.index).split("\n").length;
      refs.push({
        source: filePath,
        target,
        referenceType: "schema",
        line,
      });
    }
    return refs;
  }

  private extractSections(content: string): SectionInfo[] {
    const sections: SectionInfo[] = [];
    try {
      const doc = JSON.parse(content);
      if (doc && typeof doc === "object" && !Array.isArray(doc)) {
        const lines = content.split("\n");
        for (const key of Object.keys(doc)) {
          const escapedKey = JSON.stringify(key);
          const lineIdx = lines.findIndex((l) => l.includes(escapedKey));
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
      console.warn(`[json-parser] Failed to parse JSON: ${err instanceof Error ? err.message : String(err)}`);
    }
    return sections;
  }
}
