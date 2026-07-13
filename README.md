# bettercode

`code` now opens **Claude Code**. Your old `code` (VS Code) lives on as `vscode`.

One shell plugin, zero dependencies. Part of the `better*` family
([bettercd](https://github.com/fire17/bettercd), [betterkill](https://github.com/fire17/betterkill)).

## Install

```sh
git clone https://github.com/fire17/bettercode
cd bettercode && ./install.sh
```

The installer:

- checks whether the industry-standard `code` command (VS Code CLI) exists — if it
  does, it is **safely preserved as `vscode`** (nothing is deleted or overwritten;
  bettercode resolves the real binary and keeps it callable)
- appends one `source` block to your `~/.zshrc` (idempotent — safe to re-run)
- introduces the new `code` and what it does

Uninstall: delete the `# >>> bettercode >>>` block from your `~/.zshrc`.

## Usage

```sh
code                                # interactive Claude Code session
code -p fix the failing test       # one-shot prompt — quotes optional
code -p "works quoted too"
code --effort low -p quick question       # effort pre-set (low|medium|high|xhigh|max)
code --model haiku -p summarize this repo # any claude flag — put flags BEFORE -p
code --resume                       # everything else passes straight through
vscode .                            # your old code command, untouched
```

What `code` expands to:

```
claude --dangerously-skip-permissions --teammate-mode tmux [your flags] [-p "joined prompt"]
```

Everything after `-p`/`--print` is joined into a single prompt string, so
multi-word prompts need no quotes. Flags before `-p` pass through verbatim.

> ⚠️ `--dangerously-skip-permissions` means Claude runs tools without asking.
> That is the point of this wrapper — know what it implies, or edit
> `bettercode.plugin.zsh` to taste (it's ~30 lines).

## Roadmap: the patch mechanism

bettercode is the front door. Coming next: a mechanism to **apply, configure and
remove patches to Claude Code's own code**, enabling personal and community
features:

- a companion skill that intimately knows Claude Code's internals and knows how
  to modify them
- version-change tracking, with patches re-based and **auto-applied intelligently**
  across Claude Code updates
- example patches: a better built-in `--resume`, built-in search functions, and
  whatever the community dreams up

## Requirements

- zsh
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (`claude` on PATH)
- macOS or Linux
