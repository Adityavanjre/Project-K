/**
 * Generic Tool Adapter
 *
 * Default fallback for any tool without a dedicated adapter.
 * Passes every line through as a plain log entry.
 * Detects common patterns like errors and warnings to set severity.
 */
const BaseAdapter = require('./base_adapter');

class GenericAdapter extends BaseAdapter {
    parse(line) {
        const lower = line.toLowerCase();
        let severity = 'info';

        if (/error|fail|exception|critical/i.test(line)) severity = 'error';
        else if (/warn|warning/i.test(line)) severity = 'warn';
        else if (/success|complete|done|finished/i.test(line)) severity = 'success';

        return {
            type: 'log',
            data: { text: line, severity }
        };
    }
}

module.exports = GenericAdapter;
