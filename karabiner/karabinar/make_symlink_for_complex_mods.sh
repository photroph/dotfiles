#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$HOME/.config/karabiner/assets/complex_modifications"

mkdir -p "$TARGET_DIR"

find "$SCRIPT_DIR" -type f -name '*.json' -print0 |
  while IFS= read -r -d '' json_file; do
    link_path="$TARGET_DIR/$(basename "$json_file")"
    ln -sfn "$json_file" "$link_path"
    echo "linked: $link_path -> $json_file"
  done
