# claude-code-statusline

An enhanced status line for [Claude Code](https://github.com/anthropics/claude-code) that shows model, git context, token usage, and live plan limits — all in one line.

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Shell: bash](https://img.shields.io/badge/shell-bash-green.svg)
![Platform: macOS | Linux](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-blue.svg)

---

## What it shows

```
Claude Sonnet 4.6 | project@main (+10 -3) | 45k/200k (22%) | effort: high | 5h 45% @4:30pm | 7d 100% @mar 6, 11:00am | extra ⚡ $10.90/$20.00 ($9.10 left)
│                   │                        │                 │              │                  │                           │
model               git branch + diff        context window    effort level   5-hour session     7-day weekly               overage billing
```

### Color coding

| Section | Green | Yellow | Red |
|---------|-------|--------|-----|
| 5h session | < 70% | 70–90% | ≥ 90% |
| 7d weekly  | < 70% | 70–90% | ≥ 90% |
| Context window | < 50% | 50–75% | ≥ 75% |
| Extra usage spend | < 50% of limit | 50–80% | ≥ 80% |

**⚡** appears next to "extra" when overage billing is active (spend > $0).

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/aleksander-dytko/claude-code-statusline/main/install.sh | bash
```

Then **restart Claude Code**. That's it — no API keys, no manual token setup.

### Requirements

- [Claude Code](https://github.com/anthropics/claude-code) (any version with `statusLine` support)
- `bash`, `curl`, `jq`
  - macOS: `brew install jq`
  - Ubuntu/Debian: `sudo apt install jq`
- A Claude Pro or Max subscription (for the usage limits API)

---

## How it works

Claude Code calls the status line script on every render, passing session context as JSON on stdin. The script reads the model name, context window usage, and current working directory from that JSON.

Git information (branch name and diff stats) comes from running `git` commands against the current directory.

Usage limits (5-hour session, 7-day weekly, and extra overage) are fetched from the Anthropic API at `api.anthropic.com/api/oauth/usage`. The script auto-discovers your OAuth token from the macOS Keychain, a Linux credentials file, or the `CLAUDE_CODE_OAUTH_TOKEN` environment variable — the same token Claude Code itself uses. Responses are cached for 60 seconds to avoid redundant requests.

When multiple Claude Code sessions start simultaneously, a lock file prevents concurrent API fetches — only one session fetches while others wait for the shared cache.

---

## Configuration

All settings are optional environment variables. Add them to your shell profile (`~/.zshrc`, `~/.bashrc`, or `~/.config/fish/config.fish`).

| Variable | Default | Description |
|----------|---------|-------------|
| `STATUSLINE_SHOW_GIT` | `true` | Show git repo, branch, and diff |
| `STATUSLINE_SHOW_CONTEXT` | `true` | Show context window token usage |
| `STATUSLINE_SHOW_EFFORT` | `true` | Show effort level |
| `STATUSLINE_SHOW_SESSION` | `true` | Show 5-hour session limit |
| `STATUSLINE_SHOW_WEEKLY` | `true` | Show 7-day weekly limit |
| `STATUSLINE_SHOW_EXTRA` | `true` | Show extra usage / overage billing |
| `STATUSLINE_CURRENCY_SYMBOL` | `$` | Currency prefix (set to `€` for Europe) |
| `STATUSLINE_CACHE_TTL` | `60` | Seconds between API refreshes |
| `STATUSLINE_CACHE_DIR` | `/tmp/claude` | Cache file directory |
| `CLAUDE_CODE_OAUTH_TOKEN` | _(auto)_ | Override OAuth token explicitly |

### Examples

```bash
# European billing
export STATUSLINE_CURRENCY_SYMBOL='€'

# Minimal — model + context only
export STATUSLINE_SHOW_GIT=false
export STATUSLINE_SHOW_EFFORT=false
export STATUSLINE_SHOW_SESSION=false
export STATUSLINE_SHOW_WEEKLY=false
export STATUSLINE_SHOW_EXTRA=false

# Refresh usage data every 2 minutes instead of 1
export STATUSLINE_CACHE_TTL=120
```

---

## Manual install

If you prefer not to pipe to bash:

```bash
curl -fsSL https://raw.githubusercontent.com/aleksander-dytko/claude-code-statusline/main/statusline.sh \
    -o ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Then add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline.sh"
  }
}
```

---

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

---

## License

MIT — see [LICENSE](LICENSE).
