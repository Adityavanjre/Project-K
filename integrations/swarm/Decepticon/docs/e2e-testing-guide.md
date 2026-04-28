# E2E Testing Guide — LLM Gateway Enhancement

Manual testing procedures for verifying the LLM gateway features.

## Prerequisites

- Docker and Docker Compose installed
- At least one LLM provider API key or subscription
- `make dev` successfully starts all services

## Scenario 1: API Key Provider Routing

**Providers:** Anthropic, OpenAI, Google, MiniMax

### Steps
1. Set API key(s) in `~/.decepticon/.env`:
   ```
   ANTHROPIC_API_KEY=sk-ant-...
   ```
2. Start services: `make dev`
3. Verify LiteLLM health: `curl http://localhost:4000/health`
4. Test model routing:
   ```bash
   curl -X POST http://localhost:4000/chat/completions \
     -H "Authorization: Bearer sk-decepticon-master" \
     -H "Content-Type: application/json" \
     -d '{"model": "anthropic/claude-haiku-4-5", "messages": [{"role": "user", "content": "Say hello"}]}'
   ```
5. Verify response contains a valid completion

### Expected
- HTTP 200 with model response
- LiteLLM logs show the request routed to Anthropic

### Troubleshooting
- 401: Check API key is set in `.env` and loaded by Docker
- 404: Verify model name matches `config/litellm.yaml` entries


## Scenario 2: Claude Code OAuth Login + LLM Call

### Prerequisites
- Active Claude Pro/Max/Team subscription
- Browser access (or headless workaround)

### Steps
1. Ensure no `ANTHROPIC_API_KEY` is set (test auth-only path)
2. Run the onboard wizard:
   ```bash
   decepticon onboard
   ```
3. Select "Anthropic" provider, choose "Claude Code OAuth" auth method
4. Browser opens for OAuth login — complete the login
5. Verify tokens saved:
   ```bash
   ls -la ~/.config/anthropic/q/tokens.json
   ```
6. Start services: `make dev`
7. Test auth-based model:
   ```bash
   curl -X POST http://localhost:4000/chat/completions \
     -H "Authorization: Bearer sk-decepticon-master" \
     -H "Content-Type: application/json" \
     -d '{"model": "auth/claude-sonnet-4-6", "messages": [{"role": "user", "content": "Say hello"}]}'
   ```

### Expected
- OAuth login completes, tokens stored with 0600 permissions
- LLM call returns valid response through OAuth authentication
- No API key used — request uses OAuth bearer token

### Troubleshooting
- "No OAuth tokens found": Run `decepticon onboard` or `claude` CLI login
- Token refresh errors: Delete `~/.config/anthropic/q/tokens.json` and re-login
- Browser didn't open: Copy the URL from terminal and open manually


## Scenario 3: Codex OAuth Login + LLM Call

### Prerequisites
- OpenAI ChatGPT Plus/Pro subscription
- Codex CLI installed (`npm i -g @openai/codex`)

### Steps
1. Run Codex login: `codex login`
2. Verify tokens: `ls -la ~/.codex/auth.json`
3. Or use API key: set `OPENAI_API_KEY` in `.env`
4. Test via LiteLLM:
   ```bash
   curl -X POST http://localhost:4000/chat/completions \
     -H "Authorization: Bearer sk-decepticon-master" \
     -H "Content-Type: application/json" \
     -d '{"model": "openai/gpt-4.1", "messages": [{"role": "user", "content": "Say hello"}]}'
   ```

### Expected
- Model responds successfully
- Note: Codex OAuth tokens may have limited API scope — API key is recommended for direct use

### Troubleshooting
- OAuth token scope issues: Use `OPENAI_API_KEY` as fallback


## Scenario 4: Ollama Local Provider

### Prerequisites
- Ollama installed and running (`ollama serve`)
- At least one model pulled (`ollama pull llama3.2`)

### Steps
1. Verify Ollama is running:
   ```bash
   curl http://localhost:11434/api/tags
   ```
2. Set in `.env`:
   ```
   OLLAMA_API_BASE=http://localhost:11434
   OLLAMA_MODEL=llama3.2
   ```
3. Start services: `make dev`
4. Test Ollama routing:
   ```bash
   curl -X POST http://localhost:4000/chat/completions \
     -H "Authorization: Bearer sk-decepticon-master" \
     -H "Content-Type: application/json" \
     -d '{"model": "ollama/llama3.2", "messages": [{"role": "user", "content": "Say hello"}]}'
   ```

### Expected
- Response from local Ollama model
- No external API calls made

### Troubleshooting
- Connection refused: Ensure Ollama is running on the configured port
- In Docker: Verify `extra_hosts: ["host.docker.internal:host-gateway"]` in docker-compose.yml
- Set `OLLAMA_API_BASE=http://host.docker.internal:11434` for Docker access


## Scenario 5: Onboard Wizard Complete Flow

### Steps
1. Run: `decepticon onboard`
2. Step through all 5 wizard steps:
   - Select providers (e.g., Anthropic + Ollama)
   - Choose auth method per provider
   - Enter API keys or trigger OAuth
   - Select model profile (eco/max/test/auth)
   - Confirm .env generation
3. Verify output:
   ```bash
   cat ~/.decepticon/.env
   ```
4. Verify deprecated alias still works:
   ```bash
   decepticon config  # Should show deprecation notice then run onboard
   ```

### Expected
- Interactive wizard completes all 5 steps
- `.env` file written to `~/.decepticon/.env`
- `decepticon config` shows deprecation notice


## Scenario 6: Fallback Chain Activation

### Steps
1. Set `DECEPTICON_MODEL_PROFILE=auth` in `.env`
2. Start services with intentionally invalid OAuth tokens
3. Make a request to an auth-based model
4. Verify fallback activates to API-key model

### Expected
- Primary (auth) fails, fallback (API key) succeeds
- LiteLLM logs show retry with fallback model

### Troubleshooting
- If fallback doesn't activate: Check `router_settings.num_retries` in litellm.yaml


## Scenario 7: Token Refresh

### Steps
1. Complete Claude Code OAuth login
2. Manually edit `~/.config/anthropic/q/tokens.json` — set `expiresAt` to a past timestamp
3. Make an LLM call via auth model
4. Check that `tokens.json` is updated with a new `expiresAt`

### Expected
- Token auto-refreshes before the API call
- New token stored with future expiry
- LLM call succeeds without re-login


## Security Verification

After all scenarios, verify no tokens leak into logs:

```bash
# Should return zero matches (except test fixtures)
grep -r "sk-ant-oat01" decepticon/ --include="*.py" | grep -v test | grep -v fixture
docker compose logs litellm 2>&1 | grep -c "sk-ant-oat01"  # Should be 0
```
