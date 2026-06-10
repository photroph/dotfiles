#!/usr/bin/env bash
set -euo pipefail

BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RESET='\033[0m'

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"

printf "${BOLD}Symlinking dotfiles...${RESET}\n\n"

# 1対1のシンボリックリンク定義。追加は links=() に1行足すだけ。
links=(
  "git/gwq_config.toml:$HOME/.config/gwq/config.toml"
  ".claude/keybindings.json:$HOME/.claude/keybindings.json"
)

for entry in "${links[@]}"; do
  src="$DOTFILES/${entry%%:*}"
  dst="${entry##*:}"
  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
  printf "${CYAN}%s${RESET}\n" "${dst/$HOME/~}"
done

# karabiner は complex_modifications/ 配下の全JSONをリンクする必要があるため、
# find でディレクトリを走査して個別にリンクを張る
KARABINER_SRC="$DOTFILES/karabiner"
KARABINER_DST="$HOME/.config/karabiner/assets/complex_modifications"
mkdir -p "$KARABINER_DST"
printf "\n${CYAN}%s/${RESET}\n" "${KARABINER_DST/$HOME/~}"
find "$KARABINER_SRC" -type f -name '*.json' -print0 |
  while IFS= read -r -d '' json_file; do
    link_path="$KARABINER_DST/$(basename "$json_file")"
    ln -sfn "$json_file" "$link_path"
    printf "${GREEN}  %s${RESET}\n" "$(basename "$json_file")"
  done
