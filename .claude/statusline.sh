#!/bin/bash
input=$(cat)
CTX=$(echo "$input" | jq -r '.context_window.remaining_percentage // 0')
FIVE_USED=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // 0')
WEEK_USED=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // 0')
CTX=$(awk -v v="$CTX" 'BEGIN{printf "%.0f", v}')
FIVE=$(awk -v u="$FIVE_USED" 'BEGIN{printf "%.0f", 100-u}')
WEEK=$(awk -v u="$WEEK_USED" 'BEGIN{printf "%.0f", 100-u}')

MODEL=$(echo "$input" | jq -r '.model.display_name // "?"' | sed -E 's/[[:space:]]*\([^)]*\)[[:space:]]*$//')
EFFORT=$(echo "$input" | jq -r '.effort.level // empty')
IN_TOK=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
OUT_TOK=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')

color() {
  local val=$1
  if [ "$val" -le 10 ]; then
    echo -e "\033[31m${val}%\033[0m"
  elif [ "$val" -le 50 ]; then
    echo -e "\033[33m${val}%\033[0m"
  else
    echo -e "\033[32m${val}%\033[0m"
  fi
}

fmt_tokens() {
  local n=$1
  if [ "$n" -ge 1000 ]; then
    awk -v n="$n" 'BEGIN{printf "%.1fk", n/1000}'
  else
    echo "$n"
  fi
}

MODEL_LABEL="$MODEL"
if [ -n "$EFFORT" ]; then
  MODEL_LABEL="${MODEL} (${EFFORT})"
fi

echo -e "\033[36m${MODEL_LABEL}\033[0m|Tok: $(fmt_tokens $IN_TOK)in/$(fmt_tokens $OUT_TOK)out|Remaining — Ctx:$(color $CTX)|5h:$(color $FIVE)|7d:$(color $WEEK)"
