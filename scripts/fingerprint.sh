#!/usr/bin/env bash
# Print a Markdown table of size + SHA-256 for the game's binaries and archives.
# Only hashes are recorded; never paste file contents into the repo.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
require_game
cd "$GAME"
echo "| File | Size (bytes) | SHA-256 |"
echo "|---|---:|---|"
find . -maxdepth 2 -type f \( -iname '*.exe' -o -iname '*.dll' -o -iname '*.pac' \) | sort |
while read -r f; do
  f="${f#./}"
  size=$(stat -f %z "$f" 2>/dev/null || stat -c %s "$f")
  hash=$(shasum -a 256 "$f" | cut -d' ' -f1)
  echo "| \`$f\` | $size | \`$hash\` |"
done
