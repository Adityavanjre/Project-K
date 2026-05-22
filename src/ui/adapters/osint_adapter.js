/**
 * OSINT Output Adapter
 *
 * Parses output from theHarvester, Shodan CLI, and generic OSINT tools.
 *
 * Recognizes:
 *   - Email addresses
 *   - IP addresses
 *   - Domain/subdomain entries
 *   - Summary counts
 */
const BaseAdapter = require('./base_adapter');

const EMAIL_RE = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g;
const IP_RE = /\b(?:\d{1,3}\.){3}\d{1,3}\b/g;
const DOMAIN_RE = /(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9][a-z0-9-]{0,61}[a-z0-9]/gi;
const SUMMARY_RE = /(\d+)\s+(email|host|ip|result|domain)/i;

class OsintAdapter extends BaseAdapter {
    parse(line) {
        const trimmed = line.trim();

        // Email extraction
        const emails = trimmed.match(EMAIL_RE);
        if (emails) {
            return {
                type: 'finding',
                data: {
                    severity: 'warn',
                    title: 'Email Discovered',
                    detail: emails.join(', '),
                    raw: trimmed
                }
            };
        }

        // IP discovery
        const ips = trimmed.match(IP_RE);
        if (ips && !trimmed.includes('127.0.0.1')) {
            return {
                type: 'finding',
                data: {
                    severity: 'info',
                    title: 'IP Address Found',
                    detail: ips.join(', '),
                    raw: trimmed
                }
            };
        }

        // Summary line
        const summaryMatch = trimmed.match(SUMMARY_RE);
        if (summaryMatch) {
            return {
                type: 'finding',
                data: {
                    severity: 'success',
                    title: 'OSINT Summary',
                    detail: trimmed
                }
            };
        }

        return {
            type: 'log',
            data: { text: trimmed, severity: 'info' }
        };
    }
}

module.exports = OsintAdapter;
