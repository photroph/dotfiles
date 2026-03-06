#!/usr/bin/env bash

set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

state_file="${1:-}"
if [ -z "$state_file" ] || [ ! -f "$state_file" ]; then
  exit 1
fi

# shellcheck disable=SC1090
source "$state_file"

log_file="${LOG_FILE:-${TMPDIR:-/tmp}/codex-alerter.log}"

log() {
  {
    printf '%s ' "$(date '+%Y-%m-%d %H:%M:%S')"
    printf '%s\n' "$*"
  } >>"$log_file" 2>/dev/null || true
}

cleanup() {
  rm -f "$state_file" 2>/dev/null || true
}
trap cleanup EXIT

classify_output() {
  RESULT_TEXT="${1:-}" python3 <<'PY'
import json
import os
import re

text = os.environ.get("RESULT_TEXT", "").strip()
if not text:
    print("unknown")
    raise SystemExit

upper = text.upper()
plain = {
    "@CONTENTCLICKED": "content_clicked",
    "@ACTIONCLICKED": "action_clicked",
    "@CLOSED": "closed",
    "@TIMEOUT": "timeout",
}
if upper in plain:
    print(plain[upper])
    raise SystemExit

if text.startswith("{") or text.startswith("["):
    try:
        payload = json.loads(text)
    except Exception:
        payload = None

    tokens = []

    def walk(value):
        if isinstance(value, dict):
            for key, item in value.items():
                tokens.append(str(key))
                walk(item)
        elif isinstance(value, list):
            for item in value:
                walk(item)
        elif value is not None:
            tokens.append(str(value))

    if payload is not None:
        walk(payload)
        joined = " ".join(tokens).upper()
        if "@CONTENTCLICKED" in joined or "CONTENTCLICKED" in joined or "CONTENTSCLICKED" in joined or "CONTENT_CLICKED" in joined:
            print("content_clicked")
            raise SystemExit
        if "@ACTIONCLICKED" in joined or "ACTIONCLICKED" in joined or "ACTION_CLICKED" in joined:
            print("action_clicked")
            raise SystemExit
        if "@TIMEOUT" in joined or re.search(r"\bTIMEOUT\b", joined):
            print("timeout")
            raise SystemExit
        if "@CLOSED" in joined or re.search(r"\bCLOSED\b", joined):
            print("closed")
            raise SystemExit

print("unknown")
PY
}

alerter_bin="${ALERTER_BIN:-$(command -v alerter || true)}"
if [ -z "$alerter_bin" ]; then
  log "show helper=missing-alerter state=$state_file"
  exit 0
fi

log "show start event=${EVENT_LABEL:-unknown} group=${GROUP_ID:-none}"

alerter_args=(
  --title "${TITLE:-Codex}"
  --message "${MESSAGE:-Codex turn complete.}"
  --group "${GROUP_ID:-codex}"
  --json
)

if [ -n "${SOUND_NAME:-}" ]; then
  alerter_args+=(--sound "${SOUND_NAME}")
fi

set +e
result="$("$alerter_bin" "${alerter_args[@]}" 2>>"$log_file")"
rc=$?
set -e

classification="$(classify_output "$result")"
compact_result="$(printf '%s' "$result" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')"
if [ "${#compact_result}" -gt 240 ]; then
  compact_result="${compact_result:0:237}..."
fi

log "show finish rc=$rc class=${classification:-unknown} sound=${SOUND_NAME:-off} result=${compact_result:-<empty>}"

if [ "$classification" = "content_clicked" ]; then
  if "$(
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
  )/focus-tmux-pane.sh" "$state_file"; then
    log "show focus=ok state=$state_file"
  else
    log "show focus=failed state=$state_file"
  fi
fi

exit 0
