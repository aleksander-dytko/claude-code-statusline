#!/bin/bash
# claude-code-statusline — Enhanced status line for Claude Code
# https://github.com/aleksander-dytko/claude-code-statusline
# MIT License — Aleksander Dytko 2026
#
# Displays: model | git repo@branch | context window | 5h limit | 7d limit | extra usage

set -f  # disable globbing

# ─── Configuration (override via environment variables) ─────────────────────
STATUSLINE_SHOW_GIT="${STATUSLINE_SHOW_GIT:-true}"
STATUSLINE_SHOW_CONTEXT="${STATUSLINE_SHOW_CONTEXT:-true}"
STATUSLINE_SHOW_SESSION="${STATUSLINE_SHOW_SESSION:-true}"
STATUSLINE_SHOW_WEEKLY="${STATUSLINE_SHOW_WEEKLY:-true}"
STATUSLINE_SHOW_EXTRA="${STATUSLINE_SHOW_EXTRA:-true}"
STATUSLINE_CACHE_TTL="${STATUSLINE_CACHE_TTL:-20}"           # seconds between API fetches
STATUSLINE_CACHE_DIR="${STATUSLINE_CACHE_DIR:-/tmp/claude}"  # cache directory
STATUSLINE_CURRENCY_SYMBOL="${STATUSLINE_CURRENCY_SYMBOL:-\$}"  # set to € for Europe
# ────────────────────────────────────────────────────────────────────────────

input=$(cat)

if [ -z "$input" ]; then
    printf "Claude"
    exit 0
fi

# Hard dependency check
if ! command -v jq >/dev/null 2>&1; then
    printf "Claude (install jq for full statusline — brew install jq)"
    exit 0
fi

# ─── ANSI colors ────────────────────────────────────────────────────────────
blue='\033[38;2;0;153;255m'
orange='\033[38;2;255;176;85m'
green='\033[38;2;0;160;0m'
cyan='\033[38;2;46;149;153m'
red='\033[38;2;255;85;85m'
yellow='\033[38;2;230;200;0m'
white='\033[38;2;220;220;220m'
dim='\033[2m'
reset='\033[0m'

# ─── Helper functions ────────────────────────────────────────────────────────

# Format token counts: 50000 → "50k", 1200000 → "1.2m"
format_tokens() {
    local num=$1
    if [ "$num" -ge 1000000 ]; then
        awk "BEGIN {printf \"%.1fm\", $num / 1000000}"
    elif [ "$num" -ge 1000 ]; then
        awk "BEGIN {printf \"%.0fk\", $num / 1000}"
    else
        printf "%d" "$num"
    fi
}

# Color for plan limits (session / weekly): green < 70%, yellow 70-90%, red ≥ 90%
plan_color() {
    local pct=$1
    if   [ "$pct" -ge 90 ]; then echo "$red"
    elif [ "$pct" -ge 70 ]; then echo "$yellow"
    else echo "$green"
    fi
}

# Color for context window: green < 50%, yellow 50-75%, red ≥ 75%
context_color() {
    local pct=$1
    if   [ "$pct" -ge 75 ]; then echo "$red"
    elif [ "$pct" -ge 50 ]; then echo "$yellow"
    else echo "$green"
    fi
}

# Color for extra usage spend: green < 50%, yellow 50-80%, red ≥ 80%
extra_color() {
    local pct=$1
    if   [ "$pct" -ge 80 ]; then echo "$red"
    elif [ "$pct" -ge 50 ]; then echo "$yellow"
    else echo "$green"
    fi
}

