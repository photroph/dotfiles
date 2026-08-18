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
  "ghostty/config:$HOME/Library/Application Support/com.mitchellh.ghostty/config"
  "leaf/config.toml:$HOME/.config/leaf/config.toml"
  "herdr.config.toml:$HOME/.config/herdr/config.toml"
  ".claude/keybindings.json:$HOME/.claude/keybindings.json"
  ".claude/settings.json:$HOME/.claude/settings.json"
  "codex/rules/git-remote-write.rules:$HOME/.codex/rules/git-remote-write.rules"
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

# リネーム・削除された管理対象JSONの壊れたリンクを除去する。
find "$KARABINER_DST" -type l -print0 |
  while IFS= read -r -d '' link_path; do
    link_target="$(readlink "$link_path")"
    if [[ "$link_target" == "$DOTFILES/"* && ! -e "$link_path" ]]; then
      rm "$link_path"
      printf "${GREEN}  removed: %s${RESET}\n" "$(basename "$link_path")"
    fi
  done

# アセットからコピー済みの有効ルールも最新内容へ同期する。
"$DOTFILES/scripts/sync_karabiner_complex_modifications.sh"
