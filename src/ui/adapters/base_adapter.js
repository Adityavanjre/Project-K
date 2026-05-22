/**
 * Base Tool Adapter
 *
 * All adapters extend this class.
 * parse(line) receives a single clean line of tool output
 * and returns a structured event object.
 *
 * Output types:
 *   log      — Plain text line (default)
 *   finding  — Security finding: { severity, title, detail }
 *   table_row — Tabular data:  { columns: { key: value } }
 *   progress  — Progress update: { pct, label }
 *   done      — Tool finished
 */
class BaseAdapter {
    constructor(toolId) {
        this.toolId = toolId;
    }

    /**
     * Parse a single output line.
     * @param {string} line
     * @returns {{ type: string, data: any }}
     */
    parse(line) {
        return {
            type: 'log',
            data: { text: line }
        };
    }
}

module.exports = BaseAdapter;