# Resolve OAuth token — tries 4 sources in order
get_oauth_token() {
    # 1. Explicit env var override
    if [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
        echo "$CLAUDE_CODE_OAUTH_TOKEN"
        return 0
    fi

    # 2. macOS Keychain
    if command -v security >/dev/null 2>&1; then
        local blob
        blob=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
        if [ -n "$blob" ]; then
            local token
            token=$(echo "$blob" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
            if [ -n "$token" ] && [ "$token" != "null" ]; then
                echo "$token"; return 0
            fi
        fi
    fi

    # 3. Linux credentials file
    local creds_file="${HOME}/.claude/.credentials.json"
    if [ -f "$creds_file" ]; then
        local token
        token=$(jq -r '.claudeAiOauth.accessToken // empty' "$creds_file" 2>/dev/null)
        if [ -n "$token" ] && [ "$token" != "null" ]; then
            echo "$token"; return 0
        fi
    fi

    # 4. GNOME Keyring via secret-tool
    if command -v secret-tool >/dev/null 2>&1; then
        local blob
        blob=$(timeout 2 secret-tool lookup service "Claude Code-credentials" 2>/dev/null)
        if [ -n "$blob" ]; then
            local token
            token=$(echo "$blob" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
            if [ -n "$token" ] && [ "$token" != "null" ]; then
                echo "$token"; return 0
            fi
        fi
    fi

    echo ""
}

# Convert ISO 8601 to Unix epoch (cross-platform: GNU date + BSD date)
iso_to_epoch() {
    local iso_str="$1"

    # GNU date (Linux)
    local epoch
    epoch=$(date -d "${iso_str}" +%s 2>/dev/null)
    [ -n "$epoch" ] && echo "$epoch" && return 0

    # BSD date (macOS)
    local stripped="${iso_str%%.*}"
    stripped="${stripped%%Z}"
    stripped="${stripped%%+*}"
    stripped="${stripped%%-[0-9][0-9]:[0-9][0-9]}"

    if [[ "$iso_str" == *"Z"* ]] || [[ "$iso_str" == *"+00:00"* ]] || [[ "$iso_str" == *"-00:00"* ]]; then
        epoch=$(env TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null)
    else
        epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null)
    fi

    [ -n "$epoch" ] && echo "$epoch" && return 0
    return 1
}

# Format ISO reset timestamp to compact local time
# Styles: time (4:30pm) | datetime (Mar 6, 4:30pm) | date (Mar 6)
format_reset_time() {
    local iso_str="$1"
    local style="$2"
    [ -z "$iso_str" ] || [ "$iso_str" = "null" ] && return

    local epoch
    epoch=$(iso_to_epoch "$iso_str") || return

    case "$style" in
        time)
            date -j -r "$epoch" +"%l:%M%p" 2>/dev/null | sed 's/^ //' | tr '[:upper:]' '[:lower:]' || \
            date -d "@$epoch" +"%l:%M%P" 2>/dev/null | sed 's/^ //'
            ;;
        datetime)
            date -j -r "$epoch" +"%b %-d, %l:%M%p" 2>/dev/null | sed 's/  / /g; s/^ //' | tr '[:upper:]' '[:lower:]' || \
            date -d "@$epoch" +"%b %-d, %l:%M%P" 2>/dev/null | sed 's/  / /g; s/^ //'
            ;;
        *)
            date -j -r "$epoch" +"%b %-d" 2>/dev/null | tr '[:upper:]' '[:lower:]' || \
            date -d "@$epoch" +"%b %-d" 2>/dev/null
            ;;
    esac
}

# Format time remaining until reset: epoch → "in 2h 24min", "in 47min", "soon"
format_countdown() {
    local iso_str="$1"
    [ -z "$iso_str" ] || [ "$iso_str" = "null" ] && return

    local epoch
    epoch=$(iso_to_epoch "$iso_str") || return

    local now diff hours mins
    now=$(date +%s)
    diff=$(( epoch - now ))

    [ "$diff" -le 0 ] && echo "soon" && return

    hours=$(( diff / 3600 ))
    mins=$(( (diff % 3600) / 60 ))

    if   [ "$hours" -ge 24 ]; then echo "resets in $(( hours / 24 ))d"
    elif [ "$hours" -ge 1 ];  then echo "resets in ${hours}h ${mins}min"
    else echo "resets in ${mins}min"
    fi
}

