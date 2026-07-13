# >>> bettercode >>>
# `code` = Claude Code (permissions skipped, tmux teammate mode).
# Your previous `code` (VS Code CLI) lives on as `vscode`.
# https://github.com/fire17/bettercode

# Preserve the industry-standard `code` (VS Code) as `vscode` — resolved once,
# from the real binary on PATH (never our own function) or the macOS app bundle.
typeset -g _BETTERCODE_VSCODE_BIN="${_BETTERCODE_VSCODE_BIN:-$(whence -p code 2>/dev/null)}"
if [[ -z $_BETTERCODE_VSCODE_BIN && -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]]; then
  _BETTERCODE_VSCODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
fi
if [[ -n $_BETTERCODE_VSCODE_BIN ]]; then
  vscode() { "$_BETTERCODE_VSCODE_BIN" "$@" }
fi

# `code -p any words here` (quotes optional) joins everything after -p into one
# prompt. Other claude flags (--model, --effort, --resume, ...) go BEFORE -p.
unalias code 2>/dev/null
code() {
  local pre=()
  while (( $# )); do
    if [[ $1 == -p || $1 == --print ]]; then
      shift
      if (( $# )); then
        claude --dangerously-skip-permissions --teammate-mode tmux "${pre[@]}" -p "$*"
      else
        claude --dangerously-skip-permissions --teammate-mode tmux "${pre[@]}" -p
      fi
      return
    fi
    pre+=("$1")
    shift
  done
  claude --dangerously-skip-permissions --teammate-mode tmux "${pre[@]}"
}
# <<< bettercode <<<
