# Changelog

## v0.1.0 — 2026-07-13

Initial release.

- `code` opens Claude Code (`--dangerously-skip-permissions --teammate-mode tmux`)
- previous `code` (VS Code CLI) safely preserved as `vscode` — resolved from the real
  binary on PATH or the macOS app bundle, never deleted or overwritten
- quotes-optional one-shot prompts: everything after `-p`/`--print` is joined into a
  single prompt string
- any claude flag placed before `-p` passes through verbatim (`--effort`, `--model`,
  `--resume`, ...)
- idempotent installer with VS Code detection and usage intro
- 12-assertion dependency-free test suite; CI on ubuntu + macos
