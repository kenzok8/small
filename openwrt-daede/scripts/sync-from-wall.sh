#!/usr/bin/env bash
# Sync dae/ and daed/ Makefiles from the upstream wall repo.
# Wall is the single source of truth for core packages.
# Run from repo root: ./scripts/sync-from-wall.sh

set -euo pipefail

WALL_REPO="${WALL_REPO:-https://github.com/kenzok8/wall.git}"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

echo "==> Cloning $WALL_REPO (shallow)"
git clone --depth=1 --quiet "$WALL_REPO" "$TMPDIR/wall"

for pkg in dae daed; do
    src="$TMPDIR/wall/$pkg"
    dst="$REPO_ROOT/$pkg"
    if [ ! -d "$src" ]; then
        echo "!! $pkg not found in wall, skipping" >&2
        continue
    fi
    echo "==> Refreshing $pkg/"
    find "$dst" -mindepth 1 -delete 2>/dev/null || true
    rmdir "$dst" 2>/dev/null || true
    cp -r "$src" "$dst"
done

echo "==> Done. Review diff:"
git status -s dae daed
