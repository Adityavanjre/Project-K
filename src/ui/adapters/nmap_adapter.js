/**
 * NMAP Output Adapter
 *
 * Parses nmap text output into structured port/service objects.
 *
 * Recognizes:
 *   - Open port lines:     "80/tcp   open  http"
 *   - Scan summary lines:  "Nmap scan report for 192.168.1.1"
 *   - Host status lines:   "Host is up (0.0012s latency)"
 *   - Stats lines:         "Nmap done: 1 IP address"
 */
const BaseAdapter = require('./base_adapter');

// 80/tcp   open  http   Apache httpd 2.4.41
const PORT_RE = /^(\d+)\/(tcp|udp)\s+(open|closed|filtered)\s+(\S+)(?:\s+(.+))?$/i;
// Nmap scan report for TARGET or (IP)
const TARGET_RE = /^Nmap scan report for (.+)$/i;
// Host is up (Xs latency)
const HOST_RE = /^Host is up \((.+?)\)/i;
// Nmap done: N IP address
const DONE_RE = /^Nmap done:/i;

class NmapAdapter extends BaseAdapter {
    parse(line) {
        const trimmed = line.trim();

        const portMatch = trimmed.match(PORT_RE);
        if (portMatch) {
            return {
                type: 'table_row',
                data: {
                    columns: {
                        Port:     `${portMatch[1]}/${portMatch[2]}`,
                        State:    portMatch[3],
                        Service:  portMatch[4],
                        Version:  portMatch[5] || '—'
                    },
                    severity: portMatch[3] === 'open' ? 'finding' : 'info'
                }
            };
        }

        const targetMatch = trimmed.match(TARGET_RE);
        if (targetMatch) {
            return {
                type: 'finding',
                data: {
                    severity: 'info',
                    title: `Scan Target`,
                    detail: targetMatch[1]
                }
            };
        }

        const hostMatch = trimmed.match(HOST_RE);
        if (hostMatch) {
            return {
                type: 'finding',
                data: {
                    severity: 'success',
                    title: 'Host Up',
                    detail: `Latency: ${hostMatch[1]}`
                }
            };
        }

        if (DONE_RE.test(trimmed)) {
            return {
                type: 'done',
                data: { text: trimmed, severity: 'success' }
            };
        }

        // Default: log line
        return {
            type: 'log',
            data: { text: trimmed, severity: 'info' }
        };
    }
}

module.exports = NmapAdapter;
