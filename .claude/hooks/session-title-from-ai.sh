#!/bin/bash
# UserPromptSubmit フック: Claude が自動生成したセッションタイトル (ai-title) を、
# /rename 相当の sessionTitle として返し、入力欄の枠に表示させる。
#
# - ai-title は最初のターン中に transcript へ書かれるので、反映は早くて 2 回目のプロンプトから
# - /rename・--name・このフック自身が付けた名前 (custom-title) があれば何もしない
#   (ユーザーが付けた名前を上書きしない / 毎回 rename しない)
# - 何も出力せず exit 0 した場合は、フックなしと同じ動作になる

input=$(cat)
transcript=$(jq -r '.transcript_path // empty' <<<"$input")
[ -n "$transcript" ] && [ -r "$transcript" ] || exit 0

grep -q '"type":"custom-title"' "$transcript" && exit 0

title=$(grep '"type":"ai-title"' "$transcript" | tail -n 1 | jq -r '.aiTitle // empty')
[ -n "$title" ] || exit 0

jq -n --arg t "$title" \
  '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", sessionTitle: $t}}'
