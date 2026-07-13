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

# 10-12. installer: appends once, idempotent, detects VS Code
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
