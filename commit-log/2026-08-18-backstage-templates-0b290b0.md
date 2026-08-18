---
repo: backstage-templates
date: 2026-08-18
commit: 0b290b0
type: feat
scope: 
tags: [commit-log]
---

# feat: preload sandbox-tty image for TTY toolset in sandboxes

Sandboxes scaffolded from the nix-sandbox template now default to
sandbox-tty:latest (zsh, tmux, nvim, yazi, starship, fzf, zoxide, bat, eza,
git) instead of bare nixos/nix, and the terminal opens zsh instead of /bin/sh.
