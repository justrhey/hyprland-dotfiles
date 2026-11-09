#!/usr/bin/env bash
# Symlink this repo's hypr/ into ~/.config/hypr.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/hypr"
DEST="$HOME/.config/hypr"

if [ ! -d "$SRC" ]; then
  echo "error: $SRC not found" >&2
  exit 1
fi

mkdir -p "$HOME/.config"

if [ -L "$DEST" ]; then
  current="$(readlink -f "$DEST")"
  if [ "$current" = "$(readlink -f "$SRC")" ]; then
    echo "already linked: $DEST -> $SRC"
    exit 0
  fi
  echo "replacing existing symlink: $DEST -> $current"
  rm "$DEST"
elif [ -e "$DEST" ]; then
  backup="$DEST.bak.$(date +%Y%m%d-%H%M%S)"
  echo "backing up existing config: $DEST -> $backup"
  mv "$DEST" "$backup"
fi

ln -s "$SRC" "$DEST"
echo "linked: $DEST -> $SRC"
echo "run 'hyprctl reload' or re-login to apply."
