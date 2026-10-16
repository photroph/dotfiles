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

# src_root/*/ のうち marker(ファイル/ディレクトリ名)を持つものを、各 target ディレクトリへ
# シンボリックリンクする。走査方式なので追加時にこのスクリプトの編集は不要。
#   - 同名の実ディレクトリ/実ファイルは上書きしない(ln -sfn だと中にリンクが作られてしまう)
#   - src_root 配下を指していてリンク先が消えたリンクは掃除する
# usage: link_dirs <src_root> <marker> <target>...
link_dirs() {
  local src_root="$1" marker="$2"
  shift 2
  local target src_dir name dst link
  for target in "$@"; do
    mkdir -p "$target"
    for src_dir in "$src_root"/*/; do
      [[ -e "${src_dir}${marker}" ]] || continue
      name="$(basename "$src_dir")"
      dst="$target/$name"
      if [[ -e "$dst" && ! -L "$dst" ]]; then
        printf "${CYAN}skip (not a symlink): %s${RESET}\n" "${dst/$HOME/~}"
        continue
      fi
      ln -sfn "${src_dir%/}" "$dst"
      printf "${CYAN}%s -> %s${RESET}\n" "${dst/$HOME/~}" "${src_dir%/}"
    done
    for link in "$target"/*; do
      [[ -L "$link" && ! -e "$link" ]] || continue
      [[ "$(readlink "$link")" == "$src_root/"* ]] || continue
      rm "$link"
      printf "${GREEN}  removed: %s${RESET}\n" "${link/$HOME/~}"
    done
  done
}

# .claude/mods/ 配下の Claude mod は ~/.claude/skills/ に置くと自動ロードされる。
link_dirs "$DOTFILES/.claude/mods" ".claude-plugin" "$HOME/.claude/skills"

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

# ~/.agent/skills はリポジトリ管理外の共有スキル置き場(VPNプロファイル名など機微な内容を含むためgit管理しない)。
# 中身は各マシンで直接管理し、ここでは codex / claude の両方から見えるよう配線だけ行う。
printf "\n${BOLD}Wiring ~/.agent skills (repo-untracked)...${RESET}\n"
link_dirs "$HOME/.agent/skills" "SKILL.md" "$HOME/.codex/skills" "$HOME/.claude/skills"