# ─── Parse stdin JSON ────────────────────────────────────────────────────────
model_name=$(echo "$input" | jq -r '.model.display_name // "Claude"')
cwd=$(echo "$input" | jq -r '.cwd // empty')

size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
[ "$size" -eq 0 ] 2>/dev/null && size=200000

input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
cache_create=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
cache_read=$(echo "$input"   | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
current=$(( input_tokens + cache_create + cache_read ))

used_tokens=$(format_tokens "$current")
total_tokens=$(format_tokens "$size")
pct_used=$(( size > 0 ? current * 100 / size : 0 ))

# ─── Fetch / cache usage API ─────────────────────────────────────────────────
cache_file="${STATUSLINE_CACHE_DIR}/statusline-usage-cache.json"
mkdir -p "${STATUSLINE_CACHE_DIR}"

needs_refresh=true
usage_data=""

if [ -f "$cache_file" ]; then
    cache_mtime=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null)
    now=$(date +%s)
    cache_age=$(( now - cache_mtime ))
    if [ "$cache_age" -lt "$STATUSLINE_CACHE_TTL" ]; then
        needs_refresh=false
        usage_data=$(cat "$cache_file" 2>/dev/null)
    fi
fi

if $needs_refresh; then
    token=$(get_oauth_token)
    if [ -n "$token" ] && [ "$token" != "null" ]; then
        response=$(curl -s --max-time 8 \
            -H "Accept: application/json" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $token" \
            -H "anthropic-beta: oauth-2025-04-20" \
            -H "User-Agent: claude-code-statusline/1.0.0" \
            "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)
        if [ -n "$response" ] && echo "$response" | jq . >/dev/null 2>&1; then
            usage_data="$response"
            echo "$response" > "$cache_file"
        fi
    fi
    [ -z "$usage_data" ] && [ -f "$cache_file" ] && usage_data=$(cat "$cache_file" 2>/dev/null)
fi

# ─── Build output ────────────────────────────────────────────────────────────
sep=" ${dim}|${reset} "
out=""

# Model name
out+="${blue}${model_name}${reset}"

# Git: project[wt]@branch +adds/-dels
if [ "${STATUSLINE_SHOW_GIT}" = "true" ] && [ -n "$cwd" ]; then
    display_dir="${cwd##*/}"
    git_branch=$(git -C "${cwd}" rev-parse --abbrev-ref HEAD 2>/dev/null)
    out+="${sep}${cyan}${display_dir}${reset}"
    if [ -n "$git_branch" ]; then
        # Detect linked git worktree (e.g. created by Claude Code's isolation: "worktree")
        git_dir=$(git -C "${cwd}" rev-parse --git-dir 2>/dev/null)
        if [[ "$git_dir" == *"/worktrees/"* ]]; then
            out+="${dim}[wt]${reset}"
        fi
        out+="${dim}@${reset}${green}${git_branch}${reset}"
        # Use HEAD diff to include both staged and unstaged changes
        git_stat=$(git -C "${cwd}" diff HEAD --numstat 2>/dev/null | awk '{a+=$1; d+=$2} END {if (a+d>0) printf "+%d -%d", a, d}')
        if [ -n "$git_stat" ]; then
            adds="${git_stat%% *}"
            dels="${git_stat##* }"
            out+=" ${dim}(${reset}${green}${adds}${reset} ${red}${dels}${reset}${dim})${reset}"
        fi
    fi
fi

# Context window
if [ "${STATUSLINE_SHOW_CONTEXT}" = "true" ]; then
    ctx_color=$(context_color "$pct_used")
    out+="${sep}${orange}${used_tokens}/${total_tokens}${reset} ${dim}(${reset}${ctx_color}${pct_used}%${reset}${dim})${reset}"
fi

