# >>> bettercode >>>
# `code` = Claude Code (permissions skipped, tmux teammate mode).
# Your previous `code` (VS Code CLI) lives on as `vscode`.
# https://github.com/fire17/bettercode

typeset -g _BETTERCODE_DIR="${${(%):-%N}:A:h}"

# Preserve the industry-standard `code` (VS Code) as `vscode` — resolved once,
# from the real binary on PATH (never our own function) or the macOS app bundle.
typeset -g _BETTERCODE_VSCODE_BIN="${_BETTERCODE_VSCODE_BIN:-$(whence -p code 2>/dev/null)}"
if [[ -z $_BETTERCODE_VSCODE_BIN && -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]]; then
  _BETTERCODE_VSCODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
fi
if [[ -n $_BETTERCODE_VSCODE_BIN ]]; then
  vscode() { "$_BETTERCODE_VSCODE_BIN" "$@" }
fi

# -pp watcher: inject the prompt into this pane once Claude Code's composer is
# ready, as if the user typed it. Three phases guard against the stale-frame
# race (a dead claude's last frame still on screen while the new one boots —
# sending then could answer the trust dialog):
#   0: wait until the pane's foreground process is claude
#   1: wait until the ready marker is ABSENT (new claude cleared the screen)
#   2: wait until the ready marker is PRESENT — only then send
# If claude exits after being seen, abort without sending. On timeout: send
# nothing (fail-safe — never type blind into a shell).
_bettercode_pp_watch() {
  emulate -L zsh
  local mux=$1 pane=$2 prompt=$3
  local tries=${_BETTERCODE_PP_TRIES:-1200} interval=${_BETTERCODE_PP_INTERVAL:-0.5}
  local marker='bypass permissions on'
  local phase=0 out i tty=''
  for i in {1..$tries}; do
    sleep $interval
    case $mux in
      herdr)
        [[ "$(herdr pane process-info --pane "$pane" 2>/dev/null)" == *'"name":"claude"'* ]] \
          || { (( phase )) && return 1; continue }
        out="$(herdr pane read "$pane" --source visible 2>/dev/null)" ;;
      tmux)
        # claude may not lead the pane's foreground process group (e.g. when
        # launched from a script), so check the pane's tty for any claude
        [[ -n $tty ]] || tty="$(tmux display-message -p -t "$pane" '#{pane_tty}' 2>/dev/null)"
        ps -o comm= -t "${tty#/dev/}" 2>/dev/null | grep -qE '(^|/)claude$' \
          || { (( phase )) && return 1; continue }
        out="$(tmux capture-pane -p -t "$pane" 2>/dev/null)" ;;
    esac
    (( phase == 0 )) && phase=1
    if (( phase == 1 )); then
      [[ $out == *$marker* ]] || phase=2
      continue
    fi
    if [[ $out == *$marker* ]]; then
      case $mux in
        herdr)
          herdr pane send-text "$pane" "$prompt" && sleep 0.3 \
            && herdr pane send-keys "$pane" Enter ;;
        tmux)
          tmux send-keys -t "$pane" -l -- "$prompt" && sleep 0.3 \
            && tmux send-keys -t "$pane" Enter ;;
      esac
      return
    fi
  done
  return 1
}

# `code -p any words here` (quotes optional) joins everything after -p into one
# prompt. `code -pp any words` opens a NORMAL interactive session and types the
# prompt in once the composer is ready (claude never sees print mode) — via
# herdr or tmux when inside one, else an expect pty wrapper. Other claude flags
# (--model, --effort, --resume, ...) go BEFORE -p/-pp.
unalias code 2>/dev/null
code() {
  local pre=()
  while (( $# )); do
    case $1 in
      -p|--print)
        shift
        if (( $# )); then
          claude --dangerously-skip-permissions --teammate-mode tmux "${pre[@]}" -p "$*"
        else
          claude --dangerously-skip-permissions --teammate-mode tmux "${pre[@]}" -p
        fi
        return ;;
      -pp|--pass-through)
        shift
        if (( ! $# )); then
          print -ru2 -- "code: -pp needs a prompt (quotes optional)"
          return 1
        fi
        if [[ -n ${HERDR_PANE_ID:-} ]] && command -v herdr >/dev/null 2>&1; then
          _bettercode_pp_watch herdr "$HERDR_PANE_ID" "$*" &!
        elif [[ -n ${TMUX_PANE:-} ]] && command -v tmux >/dev/null 2>&1; then
          _bettercode_pp_watch tmux "$TMUX_PANE" "$*" &!
        elif command -v expect >/dev/null 2>&1; then
          BETTERCODE_PROMPT="$*" expect "$_BETTERCODE_DIR/bettercode-pp.exp" "${pre[@]}"
          return
        else
          print -ru2 -- "code: -pp needs herdr, tmux, or expect on PATH — opening claude without injection"
        fi
        claude --dangerously-skip-permissions --teammate-mode tmux "${pre[@]}"
        return ;;
      *) pre+=("$1"); shift ;;
    esac
  done
  claude --dangerously-skip-permissions --teammate-mode tmux "${pre[@]}"
}
# <<< bettercode >>>
