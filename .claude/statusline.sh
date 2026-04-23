#!/bin/bash
input=$(cat)
CTX=$(echo "$input" | jq -r '.context_window.remaining_percentage // 0')
FIVE_USED=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // 0')
WEEK_USED=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // 0')
FIVE=$((100 - FIVE_USED))
WEEK=$((100 - WEEK_USED))

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

echo "Remaining — Ctx: $(color $CTX) | 5h: $(color $FIVE) | 7d: $(color $WEEK)"
