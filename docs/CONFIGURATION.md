# Configuration

All configuration is done via environment variables. Add them to your shell profile.

## Shell profile locations

| Shell | Profile file |
|-------|-------------|
| zsh | `~/.zshrc` |
| bash | `~/.bashrc` or `~/.bash_profile` |
| fish | `~/.config/fish/config.fish` |

## Variables

### `STATUSLINE_SHOW_GIT`
**Default:** `true`

Show the git segment: `project@branch (+N -M)`.

Requires the current working directory to be a git repository. If it's not, the segment is silently omitted.

```bash
export STATUSLINE_SHOW_GIT=false  # hide git segment
```

---

### `STATUSLINE_SHOW_CONTEXT`
**Default:** `true`

Show the context window segment: `ctx 45k/200k (22%)`.

Percentage is color-coded: green < 50%, yellow 50–75%, red ≥ 75%.

```bash
export STATUSLINE_SHOW_CONTEXT=false
```

---

### `STATUSLINE_SPLIT_LINES`
**Default:** `false`

When `true`, splits the status line into two rows:

```
Line 1 (stdin — always fresh):   Sonnet 4.6 | project@main (+10 -3) | ctx 45k/200k (22%) | cost $0.07
Line 2 (OAuth API — cached):     5h 45% @4:30pm | 7d 78% @mar 14, 11am | extra ⚡ €17.30/€20 (€2.70 left)
```

Useful when terminal windows are narrow. Line 2 is only emitted when API data is available — no blank line appears during cache warm-up.

```bash
export STATUSLINE_SPLIT_LINES=true
```

Fish shell:
```fish
set -gx STATUSLINE_SPLIT_LINES true
```

---

### `STATUSLINE_SHOW_SESSION_COST`
**Default:** `true`

Show the session cost segment: `cost $0.07`.

The value comes from stdin (`cost.total_cost_usd`) — no API call required. Uses `STATUSLINE_CURRENCY_SYMBOL` as the prefix.

```bash
export STATUSLINE_SHOW_SESSION_COST=false
```

---

### `STATUSLINE_SHOW_SESSION`
**Default:** `true`

Show the 5-hour session usage limit: `5h 45% @4:30pm`.

Color-coded: green < 70%, yellow 70–90%, red ≥ 90%.

Requires a Claude Pro or Max subscription and a valid OAuth token.

```bash
export STATUSLINE_SHOW_SESSION=false
```

---

### `STATUSLINE_SHOW_WEEKLY`
**Default:** `true`

Show the 7-day weekly usage limit: `7d 100% @mar 6, 11:00am`.

Same color thresholds as session (70/90). Reset time shown as `Month Day, H:MMam/pm`.

```bash
export STATUSLINE_SHOW_WEEKLY=false
```

---

### `STATUSLINE_SHOW_EXTRA`
**Default:** `true`

Show the extra usage / overage billing section: `extra ⚡ $10.90/$20.00 ($9.10 left)`.

Only shown when extra usage is enabled on your account (`is_enabled: true`). The ⚡ indicator appears when a plan limit (5h or 7d) is at 100% and extra billing is actively being consumed. The "left" amount shows how much of your monthly limit remains.

Extra usage color: green < 50% of limit, yellow 50–80%, red ≥ 80%.

```bash
export STATUSLINE_SHOW_EXTRA=false
```

---

### `STATUSLINE_CURRENCY_SYMBOL`
**Default:** `$`

Currency prefix for session cost, extra usage amounts, and any future monetary fields. Set to `€` if your account bills in euros.

```bash
export STATUSLINE_CURRENCY_SYMBOL='€'
```

---

### `STATUSLINE_CACHE_TTL`
**Default:** `60`

Seconds between API fetches for usage data. Higher values reduce API calls but mean slightly stale usage numbers. The cache is shared across all terminal tabs — only one API call is made per TTL period regardless of how many sessions are open.

```bash
export STATUSLINE_CACHE_TTL=120  # refresh every 2 minutes
```

---

### `STATUSLINE_CACHE_DIR`
**Default:** `/tmp/claude`

Directory for the API response cache file. Change if `/tmp` is not available or you want persistent caching across reboots.

```bash
export STATUSLINE_CACHE_DIR="${HOME}/.claude/cache"
```

---

### `CLAUDE_CODE_OAUTH_TOKEN`
**Default:** _(auto-discovered)_

Explicit OAuth token override. Normally you don't need this — the script discovers the token automatically from the macOS Keychain, Linux credentials file, or GNOME Keyring.

Use this only if auto-discovery fails on your setup.

```bash
export CLAUDE_CODE_OAUTH_TOKEN="your_token_here"
```

## Fish shell note

Fish syntax uses `set -gx` instead of `export`:

```fish
set -gx STATUSLINE_CURRENCY_SYMBOL '€'
set -gx STATUSLINE_CACHE_TTL 120
set -gx STATUSLINE_SHOW_EXTRA false
```
