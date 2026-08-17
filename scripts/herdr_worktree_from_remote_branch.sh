#!/usr/bin/env bash
set -euo pipefail

# リモートブランチを選んで、herdr の worktree ワークスペースとして開く。
# herdr.config.toml の [[keys.command]] type="popup" から起動される想定。

BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

HERDR="${HERDR_BIN_PATH:-herdr}"
REMOTE="${HERDR_WT_REMOTE:-origin}"

# popup はコマンドの終了と同時に閉じるため、失敗時は入力待ちで止めないと
# エラーメッセージが読めない。
die() {
  printf "${RED}%s${RESET}\n" "$*" >&2
  printf '\n何かキーを押すと閉じます...'
  read -r -n 1 -s _ || true
  printf '\n'
  exit 1
}

for cmd in git fzf "$HERDR"; do
  command -v "$cmd" >/dev/null 2>&1 || die "$cmd が見つかりません。"
done

# type="popup" のコマンドには cwd が引き継がれないため、herdr が注入する
# HERDR_ACTIVE_PANE_CWD を対象リポジトリの起点にする。
start_dir="${HERDR_ACTIVE_PANE_CWD:-$PWD}"
cd "$start_dir" 2>/dev/null || die "ディレクトリに移動できません: $start_dir"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
  die "Gitリポジトリではありません: $start_dir"

# 既存のworktreeの中から起動されても、ブランチ一覧と worktree の追加先は
# 本体リポジトリのものを使う。
common_dir="$(git rev-parse --path-format=absolute --git-common-dir)"
main_repo="$(git -C "$common_dir/.." rev-parse --path-format=absolute --show-toplevel 2>/dev/null)" ||
  die "本体リポジトリを特定できませんでした: $common_dir"
cd "$main_repo"

printf "${BOLD}%s${RESET} から fetch しています...\n" "$REMOTE"
git fetch --prune --quiet "$REMOTE" || die "$REMOTE の fetch に失敗しました。"

# lstrip=3 は refs/remotes/<remote>/ の3階層だけを剥がすので、
# feature/foo のようなスラッシュ入りブランチ名はそのまま残る。
# fzf の {} は single-quote 済みの文字列に展開されるため、$REMOTE/{} で連結できる。
branch="$(
  git for-each-ref --sort=-committerdate \
    --format='%(refname:lstrip=3)' "refs/remotes/$REMOTE" |
    { grep -v '^HEAD$' || true; } |
    fzf --prompt="$REMOTE/ > " \
      --height=100% --reverse --no-multi \
      --preview="git log --oneline --color=always -20 $REMOTE/{}" \
      --preview-window='right,60%'
)" || exit 0
[[ -n "$branch" ]] || exit 0

# 既に worktree があるブランチは作り直さずに開く。
# git worktree add の "already checked out" エラーもここで避けられる。
existing_path="$(
  git worktree list --porcelain |
    awk -v target="branch refs/heads/$branch" '
      /^worktree / { path = substr($0, 10) }
      $0 == target { print path; exit }
    '
)"
if [[ -n "$existing_path" ]]; then
  printf "${CYAN}既存の worktree を開きます:${RESET} %s\n" "$existing_path"
  exec "$HERDR" worktree open --cwd "$main_repo" --path "$existing_path" --label "$branch"
fi

# ローカル追跡ブランチを用意する。これが無いと herdr が HEAD から
# 新規ブランチを切ってしまうので必須。
if git show-ref --verify --quiet "refs/heads/$branch"; then
  if git merge-base --is-ancestor "$branch" "$REMOTE/$branch"; then
    git branch --force "$branch" "$REMOTE/$branch" ||
      die "ローカルブランチの早送りに失敗しました: $branch"
    printf "${GREEN}ローカルブランチを %s/%s へ早送りしました。${RESET}\n" "$REMOTE" "$branch"
  else
    # ローカルコミットを失わないよう、分岐しているときは早送りしない。
    printf "${YELLOW}警告: ローカルの %s は %s/%s から分岐しています。そのまま使います。${RESET}\n" \
      "$branch" "$REMOTE" "$branch"
  fi
else
  git branch --track "$branch" "$REMOTE/$branch" ||
    die "ローカルブランチの作成に失敗しました: $branch"
  printf "${GREEN}ローカルブランチを作成しました: %s${RESET}\n" "$branch"
fi

# --label にブランチ名をそのまま渡すことで、サイドバーの表示を
# リモートブランチ名と完全一致させる（チェックアウト先のディレクトリ名は
# herdr 既定のスラッグ化されたものになる）。
"$HERDR" worktree create \
  --cwd "$main_repo" \
  --branch "$branch" \
  --label "$branch" \
  --focus ||
  die "worktree の作成に失敗しました: $branch"
