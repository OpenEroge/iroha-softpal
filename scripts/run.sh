#!/usr/bin/env bash
# Run the game in a window from the isolated root. Extra args go to `sena`.
# Example: scripts/run.sh --trace-script
set -euo pipefail
source "$(dirname "$0")/lib.sh"
[[ -d "$ISO" ]] || "$ROOT/scripts/isolated-root.sh"
build_engine -q
exec "$BIN/sena" "$ISO" --nls sjis "$@"
