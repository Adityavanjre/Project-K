import type { AnalyzerPlugin, StructuralAnalysis, ReferenceResolution } from "../../types.js";
/**
 * Parses JSON configuration files to extract top-level key sections and $ref references.
 * Handles package.json, tsconfig.json, JSON Schema, and OpenAPI spec files.
 * Does not descend into nested object structures beyond top-level keys.
 */
export declare class JSONConfigParser implements AnalyzerPlugin {
    name: string;
    languages: string[];
    analyzeFile(_filePath: string, content: string): StructuralAnalysis;
    extractReferences(filePath: string, content: string): ReferenceResolution[];
    private extractSections;
}
//# sourceMappingURL=json-parser.d.ts.map
