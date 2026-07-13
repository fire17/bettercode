#!/bin/zsh
# bettercode test suite — zero deps, stubs claude & VS Code, never touches real config.
set -u
DIR="${0:A:h}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
PASS=0 FAIL=0

t() { # t <name> <expected> <actual>
  if [[ $2 == $3 ]]; then
    (( PASS++ )); print -r -- "ok   - $1"
  else
    (( FAIL++ )); print -r -- "FAIL - $1"; print -r -- "  expected: $2"; print -r -- "  actual:   $3"
  fi
}

# stub claude: prints one line per arg, so prompt-joining is observable
mkdir -p "$TMP/bin"
cat > "$TMP/bin/claude" <<'EOF'
#!/bin/sh
printf '%s\n' "$@"
EOF
chmod +x "$TMP/bin/claude"

run() { # run [extra-path] -- args...  -> code output via plugin in a clean zsh
  local extra=""
  [[ $1 != -- ]] && { extra="$1"; shift }
  shift # --
  PATH="$TMP/bin${extra:+:$extra}:$PATH" zsh -fc "
    source '$DIR/bettercode.plugin.zsh'
    code $*"
}

# 1. unquoted multi-word prompt joins into ONE arg after -p
t "unquoted -p joins words" \
"--dangerously-skip-permissions
--teammate-mode
tmux
-p
fix the failing test" \
"$(run -- -p fix the failing test)"

# 2. quoted prompt identical
t "quoted -p same result" \
"--dangerously-skip-permissions
--teammate-mode
tmux
-p
fix the failing test" \
"$(run -- -p '"fix the failing test"')"

# 3. flags before -p pass through in order
t "flags before -p preserved" \
"--dangerously-skip-permissions
--teammate-mode
tmux
--effort
low
--model
haiku
-p
quick question" \
"$(run -- --effort low --model haiku -p quick question)"

# 4. bare -p (no prompt) passes -p alone (stdin mode)
t "bare -p passes through" \
"--dangerously-skip-permissions
--teammate-mode
tmux
-p" \
"$(run -- -p)"

# 5. no -p: plain passthrough
t "no -p passthrough" \
"--dangerously-skip-permissions
--teammate-mode
tmux
--resume" \
"$(run -- --resume)"

# 6. --print treated like -p
t "--print joins words" \
"--dangerously-skip-permissions
--teammate-mode
tmux
-p
hello there" \
"$(run -- --print hello there)"

# 7. VS Code binary on PATH is preserved as vscode
mkdir -p "$TMP/vsc"
printf '#!/bin/sh\necho "VSCODE-BIN $@"\n' > "$TMP/vsc/code"
chmod +x "$TMP/vsc/code"
t "vscode preserved when VS Code present" \
"VSCODE-BIN --version" \
"$(PATH="$TMP/vsc:$TMP/bin:$PATH" zsh -fc "source '$DIR/bettercode.plugin.zsh'; vscode --version")"

# 8. no VS Code -> no vscode function
t "no vscode when VS Code absent" \
"absent" \
"$(PATH="$TMP/bin:/usr/bin:/bin" _BETTERCODE_VSCODE_BIN= zsh -fc "
  source '$DIR/bettercode.plugin.zsh'
  whence -w vscode >/dev/null || echo absent")"

# 9. pre-existing alias code is overridden by the function
t "pre-existing alias overridden" \
"code: function" \
"$(PATH="$TMP/bin:$PATH" zsh -fc "
  alias code='echo old'
  source '$DIR/bettercode.plugin.zsh'
  whence -w code")"

# --- -pp pass-through dispatch (stubbed herdr / tmux / expect) ---
export _BETTERCODE_PP_TRIES=200 _BETTERCODE_PP_INTERVAL=0.01
PPLOG="$TMP/pp.log"

mkstub_herdr() { # $1 = read behavior: normal | always-marker | claude-vanishes
  mkdir -p "$TMP/mux"; : > "$PPLOG"; rm -f "$TMP/n_read" "$TMP/n_proc"
  cat > "$TMP/mux/herdr" <<EOF
#!/bin/zsh
log="$PPLOG"; mode="$1"
case "\$1 \$2" in
  "pane process-info")
    n=\$(( \$(cat "$TMP/n_proc" 2>/dev/null || echo 0) + 1 )); echo \$n > "$TMP/n_proc"
    if [[ \$mode == claude-vanishes && \$n -gt 1 ]]; then echo '{}'; else echo '{"name":"claude"}'; fi ;;
  "pane read")
    n=\$(( \$(cat "$TMP/n_read" 2>/dev/null || echo 0) + 1 )); echo \$n > "$TMP/n_read"
    if [[ \$mode == always-marker || \$n -gt 1 ]]; then echo "bypass permissions on"; fi ;;
  "pane send-text") shift 2; shift; print -r -- "SEND-TEXT|\$*" >> "\$log" ;;
  "pane send-keys") shift 2; shift; print -r -- "SEND-KEYS|\$*" >> "\$log" ;;
