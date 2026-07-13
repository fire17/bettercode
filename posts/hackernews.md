# Show HN draft (do not auto-post)

**Title:** Show HN: bettercode – `code` opens Claude Code, VS Code lives on as `vscode`

**Body:**

I type `code` a hundred times a day, but these days what I want it to open is Claude
Code, not VS Code. bettercode is a ~30-line zsh plugin that makes `code` launch
`claude --dangerously-skip-permissions --teammate-mode tmux`, while resolving the real
VS Code binary first and keeping it callable as `vscode` — nothing deleted, nothing
overwritten.

The bit I actually built it for: `code -p fix the failing test` works without quotes.
Everything after `-p` is joined into one prompt string, and any claude flag before `-p`
(`--effort low`, `--model haiku`, `--resume`) passes through verbatim.

Design choices I'd like critique on:

- hijacking the industry-standard `code` name is rude by default — is install-time
  detection + a loud `vscode` rename announcement enough consent?
- `--dangerously-skip-permissions` is the point of the wrapper for me (tmux teammate
  workflows), but it's a sharp default to ship. README leads with the warning; would
  you gate it behind an env var instead?
- roadmap: a patch mechanism for Claude Code itself — version-tracked, intelligently
  re-applied personal/community patches (better `--resume`, built-in search). Curious
  if others are already maintaining private patch sets against the claude binary.

Repo: https://github.com/fire17/bettercode

(X thread: <link after posting>)

**Posting notes:** post morning US time; first comment = the safety table from the
README + the uninstall one-liner, so the "it clobbers code!" thread has an anchor.
