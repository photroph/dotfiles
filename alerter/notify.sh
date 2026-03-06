#!/usr/bin/env bash

set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log_file="${TMPDIR:-/tmp}/codex-alerter.log"

log() {
  {
    printf '%s ' "$(date '+%Y-%m-%d %H:%M:%S')"
    printf '%s\n' "$*"
  } >>"$log_file" 2>/dev/null || true
}

title="${1:-Codex}"
payload="${2:-}"

if [ -z "$payload" ] && [ -n "$title" ]; then
  payload="$title"
  title="Codex"
fi

if [ -z "$payload" ] || [ "$payload" = "__codex_notify__" ]; then
  payload='{"type":"agent-turn-complete","last-assistant-message":"Codex turn complete"}'
fi

metadata="$(
  PAYLOAD="$payload" python3 <<'PY'
import json
import os
import re
import shlex
import time

payload = os.environ.get("PAYLOAD", "")


def first_string(*values):
    for value in values:
        if isinstance(value, str) and value.strip():
            return value.strip()
    return ""


def to_text(value):
    if value is None:
        return ""
    if isinstance(value, str):
        return value
    if isinstance(value, (int, float, bool)):
        return str(value)
    if isinstance(value, list):
        return " ".join(part for part in (to_text(item).strip() for item in value) if part)
    if isinstance(value, dict):
        preferred = (
            "text",
            "output_text",
            "input_text",
            "message",
            "content",
            "question",
            "header",
            "title",
            "description",
            "reason",
        )
        for key in preferred:
            if key in value:
                text = to_text(value.get(key, "")).strip()
                if text:
                    return text
        return " ".join(part for part in (to_text(item).strip() for item in value.values()) if part)
    return str(value)


def normalize_message(value, limit=200):
    text = to_text(value)
    text = text.replace("\r", "\n")
    text = re.sub(r"\s+", " ", text).strip()
    if len(text) > limit:
        return text[: limit - 3].rstrip() + "..."
    return text


def generic_message(obj):
    candidates = (
        obj.get("last_agent_message"),
        obj.get("last-agent-message"),
        obj.get("lastAgentMessage"),
        obj.get("last_assistant_message"),
        obj.get("last-assistant-message"),
        obj.get("lastAssistantMessage"),
        obj.get("message"),
        obj.get("text"),
        obj.get("content"),
    )
    for candidate in candidates:
        text = normalize_message(candidate)
        if text:
            return text
    return ""


event_type = ""
thread_id = ""
turn_id = ""
call_id = ""
message = ""
event_label = "agent-turn-complete"

parsed = None
stripped = payload.strip()
if stripped.startswith("{") or stripped.startswith("["):
    try:
        parsed = json.loads(payload)
    except Exception:
        parsed = None

if isinstance(parsed, dict):
    event_type = first_string(
        parsed.get("type"),
        parsed.get("event_type"),
        parsed.get("event-type"),
    )
    thread_id = first_string(
        parsed.get("thread_id"),
        parsed.get("thread-id"),
        parsed.get("threadId"),
    )
    turn_id = first_string(
        parsed.get("turn_id"),
        parsed.get("turn-id"),
        parsed.get("turnId"),
    )
    call_id = first_string(
        parsed.get("call_id"),
        parsed.get("call-id"),
        parsed.get("callId"),
    )

    normalized_type = event_type.replace("-", "_")
    if normalized_type in ("agent_turn_complete", "task_complete", "turn_complete", ""):
        event_label = "agent-turn-complete"
        message = generic_message(parsed)
    elif normalized_type == "request_user_input":
        event_label = "request-user-input"
        questions = parsed.get("questions") or []
        for question in questions:
            text = normalize_message(question.get("question") if isinstance(question, dict) else question)
            if text:
                message = text
                break
        if not message:
            message = generic_message(parsed)
    elif normalized_type == "exec_approval_request":
        event_label = "exec-approval-request"
        message = normalize_message(parsed.get("reason"))
        if not message:
            command = parsed.get("command")
            if isinstance(command, list):
                message = normalize_message(" ".join(to_text(part) for part in command))
            elif isinstance(command, str):
                message = normalize_message(command)
        if not message:
            parsed_cmd = parsed.get("parsed_cmd") or parsed.get("parsed-cmd") or []
            if isinstance(parsed_cmd, list):
                pieces = []
                for item in parsed_cmd:
                    if isinstance(item, dict):
                        pieces.append(first_string(item.get("cmd"), item.get("path"), item.get("query"), item.get("name")))
                message = normalize_message(" ".join(piece for piece in pieces if piece))
    else:
        event_label = event_type or "agent-turn-complete"
        message = generic_message(parsed)
else:
    message = normalize_message(payload)

