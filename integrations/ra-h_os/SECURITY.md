# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability, please report it privately:

1. **Do NOT open a public issue**
2. Email: security@ra-h.app (or use GitHub Security Advisories)
3. Include: description, steps to reproduce, potential impact

We will respond within 48 hours and work with you on a fix.

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.1.x   | ✅        |

## Security Considerations

### API Keys
- API keys are stored locally in your browser's localStorage
- Keys are never sent to any server except the respective AI provider (OpenAI, Anthropic)
- Clear your browser data to remove stored keys

### Local Database
- All data is stored locally in SQLite at `~/Library/Application Support/RA-H/db/rah.sqlite`
- No data is sent to external servers (except AI API calls with your keys)
- Back up this file to preserve your data

### MCP Server
- The MCP server binds only to `127.0.0.1` (localhost)
- Do not expose it to external networks
- Only connect trusted AI assistants
