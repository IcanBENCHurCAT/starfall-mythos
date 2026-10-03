#!/usr/bin/env bash
# fetch_assets.sh — fetch the CC0 Superpowers medieval-fantasy asset pack
# into clients/godot/assets/third-party/superpowers-medieval-fantasy/
#
# The pack (~15MB, ~360 files: characters, monsters, animals,
# background-elements, items, fx, hud, sounds, music) is documented in
# ASSET_SOURCES.md but deliberately NOT committed to git. Run this after
# cloning to reproduce the bundled layout.
#
# Godot's editor regenerates the .import files for these textures on first
# open (the .import files were editor-generated locally, not upstream), so a
# plain sparse clone is sufficient.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HERE/superpowers-medieval-fantasy"
REPO="https://github.com/sparklinlabs/superpowers-asset-packs"
LICENSE_URL="https://raw.githubusercontent.com/sparklinlabs/superpowers-asset-packs/master/LICENSE.txt"

if [ -d "$DEST" ]; then
  echo "already present: $DEST"
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "sparse-cloning $REPO (depth 1, blob filter, medieval-fantasy only)..."
git clone --depth 1 --filter=blob:none --sparse "$REPO" "$TMP/pack"
git -C "$TMP/pack" sparse-checkout set medieval-fantasy
git -C "$TMP/pack" checkout

mkdir -p "$DEST"
# Flatten: upstream packs live under <repo>/medieval-fantasy/; local layout
# expects the category dirs directly under superpowers-medieval-fantasy/.
mv "$TMP/pack/medieval-fantasy"/* "$DEST/"
# Upstream keeps one shared CC0 license at the repo root; keep a copy with
# the pack so the manifest rule (ASSET_SOURCES.md) stays satisfied offline.
curl -fsSL "$LICENSE_URL" -o "$DEST/LICENSE.txt"

echo "fetched -> $DEST/"
du -sh "$DEST"
