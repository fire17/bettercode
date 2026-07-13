#!/bin/zsh
# bettercode installer — makes `code` open Claude Code, keeps VS Code as `vscode`.
# Run from the cloned repo:  ./install.sh      Uninstall: remove the bettercode
# block from your ~/.zshrc (between the >>> bettercode >>> markers).
set -e

DIR="${0:A:h}"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
PLUGIN="$DIR/bettercode.plugin.zsh"

[[ -r $PLUGIN ]] || { print -r -- "bettercode: plugin not found at $PLUGIN" >&2; exit 1; }

if ! command -v claude >/dev/null 2>&1; then
  print -r -- "⚠️  'claude' CLI not found on PATH — install Claude Code first:"
  print -r -- "    npm install -g @anthropic-ai/claude-code   (or: bun add -g)"
fi

# What does `code` mean today? (real binary on PATH, ignoring shell functions/aliases)
VSC="$(whence -p code 2>/dev/null || true)"
[[ -z $VSC && -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]] &&
  VSC="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"

# Idempotent: only append the source block once.
if grep -q "bettercode.plugin.zsh" "$ZSHRC" 2>/dev/null; then
  print -r -- "bettercode: already installed in $ZSHRC — nothing to do."
else
  {
    print -r -- ""
    print -r -- "# >>> bettercode >>>  (\`code\` = Claude Code; VS Code = \`vscode\`)"
    print -r -- "source \"$PLUGIN\""
    print -r -- "# <<< bettercode <<<"
  } >> "$ZSHRC"
  print -r -- "bettercode: installed into $ZSHRC"
fi

print -r -- ""
print -r -- "🪄 bettercode"
print -r -- "─────────────"
if [[ -n $VSC ]]; then
  print -r -- "VS Code detected. Your previous 'code' command is now 'vscode':"
  print -r -- "    vscode .        # opens VS Code, exactly as before"
else
  print -r -- "No VS Code CLI found — 'code' was free, nothing was renamed."
  print -r -- "(If you install VS Code later it will appear as 'vscode' automatically.)"
fi
print -r -- ""
print -r -- "'code' now launches Claude Code (permissions skipped, tmux teammate mode):"
print -r -- "    code                          # interactive session"
print -r -- "    code -p fix the failing test  # one-shot prompt, quotes optional"
print -r -- "    code --effort low -p quick q  # any claude flag works — put it BEFORE -p"
print -r -- "    code -pp fix this bug         # pass-through: NORMAL session, prompt typed"
print -r -- "                                  # in for you once the composer is ready"
print -r -- ""
print -r -- "Coming soon: an intelligent patch mechanism for Claude Code itself —"
print -r -- "personal & community patches (better --resume, built-in search, ...),"
print -r -- "version-tracked and auto-applied. See README."
print -r -- ""
print -r -- "Open a new terminal (or: source $ZSHRC) to activate."
