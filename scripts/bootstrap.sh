#!/usr/bin/env bash
# One-time setup: submodule, git hooks, engine build, isolated game root.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
cd "$ROOT"

git submodule update --init --recursive
# Work on the iroha branch inside the submodule (create it from the pinned commit if absent).
if ! git -C "$ENGINE" rev-parse --verify --quiet iroha >/dev/null; then
  if git -C "$ENGINE" ls-remote --exit-code --heads origin iroha >/dev/null 2>&1; then
    git -C "$ENGINE" fetch origin iroha
    git -C "$ENGINE" checkout -b iroha --track origin/iroha
  else
    git -C "$ENGINE" checkout -b iroha
  fi
else
  git -C "$ENGINE" checkout iroha
fi

git config core.hooksPath scripts/hooks
build_engine
"$ROOT/scripts/isolated-root.sh"
echo "bootstrap done."
