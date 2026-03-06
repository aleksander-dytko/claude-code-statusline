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

Show the context window segment: `45k/200k (22%)`.

Percentage is color-coded: green < 50%, yellow 50–75%, red ≥ 75%.

```bash
export STATUSLINE_SHOW_CONTEXT=false
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

Only shown when extra usage is enabled on your account (`is_enabled: true`). The ⚡ indicator appears when you have active spend (> $0 charged). The "left" amount shows how much of your monthly limit remains.

Extra usage color: green < 50% of limit, yellow 50–80%, red ≥ 80%.

```bash
export STATUSLINE_SHOW_EXTRA=false
```

---

### `STATUSLINE_CURRENCY_SYMBOL`
**Default:** `$`

Currency prefix for extra usage amounts. Set to `€` if your account bills in euros.

```bash
export STATUSLINE_CURRENCY_SYMBOL='€'
```

---

### `STATUSLINE_CACHE_TTL`
**Default:** `20`

Seconds between API fetches for usage data. Higher values reduce API calls but mean slightly stale usage numbers.

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
