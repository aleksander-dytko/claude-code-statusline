# Troubleshooting

## Status line not showing

**Symptom:** Claude Code starts but no status line appears.

1. Check that `~/.claude/settings.json` contains the `statusLine` key:
   ```bash
   cat ~/.claude/settings.json | jq '.statusLine'
   ```
   Expected:
   ```json
   {
     "type": "command",
     "command": "bash ~/.claude/statusline.sh"
   }
   ```

2. Verify the script exists:
   ```bash
   ls -la ~/.claude/statusline.sh
   ```

3. Test the script manually (it expects JSON on stdin — empty input returns "Claude"):
   ```bash
   echo '{}' | bash ~/.claude/statusline.sh
   ```

4. Restart Claude Code completely after installation.

---

## `jq: command not found`

The script requires `jq` for JSON parsing.

**macOS:**
```bash
brew install jq
```

**Ubuntu/Debian:**
```bash
sudo apt install jq
```

**Other Linux:** Check your package manager — the package is usually called `jq`.

---

## Session and weekly usage not showing

**Symptom:** Model, git, and context window show fine, but 5h/7d sections are blank.

This means the script couldn't get a valid OAuth token. Try these in order:

**1. Check if token exists in macOS Keychain:**
```bash
security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null | jq -r '.claudeAiOauth.accessToken' | head -c 20
```
Should print the first 20 characters of a token.

**2. Check Linux credentials file:**
```bash
cat ~/.claude/.credentials.json | jq -r '.claudeAiOauth.accessToken' | head -c 20
```

**3. Set token explicitly as a fallback:**
Claude Code stores its token in the Keychain after you log in. If you've logged in to Claude Code, the token should be there. If not, re-authenticate:
```bash
claude /login
```

**4. Test API connectivity directly:**
```bash
token=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null | jq -r '.claudeAiOauth.accessToken')
curl -s -H "Authorization: Bearer $token" -H "anthropic-beta: oauth-2025-04-20" \
  "https://api.anthropic.com/api/oauth/usage" | jq .
```

---

## Extra usage section not showing

**Symptom:** Session and weekly limits show, but "extra" is missing.

Extra usage only shows when `is_enabled: true` in the API response. Check:

```bash
cat /tmp/claude/statusline-usage-cache.json | jq '.extra_usage'
```

If `is_enabled` is `false`, extra usage is disabled on your account. Enable it in your Claude.ai account settings under "Plan usage limits".

---

## Currency shows `$` but I'm billed in euros

Set the currency symbol in your shell profile:

```bash
# ~/.zshrc or ~/.bashrc
export STATUSLINE_CURRENCY_SYMBOL='€'
```

---

## `settings.json` parse error during install

**Symptom:** `install.sh` fails with `Failed to update settings.json. It may contain invalid JSON.`

Claude Code can sometimes write settings.json with trailing commas or other non-standard JSON. Fix it:

```bash
# View the file
cat ~/.claude/settings.json

# Validate
jq . ~/.claude/settings.json
```

Fix any JSON errors (remove trailing commas, fix quotes) and re-run the installer.

---

## Git diff shows wrong numbers

By default the script uses `git diff HEAD --numstat` which shows all changes against the last commit (staged + unstaged). This is intentional — it shows your total unreleased work.

If you only want unstaged changes, you can fork the script and change this line:
```bash
# Change this:
git_stat=$(git -C "${cwd}" diff HEAD --numstat 2>/dev/null | ...)
# To this:
git_stat=$(git -C "${cwd}" diff --numstat 2>/dev/null | ...)
```

---

## Status line renders slowly

The API fetch has a 10-second timeout. If the Anthropic API is slow, it can block the status line render.

Mitigations:
- Increase `STATUSLINE_CACHE_TTL` to reduce fetch frequency
- The cache is per-machine — all Claude Code sessions share it, so only one session fetches at a time

If you're frequently hitting slow API responses, check your network connection to `api.anthropic.com`.

---

## Multiple Claude Code sessions — duplicate API calls

The script uses a lock file at `$STATUSLINE_CACHE_DIR/statusline-fetch.lock` to prevent concurrent fetches when multiple sessions start simultaneously. If the lock file gets stuck (e.g., from a crashed session):

```bash
rm /tmp/claude/statusline-fetch.lock
```

---

## Usage shows stale data or 5h/7d sections are missing

**Symptom:** The 5h/7d values are behind what the Claude app shows, or those sections are blank entirely.

This is usually caused by one of two things:

**1. Rate limiting** — The Anthropic API rate-limited a recent fetch. The script uses exponential backoff: 30s → 60s → 120s → 240s → 300s (capped). During backoff it shows the last good cached value. The `statusline-ratelimited` file stores the consecutive hit count.

**2. A stale lock file** — A previous session crashed while holding the fetch lock, blocking all future fetches.

**Fix (run all three):**
```bash
rm -f /tmp/claude/statusline-usage-cache.json \
      /tmp/claude/statusline-fetch-attempt \
      /tmp/claude/statusline-ratelimited
rmdir /tmp/claude/statusline-fetch.lock 2>/dev/null
```

Wait a few seconds for the next statusline render to fetch fresh data.

**Why rate limiting happens:** If multiple terminal tabs all open simultaneously, they can all try to fetch before any of them updates the shared lock — triggering a burst of API calls. The `statusline-fetch.lock` directory (atomic mkdir) prevents this in normal operation, but a crashed session can leave the lock behind.

---

## Balance not showing

The `bal` field is not available via the Anthropic OAuth API (`api.anthropic.com/api/oauth/usage`). Balance data is not returned in the API response, so this segment is not displayed.

---

## Reporting issues

Open an issue at https://github.com/aleksander-dytko/claude-code-statusline/issues with:
- Your OS and shell
- Output of `echo '{}' | bash ~/.claude/statusline.sh`
- Output of `jq . /tmp/claude/statusline-usage-cache.json` (if it exists)
