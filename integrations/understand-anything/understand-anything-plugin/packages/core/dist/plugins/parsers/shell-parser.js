/**
 * Parses shell scripts (.sh, .bash) to extract function definitions and source references.
 * Handles both `name() {` and `function name {` styles, including brace on next line.
 * Does not extract variable declarations, aliases, or trap handlers.
 */
export class ShellParser {
    name = "shell-parser";
    languages = ["shell"];
    analyzeFile(_filePath, content) {
        const functions = this.extractFunctions(content);
        return {
            functions,
            classes: [],
            imports: [],
            exports: [],
        };
    }
    extractReferences(filePath, content) {
        const refs = [];
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
    extractFunctions(content) {
        const functions = [];
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
                            if (ch === "{")
                                depth++;
                            if (ch === "}")
                                depth--;
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
//# sourceMappingURL=shell-parser.js.map
