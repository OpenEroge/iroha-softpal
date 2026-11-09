#!/usr/bin/env bash
# Build work/isolated-game: every top-level entry of iroha_game is a symlink,
# while save/ is a real, writable directory owned by the port. The engine must
# only ever be pointed at this root, never at iroha_game itself.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
require_game

mkdir -p "$ISO/save"
for src in "$GAME"/* "$GAME"/.[!.]*; do
  [[ -e "$src" ]] || continue
  name="$(basename "$src")"
  [[ "$name" == "save" ]] && continue
  dst="$ISO/$name"
  if [[ -L "$dst" || ! -e "$dst" ]]; then
    ln -sfn "$src" "$dst"
  else
    echo "warning: $dst exists and is not a symlink; left untouched" >&2
  fi
done
echo "isolated root: $ISO"