# Usage limits from API
if [ -n "$usage_data" ] && echo "$usage_data" | jq -e . >/dev/null 2>&1; then

    five_pct=$(echo "$usage_data" | jq -r '.five_hour.utilization // 0' | awk '{printf "%.0f", $1}')
    five_reset_iso=$(echo "$usage_data" | jq -r '.five_hour.resets_at // empty')
    seven_pct=$(echo "$usage_data" | jq -r '.seven_day.utilization // 0' | awk '{printf "%.0f", $1}')
    seven_reset_iso=$(echo "$usage_data" | jq -r '.seven_day.resets_at // empty')

    # ⚡ fires on whichever limit is currently causing overflow (real-time signal)
    five_on_extra=false
    seven_on_extra=false
    [ "$five_pct" -ge 100 ] && five_on_extra=true
    [ "$seven_pct" -ge 100 ] && seven_on_extra=true

    # 5-hour session limit
    if [ "${STATUSLINE_SHOW_SESSION}" = "true" ]; then
        five_color=$(plan_color "$five_pct")
        five_label="5h"
        $five_on_extra && five_label="⚡ 5h"

        out+="${sep}${white}${five_label}${reset} ${five_color}${five_pct}%${reset}"
        if $five_on_extra; then
            # At limit: show countdown to reset (more actionable than wall clock)
            five_countdown=$(format_countdown "$five_reset_iso")
            [ -n "$five_countdown" ] && out+=" ${dim}${five_countdown}${reset}"
        else
            # Under limit: show wall clock reset time
            five_reset=$(format_reset_time "$five_reset_iso" "time")
            [ -n "$five_reset" ] && out+=" ${dim}@${five_reset}${reset}"
        fi
    fi

    # 7-day weekly limit
    if [ "${STATUSLINE_SHOW_WEEKLY}" = "true" ]; then
        seven_color=$(plan_color "$seven_pct")
        seven_label="7d"
        $seven_on_extra && seven_label="⚡ 7d"

        out+="${sep}${white}${seven_label}${reset} ${seven_color}${seven_pct}%${reset}"
        if $seven_on_extra; then
            # At limit: show countdown to reset
            seven_countdown=$(format_countdown "$seven_reset_iso")
            [ -n "$seven_countdown" ] && out+=" ${dim}${seven_countdown}${reset}"
        else
            # Under limit: show wall clock reset time
            seven_reset=$(format_reset_time "$seven_reset_iso" "datetime")
            [ -n "$seven_reset" ] && out+=" ${dim}@${seven_reset}${reset}"
        fi
    fi

    # Extra usage — monthly billing summary (shown when extra is enabled)
    if [ "${STATUSLINE_SHOW_EXTRA}" = "true" ]; then
        extra_enabled=$(echo "$usage_data" | jq -r '.extra_usage.is_enabled // false')
        if [ "$extra_enabled" = "true" ]; then
            extra_pct=$(echo "$usage_data" | jq -r '.extra_usage.utilization // 0' | awk '{printf "%.0f", $1}')
            extra_used=$(echo "$usage_data" | jq -r '.extra_usage.used_credits // 0' | awk '{printf "%.2f", $1/100}')
            extra_limit=$(echo "$usage_data" | jq -r '.extra_usage.monthly_limit // 0' | awk '{printf "%.2f", $1/100}')
            extra_clr=$(extra_color "$extra_pct")

            sym="${STATUSLINE_CURRENCY_SYMBOL}"
            out+="${sep}${white}extra${reset} ${extra_clr}${sym}${extra_used}/${sym}${extra_limit}${reset}"

            extra_cap_left=$(echo "$usage_data" | jq -r '((.extra_usage.monthly_limit // 0) - (.extra_usage.used_credits // 0)) / 100' | awk '{printf "%.2f", $1}')
            out+=" ${dim}(${reset}${white}${sym}${extra_cap_left} left${reset}${dim})${reset}"
        fi
    fi
fi

printf "%b" "$out"
exit 0
