#!/bin/bash
input=$(cat)

# 欠損値は -1 / 空文字にして、区切り文字で空フィールドが潰れないようにする
IFS=$'\x1f' read -r MODEL EFFORT CTX_REM FIVE_USED FIVE_RESET WEEK_USED WEEK_RESET IN_TOK < <(
  echo "$input" | jq -r '[
    (.model.display_name // "?"),
    (.effort.level // "-"),
    (.context_window.remaining_percentage // 100),
    (.rate_limits.five_hour.used_percentage // -1),
    (.rate_limits.five_hour.resets_at // -1),
    (.rate_limits.seven_day.used_percentage // -1),
    (.rate_limits.seven_day.resets_at // -1),
    (.context_window.total_input_tokens // 0)
  ] | map(tostring) | join("\u001f")'
)

MODEL=$(echo "$MODEL" | sed -E 's/[[:space:]]*\([^)]*\)[[:space:]]*$//')
NOW=$(date +%s)

RESET='\033[0m'
DIM='\033[2m'
# モデル名バッジ: 白抜き (ダークスレート背景 + 白太字)。effort の色を引き立てるため無彩色寄り
BADGE='\033[1;38;2;255;255;255;48;2;58;66;82m'

# effort のバッジ背景色: 低 (落ち着いた色) → 高 (暖色・強い色)
effort_bg() {
  case "$1" in
    low)    echo '76;104;118' ;;
    medium) echo '150;120;50' ;;
    high)   echo '184;98;48' ;;
    xhigh)  echo '176;62;62' ;;
    max)    echo '150;40;90' ;;
    *)      echo '100;100;100' ;;
  esac
}

# 残量(%)から色を決める
pick_color() {
  if [ "$1" -le 10 ]; then echo '\033[31m'
  elif [ "$1" -le 50 ]; then echo '\033[33m'
  else echo '\033[38;2;60;179;113m'
  fi
}

TRACK='\033[38;2;70;70;70m'

BAR_W=6
# Nerd Font: microchip (U+F2DB)
ICON_CHIP=$'\xef\x8b\x9b'

# 残量(%) と色 → 太めの線のバー(BAR_W マス)。pct が na なら空のトラックだけ描く
bar() {
  local pct=$1 color=$2 filled=0 i out
  if [ "$pct" != "na" ]; then
    filled=$(( (pct * BAR_W + 50) / 100 ))
    [ "$pct" -gt 0 ] && [ "$filled" -lt 1 ] && filled=1
    [ "$filled" -gt "$BAR_W" ] && filled=$BAR_W
  fi
  out="${color}"
  for ((i = 0; i < filled; i++)); do out+="▬"; done
  out+="${TRACK}"
  for ((i = filled; i < BAR_W; i++)); do out+="▬"; done
  out+="${RESET}"
  echo "$out"
}

# リセット時刻(epoch秒) → "1h20m" などの残り時間
fmt_reset() {
  local left=$(( $1 - NOW ))
  [ "$1" -lt 0 ] && return
  if [ "$left" -le 0 ]; then echo "now"
  elif [ "$left" -lt 3600 ]; then echo "$(( left / 60 ))m"
  elif [ "$left" -lt 86400 ]; then echo "$(( left / 3600 ))h$(( (left % 3600) / 60 ))m"
  else echo "$(( left / 86400 ))d$(( (left % 86400) / 3600 ))h"
  fi
}

fmt_tokens() {
  if [ "$1" -ge 1000 ]; then awk -v n="$1" 'BEGIN{printf "%.1fk", n/1000}'
  else echo "$1"
  fi
}

# ラベル + バー + 残量% (+ リセットまでの時間 / 補足)。used が -1 なら n/a
gauge() {
  local label=$1 remaining=$2 reset=$3 extra=$4 color rst
  if [ "$remaining" = "na" ]; then
    echo -e "${label} $(bar na "$TRACK") ${DIM}n/a${RESET}"
    return
  fi
  color=$(pick_color "$remaining")
  rst=$(fmt_reset "$reset")
  local out="${label} $(bar "$remaining" "$color") ${color}${remaining}%${RESET}"
  [ -n "$rst" ] && out+=" ${DIM}(↻${rst})${RESET}"
  [ -n "$extra" ] && out+=" ${DIM}(${extra})${RESET}"
  echo -e "$out"
}

remaining_of_used() {
  if awk -v u="$1" 'BEGIN{exit !(u < 0)}'; then echo "na"
  else awk -v u="$1" 'BEGIN{printf "%.0f", 100-u}'
  fi
}

CTX=$(awk -v v="$CTX_REM" 'BEGIN{printf "%.0f", v}')
FIVE=$(remaining_of_used "$FIVE_USED")
WEEK=$(remaining_of_used "$WEEK_USED")
FIVE_RESET=${FIVE_RESET%.*}
WEEK_RESET=${WEEK_RESET%.*}

MODEL_LABEL="${BADGE} ${MODEL} ${RESET}"
[ "$EFFORT" != "-" ] && MODEL_LABEL+="\033[1;38;2;255;255;255;48;2;$(effort_bg "$EFFORT")m ${EFFORT} ${RESET}"

SEP=" ${DIM}│${RESET} "

# 1 行目: モデル / コンテキスト (括弧内は現在の入力トークン量)
echo -e "${MODEL_LABEL} $(gauge Ctx "$CTX" -1 "${ICON_CHIP} $(fmt_tokens "${IN_TOK%.*}")")"
# 2 行目: 5時間 / 7日
echo -e "$(gauge 5h "$FIVE" "$FIVE_RESET")${SEP}$(gauge 7d "$WEEK" "$WEEK_RESET")"
