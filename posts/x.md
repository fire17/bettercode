# X thread draft (do not auto-post)

1/ `code` used to mean VS Code. On my machine it now means Claude Code — and VS Code
didn't lose anything: it's still right there as `vscode`.

bettercode: a ~30-line zsh plugin. 🧵

2/ The killer detail: no more quote gymnastics.

    code -p fix the failing test

Everything after -p becomes ONE prompt. Flags go before it:

    code --effort low -p quick question
    code --model haiku -p summarize this repo

3/ Safety ladder:
- resolves the REAL VS Code binary before overriding (PATH, then the macOS app bundle)
- installer detects it and tells you loudly: "your previous 'code' is now 'vscode'"
- idempotent install, one marked block in .zshrc, uninstall = delete the block
- 12-assertion test suite, CI on ubuntu+macos

4/ Roadmap: bettercode is the front door. Next up — a patch mechanism for Claude Code
itself: personal & community patches, version-tracked, re-applied intelligently across
updates. Better --resume, built-in search, your idea here.

5/ MIT, zero deps:
https://github.com/fire17/bettercode

(HN: <link after posting>)

**Posting notes:** post after HN; put the install one-liner in the reply, not the hook.
