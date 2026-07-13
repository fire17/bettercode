# Changelog

## v0.2.1 — 2026-07-13

- test-only: fix a CI timing race (a lingering background watcher from the
  stale-frame test could fire into the next test's window on slow runners);
  guard tests now run the watcher in the foreground, send tests poll the log.
  Plugin code unchanged.

## v0.2.0 — 2026-07-13

**`-pp` — the pass-through prompt.** `code -pp any words here` opens a normal
interactive session and types the prompt into the composer as if the user wrote it
(claude never sees print mode; the session stays interactive after the answer).

- three injection lanes, auto-detected: herdr pane API → tmux send-keys → bundled
  `expect` pty wrapper for bare terminals; warning + plain session when none exist
- focus-proof: herdr/tmux lanes are server-side; expect owns the pty
- three-phase fail-safe (claude running → screen cleared → composer ready): never
  types into a shell, never answers a trust dialog, types nothing on timeout —
  live-verified through a real trust dialog
- suite grown to 18 assertions (dispatch, stale-frame guard, claude-exit abort,
  per-lane argv contracts); all three lanes live-verified end-to-end


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