if not message:
    if event_label == "request-user-input":
        message = "Codex needs your input."
    elif event_label == "exec-approval-request":
        message = "Codex needs approval for a command."
    else:
        message = "Codex turn complete."

group_id = first_string(turn_id, call_id, thread_id)
if not group_id:
    group_id = f"codex-{event_label}-{int(time.time())}-{os.getpid()}"

for key, value in {
    "EVENT_TYPE": event_type,
    "EVENT_LABEL": event_label,
    "THREAD_ID": thread_id,
    "TURN_ID": turn_id,
    "CALL_ID": call_id,
    "GROUP_ID": group_id,
    "MESSAGE": message,
}.items():
    print(f"{key}={shlex.quote(value)}")
PY
)"
eval "$metadata"

tmux_socket=""
pane_id="${TMUX_PANE:-}"
session_id=""
window_id=""
client_tty=""

if command -v tmux >/dev/null 2>&1 && [ -n "${TMUX:-}" ]; then
  tmux_socket="${TMUX%%,*}"
  tmux_cmd=(tmux)
  if [ -n "$tmux_socket" ]; then
    tmux_cmd+=( -S "$tmux_socket" )
  fi

  if [ -z "$pane_id" ]; then
    pane_id="$("${tmux_cmd[@]}" display-message -p '#{pane_id}' 2>/dev/null || true)"
  fi

  if [ -n "$pane_id" ]; then
    session_id="$("${tmux_cmd[@]}" display-message -p -t "$pane_id" '#{session_id}' 2>/dev/null || true)"
    window_id="$("${tmux_cmd[@]}" display-message -p -t "$pane_id" '#{window_id}' 2>/dev/null || true)"
    if [ -z "$session_id" ] || [ -z "$window_id" ]; then
      pane_meta="$("${tmux_cmd[@]}" list-panes -a -F '#{pane_id} #{session_id} #{window_id}' 2>/dev/null | awk -v pane="$pane_id" '$1 == pane { print $2 " " $3; exit }' || true)"
      if [ -n "$pane_meta" ]; then
        if [ -z "$session_id" ]; then
          session_id="${pane_meta%% *}"
        fi
        if [ -z "$window_id" ]; then
          window_id="${pane_meta##* }"
        fi
      fi
    fi
  fi

  if [ -z "$session_id" ]; then
    session_id="$("${tmux_cmd[@]}" display-message -p '#{session_id}' 2>/dev/null || true)"
  fi
  if [ -z "$window_id" ]; then
    window_id="$("${tmux_cmd[@]}" display-message -p '#{window_id}' 2>/dev/null || true)"
  fi

  client_tty="$("${tmux_cmd[@]}" display-message -p '#{client_tty}' 2>/dev/null || true)"
  if [ -z "$client_tty" ] && [ -n "$session_id" ]; then
    client_tty="$("${tmux_cmd[@]}" list-clients -t "$session_id" -F '#{client_tty}' 2>/dev/null | head -n 1 || true)"
  fi
fi

state_file="$(mktemp "${TMPDIR:-/tmp}/codex-alerter.XXXXXX")"
chmod 600 "$state_file" 2>/dev/null || true
{
  printf 'TITLE=%q\n' "$title"
  printf 'MESSAGE=%q\n' "$MESSAGE"
  printf 'GROUP_ID=%q\n' "$GROUP_ID"
  printf 'EVENT_TYPE=%q\n' "$EVENT_TYPE"
  printf 'EVENT_LABEL=%q\n' "$EVENT_LABEL"
  printf 'THREAD_ID=%q\n' "$THREAD_ID"
  printf 'TURN_ID=%q\n' "$TURN_ID"
  printf 'CALL_ID=%q\n' "$CALL_ID"
  printf 'TMUX_SOCKET=%q\n' "$tmux_socket"
  printf 'TMUX_SESSION=%q\n' "$session_id"
  printf 'TMUX_WINDOW=%q\n' "$window_id"
  printf 'TMUX_PANE=%q\n' "$pane_id"
  printf 'CLIENT_TTY=%q\n' "$client_tty"
  printf 'TERMINAL_BUNDLE_ID=%q\n' 'com.mitchellh.ghostty'
  printf 'LOG_FILE=%q\n' "$log_file"
} >"$state_file"

log "notify start event=${EVENT_LABEL:-unknown} group=${GROUP_ID:-none} pane=${pane_id:-none} session=${session_id:-none} state=$state_file"

# Run the blocking notification flow in a detached helper so Codex can return immediately.
if nohup "$script_dir/show-and-wait.sh" "$state_file" >/dev/null 2>&1 & then
  log "notify helper=spawned pid=$! state=$state_file"
else
  log "notify helper=spawn-failed state=$state_file"
  rm -f "$state_file" 2>/dev/null || true
fi

exit 0
