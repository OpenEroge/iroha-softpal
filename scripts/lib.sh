# Shared paths for iroha scripts. Source this file; do not execute it.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GAME="${IROHA_GAME:-$ROOT/iroha_game}"
ENGINE="$ROOT/sena-rs"
WORK="$ROOT/work"
ISO="$WORK/isolated-game"
BIN="$ENGINE/target/release"

build_engine() {
  cargo build --manifest-path "$ENGINE/Cargo.toml" --release \
    -p pal-vm -p pal-pac-unpacker -p pal-assets "$@"
}

require_game() {
  if [[ ! -d "$GAME" ]]; then
    echo "error: game directory not found: $GAME (set IROHA_GAME)" >&2
    exit 1
  fi
}
