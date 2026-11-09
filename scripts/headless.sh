#!/usr/bin/env bash
# Headless diagnostic run. Output (log + final PNG) goes to work/diag/<timestamp>/.
# Usage: scripts/headless.sh [frames] [extra sena args...]
# Example: scripts/headless.sh 600 --diagnostic-png-at 300:work/diag/t300.png
# HEADLESS_AUDIO=1 plays through the audio device and paces frames to real time
# (--diagnostic-realtime); without it audio is disabled and frames run unpaced.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
[[ -d "$ISO" ]] || "$ROOT/scripts/isolated-root.sh"
build_engine -q

frames="${1:-600}"; shift || true
out="$WORK/diag/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$out"
set +e
audio_args=(--no-audio)
[[ "${HEADLESS_AUDIO:-0}" == 1 ]] && audio_args=(--diagnostic-realtime)
RUST_LOG="${RUST_LOG:-info}" "$BIN/sena" "$ISO" --nls sjis --headless "${audio_args[@]}" \
  --diagnostic-frames "$frames" --fixed-timestep-ms 16 --diagnostic-frame-ms 0 \
  --diagnostic-png "$out/final.png" "$@" >"$out/log.txt" 2>&1
code=$?
set -e
echo "exit=$code  log=$out/log.txt  png=$out/final.png"
tail -n 15 "$out/log.txt"
exit "$code"
