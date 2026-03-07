# Contributing

Thanks for your interest in improving claude-code-statusline!

## Quick start

1. Fork the repo and clone your fork
2. Make your changes in a feature branch
3. Test manually: `echo '{}' | bash statusline.sh`
4. Open a PR against `main`

## Guidelines

- **Keep it simple.** This is a single bash script with minimal dependencies (`bash`, `jq`, `curl`). Avoid adding build steps, transpilers, or new runtime dependencies.
- **Test on macOS and Linux.** The script must work on both. Use the `_stat_mtime` helper (not raw `stat`) for file timestamps, and test both GNU and BSD date where applicable.
- **Don't break existing config.** New features should be opt-in via `STATUSLINE_SHOW_*` or `STATUSLINE_*` environment variables with sensible defaults.
- **Match the existing style.** No tabs, 4-space indentation, `snake_case` variables, comments on non-obvious logic.

## What makes a good PR

- Fixes a bug with a clear description of what was wrong
- Adds a feature that multiple users have requested (link the issue)
- Improves performance without adding complexity
- Fixes docs that are wrong or misleading

## What to avoid

- Large refactors without discussion — open an issue first
- Adding Node.js, Python, or other runtime dependencies
- Cosmetic-only changes (whitespace, reordering, renaming) unless they fix a real problem

## Reporting bugs

Open an issue with:
- Your OS and shell (`bash --version`, `uname -a`)
- Output of `echo '{}' | bash ~/.claude/statusline.sh`
- Output of `jq . /tmp/claude/statusline-usage-cache.json` (if it exists)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