esac
EOF
  chmod +x "$TMP/mux/herdr"
}

run_pp() { # run code with stub mux dir first on PATH; args after --
  shift # --
  PATH="$TMP/mux:$TMP/bin:$PATH" HERDR_PANE_ID="${STUB_HERDR_PANE:-}" TMUX_PANE="${STUB_TMUX_PANE:-}" \
    zsh -fc "source '$DIR/bettercode.plugin.zsh'; code $*" 2>&1
}

# 13. -pp without a prompt errors
out="$(PATH="$TMP/bin:$PATH" zsh -fc "source '$DIR/bettercode.plugin.zsh'; code -pp" 2>&1; echo "rc=$?")"
t "-pp without prompt errors" "yes" "$(print -r -- "$out" | grep -q 'needs a prompt' && print -r -- "$out" | grep -q 'rc=1' && echo yes)"

# 14. herdr path: waits for clear-then-marker, sends prompt then Enter
mkstub_herdr normal
STUB_HERDR_PANE="w0:p0" run_pp -- -pp fix the failing test >/dev/null
sleep 1
t "herdr -pp sends joined prompt + Enter" \
"SEND-TEXT|fix the failing test
SEND-KEYS|Enter" \
"$(cat "$PPLOG")"

# 15. stale-frame guard: marker visible from the first poll -> never send
mkstub_herdr always-marker
STUB_HERDR_PANE="w0:p0" run_pp -- -pp danger prompt >/dev/null
sleep 3
t "stale frame -> no injection (fail-safe)" "" "$(cat "$PPLOG")"

# 16. claude exits after being seen -> watcher aborts, no send
mkstub_herdr claude-vanishes
STUB_HERDR_PANE="w0:p0" run_pp -- -pp should never arrive >/dev/null
sleep 1
t "claude vanished -> watcher aborts" "" "$(cat "$PPLOG")"

# 17. tmux path: send-keys -l prompt, then Enter
mkdir -p "$TMP/mux"; : > "$PPLOG"; rm -f "$TMP/n_read"
cat > "$TMP/mux/tmux" <<EOF
#!/bin/zsh
log="$PPLOG"
case "\$1" in
  display-message) echo /dev/ttys999 ;;
  capture-pane)
    n=\$(( \$(cat "$TMP/n_read" 2>/dev/null || echo 0) + 1 )); echo \$n > "$TMP/n_read"
    (( n > 1 )) && echo "bypass permissions on" ;;
  send-keys) shift; print -r -- "SEND-KEYS|\$*" >> "\$log" ;;
esac
EOF
printf '#!/bin/zsh\necho claude\n' > "$TMP/mux/ps"
chmod +x "$TMP/mux/tmux" "$TMP/mux/ps"
rm -f "$TMP/mux/herdr"
STUB_TMUX_PANE="%7" run_pp -- -pp fix the failing test >/dev/null
sleep 1
t "tmux -pp literal send-keys + Enter" \
"SEND-KEYS|-t %7 -l -- fix the failing test
SEND-KEYS|-t %7 Enter" \
"$(cat "$PPLOG")"

# 18. bare terminal: expect fallback gets BETTERCODE_PROMPT + pre-flags
: > "$PPLOG"; rm -f "$TMP/mux/tmux"
cat > "$TMP/mux/expect" <<EOF
#!/bin/zsh
print -r -- "EXPECT|\$BETTERCODE_PROMPT|\${@:2}" >> "$PPLOG"
EOF
chmod +x "$TMP/mux/expect"
run_pp -- --model haiku -pp quick question >/dev/null
t "expect fallback: env prompt + pre-flags" \
"EXPECT|quick question|--model haiku" \
"$(cat "$PPLOG")"
rm -rf "$TMP/mux"
unset _BETTERCODE_PP_TRIES _BETTERCODE_PP_INTERVAL STUB_HERDR_PANE STUB_TMUX_PANE

# 19-21. installer: appends once, idempotent, detects VS Code
export ZDOTDIR="$TMP/home"; mkdir -p "$ZDOTDIR"; : > "$ZDOTDIR/.zshrc"
out1="$(PATH="$TMP/vsc:$TMP/bin:$PATH" "$DIR/install.sh")"
t "installer appends source block" "1" "$(grep -c 'bettercode.plugin.zsh' "$ZDOTDIR/.zshrc")"
PATH="$TMP/vsc:$TMP/bin:$PATH" "$DIR/install.sh" >/dev/null
t "installer idempotent (still one block)" "1" "$(grep -c 'bettercode.plugin.zsh' "$ZDOTDIR/.zshrc")"
t "installer announces vscode rename" "yes" "$(print -r -- "$out1" | grep -q "now 'vscode'" && echo yes)"
unset ZDOTDIR

print -r -- ""
print -r -- "passed: $PASS  failed: $FAIL  total: $(( PASS + FAIL ))"
(( FAIL == 0 ))
