#!/usr/bin/env bash
# claude-code-statusline installer
# https://github.com/aleksander-dytko/claude-code-statusline
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/aleksander-dytko/claude-code-statusline/main/install.sh | bash

set -e

REPO_URL="https://raw.githubusercontent.com/aleksander-dytko/claude-code-statusline/main"
CLAUDE_DIR="${HOME}/.claude"
SCRIPT_PATH="${CLAUDE_DIR}/statusline.sh"
SETTINGS_PATH="${CLAUDE_DIR}/settings.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { printf "${GREEN}[claude-code-statusline]${NC} %s\n" "$1"; }
warn()  { printf "${YELLOW}[warn]${NC} %s\n" "$1"; }
error() { printf "${RED}[error]${NC} %s\n" "$1" >&2; exit 1; }

# ─── Prerequisites ────────────────────────────────────────────────────────────
info "Checking prerequisites..."

command -v curl >/dev/null 2>&1 || error "curl is required. Install it and try again."
command -v jq >/dev/null 2>&1   || error "jq is required.\n  macOS: brew install jq\n  Ubuntu: sudo apt install jq"
command -v bash >/dev/null 2>&1 || error "bash is required."

# ─── Claude directory ─────────────────────────────────────────────────────────
if [ ! -d "$CLAUDE_DIR" ]; then
    warn "$HOME/.claude directory not found. Is Claude Code installed?"
    printf "Create ~/.claude and continue? [y/N] "
    read -r answer
    [ "$answer" = "y" ] || [ "$answer" = "Y" ] || error "Aborted."
    mkdir -p "$CLAUDE_DIR"
fi

# ─── Download statusline.sh ───────────────────────────────────────────────────
info "Downloading statusline.sh → ${SCRIPT_PATH}"
curl -fsSL "${REPO_URL}/statusline.sh" -o "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"

# ─── Update settings.json ─────────────────────────────────────────────────────
STATUSLINE_CONFIG='{"type":"command","command":"bash ~/.claude/statusline.sh"}'

if [ -f "$SETTINGS_PATH" ]; then
    info "Updating existing ~/.claude/settings.json (preserving all other settings)..."
    tmp_file=$(mktemp)
    if jq --argjson sl "$STATUSLINE_CONFIG" '. + {statusLine: $sl}' "$SETTINGS_PATH" > "$tmp_file"; then
        mv "$tmp_file" "$SETTINGS_PATH"
    else
        rm -f "$tmp_file"
        error "Failed to update settings.json. It may contain invalid JSON. Check the file and try again."
    fi
else
    info "Creating ~/.claude/settings.json..."
    printf '{"statusLine":%s}\n' "$STATUSLINE_CONFIG" > "$SETTINGS_PATH"
fi

# ─── Done ─────────────────────────────────────────────────────────────────────
printf "\n"
info "Installation complete!"
printf "\n"
printf "  %bRestart Claude Code%b to activate the status line.\n" "${GREEN}" "${NC}"
printf "\n"
printf "  Status line will show:\n"
printf "    model | git repo@branch | context window | cost | 5h limit | 7d limit | extra usage\n"
printf "\n"
printf "  Customize with environment variables:\n"
printf "    export STATUSLINE_CURRENCY_SYMBOL='€'   # for European billing\n"
printf "    export STATUSLINE_SHOW_EXTRA=false       # hide extra usage section\n"
printf "    export STATUSLINE_CACHE_TTL=120          # refresh every 2 minutes\n"
printf "\n"
printf "  Docs: https://github.com/aleksander-dytko/claude-code-statusline\n"
printf "\n"
