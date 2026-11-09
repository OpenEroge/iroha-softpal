#!/usr/bin/env bash
# Unpack (or list) a .pac from the game into work/unpacked/<name>/.
# Usage: scripts/unpack.sh <name-without-.pac> [--list-only] [--nls sjis|gbk]
set -euo pipefail
source "$(dirname "$0")/lib.sh"
require_game
name="${1:?usage: unpack.sh <pac-name> [extra args]}"; shift
build_engine -q
out="$WORK/unpacked/$name"
mkdir -p "$out"
"$BIN/pal-pac-unpacker" --input "$GAME/$name.pac" --output "$out" --overwrite "$@"
