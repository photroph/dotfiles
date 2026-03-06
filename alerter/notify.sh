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

is_placeholder_token() {
  case "${1:-}" in
    __codex_notify__|__codex__notify__)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

title="${1:-Codex}"
payload="${2:-}"
payload_source="arg2"
argc=$#
arg1_is_placeholder=0
arg2_is_placeholder=0
stdin_present=0

if is_placeholder_token "$title"; then
  arg1_is_placeholder=1
  title="Codex"
fi

if is_placeholder_token "$payload"; then
  arg2_is_placeholder=1
fi

if [ -z "$payload" ] && [ $# -eq 1 ]; then
  case "$title" in
    \{*|\[*)
      payload="$title"
      title="Codex"
      payload_source="arg1"
      ;;
    __codex_notify__|__codex__notify__)
      payload=""
      title="Codex"
      payload_source="placeholder-arg1"
      ;;
    *)
      payload=""
      payload_source="title-only"
      ;;
  esac
elif [ "$arg2_is_placeholder" -eq 1 ]; then
  payload=""
  payload_source="placeholder-arg2"
fi

if [ ! -t 0 ]; then
  stdin_present=1
fi

if [ -z "$payload" ] && [ "$stdin_present" -eq 1 ]; then
  payload="$(cat)"
  if [ -n "$payload" ]; then
    payload_source="stdin"
  fi
fi

metadata="$(
  PAYLOAD="$payload" CODEX_HOME="${CODEX_HOME:-$HOME/.codex}" python3 <<'PY'
import datetime
import json
import os
import pathlib
import re
import shlex
import time

payload = os.environ.get("PAYLOAD", "")
codex_home = os.environ.get("CODEX_HOME", os.path.expanduser("~/.codex"))
env_thread_id = os.environ.get("CODEX_THREAD_ID", "").strip()


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


def parse_timestamp(value):
    if not isinstance(value, str) or not value.strip():
        return None
    text = value.strip()
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    try:
        return datetime.datetime.fromisoformat(text).timestamp()
    except Exception:
        return None


def root_object(obj):
    if isinstance(obj, dict) and isinstance(obj.get("event"), dict):
        return obj["event"]
    return obj


def walk_objects(value):
    if isinstance(value, dict):
        yield value
        for item in value.values():
            yield from walk_objects(item)
    elif isinstance(value, list):
        for item in value:
            yield from walk_objects(item)


def recursive_assistant_message(obj):
    root = root_object(obj)
    keys = (
        "last-assistant-message",
        "last_assistant_message",
        "lastAssistantMessage",
        "last-agent-message",
        "last_agent_message",
        "lastAgentMessage",
    )
    for candidate in walk_objects(root):
        for key in keys:
            text = normalize_message(candidate.get(key))
            if text:
                return text
    return ""


def prompt_message(obj):
    root = root_object(obj)
    input_messages = (
        root.get("input-messages")
        or root.get("input_messages")
        or root.get("inputMessages")
        or root.get("input")
        or []
    )
    if isinstance(input_messages, list):
        user_messages = [
            item for item in input_messages if isinstance(item, dict) and item.get("role") == "user"
        ]
        last_item = (user_messages or input_messages)[-1] if (user_messages or input_messages) else None
        text = normalize_message(last_item)
        if text:
            return text

    return normalize_message(
        first_string(
            root.get("prompt"),
            root.get("user_prompt"),
            root.get("last-user-message"),
        )
    )


def extract_rollout_message(thread_id, turn_id, *, attempts=1, delay_seconds=0.0, require_recent=False, max_age_seconds=10.0):
    sessions_dir = pathlib.Path(codex_home).expanduser() / "sessions"
    if not thread_id or not sessions_dir.is_dir():
        return "", "miss"

    latest = None
    stale_message = ""
    stale_hit = False

    for attempt in range(max(1, attempts)):
        rollout_files = sorted(sessions_dir.rglob(f"rollout-*{thread_id}.jsonl"))
        if rollout_files:
            latest = rollout_files[-1]

        last_any = ""
        last_any_ts = None
        last_matching_turn = ""
        last_matching_turn_ts = None

        if latest is not None:
            try:
                for line in latest.read_text(encoding="utf-8").splitlines():
                    if not line.strip():
                        continue
                    try:
                        item = json.loads(line)
                    except Exception:
                        continue
                    if item.get("type") != "event_msg":
                        continue
                    event_payload = item.get("payload") or {}
                    if not isinstance(event_payload, dict):
                        continue
                    if event_payload.get("type") != "task_complete":
                        continue

                    message = normalize_message(
                        first_string(
                            event_payload.get("last_agent_message"),
                            event_payload.get("last-agent-message"),
                            event_payload.get("last_assistant_message"),
                            event_payload.get("last-assistant-message"),
                        )
                    )
                    if not message:
                        continue

                    event_ts = parse_timestamp(item.get("timestamp"))
                    last_any = message
                    last_any_ts = event_ts
                    event_turn_id = first_string(
                        event_payload.get("turn_id"),
                        event_payload.get("turn-id"),
                        event_payload.get("turnId"),
                    )
                    if turn_id and event_turn_id == turn_id:
                        last_matching_turn = message
                        last_matching_turn_ts = event_ts
            except Exception:
                latest = None

        candidate_message = last_matching_turn or last_any
        candidate_ts = last_matching_turn_ts if last_matching_turn else last_any_ts

        if candidate_message:
            if not require_recent:
                return candidate_message, "hit"
            cutoff = time.time() - max_age_seconds
            if candidate_ts is not None and candidate_ts >= cutoff:
                return candidate_message, "hit"
            stale_message = candidate_message
            stale_hit = True

        if attempt + 1 < max(1, attempts):
            time.sleep(delay_seconds)

    if stale_hit:
        return "", "stale"
    return "", "miss"


event_type = ""
thread_id = ""
turn_id = ""
call_id = ""
message = ""
event_label = "agent-turn-complete"
message_source = "default"
thread_source = "none"
rollout_lookup = "not_attempted"
env_thread_id_present = "1" if env_thread_id else "0"

parsed = None
stripped = payload.strip()
payload_present = bool(stripped)
if stripped.startswith("{") or stripped.startswith("["):
    try:
        parsed = json.loads(payload)
    except Exception:
        parsed = None

if isinstance(parsed, dict):
    root = root_object(parsed)

    event_type = first_string(
        root.get("type") if isinstance(root, dict) else "",
        parsed.get("type"),
        parsed.get("event_type"),
        parsed.get("event-type"),
    )
    thread_id = first_string(
        root.get("thread_id") if isinstance(root, dict) else "",
        root.get("thread-id") if isinstance(root, dict) else "",
        root.get("threadId") if isinstance(root, dict) else "",
        parsed.get("thread_id"),
        parsed.get("thread-id"),
        parsed.get("threadId"),
    )
    if thread_id:
        thread_source = "payload"
    turn_id = first_string(
        root.get("turn_id") if isinstance(root, dict) else "",
        root.get("turn-id") if isinstance(root, dict) else "",
        root.get("turnId") if isinstance(root, dict) else "",
        parsed.get("turn_id"),
        parsed.get("turn-id"),
        parsed.get("turnId"),
    )
    call_id = first_string(
        root.get("call_id") if isinstance(root, dict) else "",
        root.get("call-id") if isinstance(root, dict) else "",
        root.get("callId") if isinstance(root, dict) else "",
        parsed.get("call_id"),
        parsed.get("call-id"),
        parsed.get("callId"),
    )

    normalized_type = event_type.replace("-", "_")
    if normalized_type in ("agent_turn_complete", "task_complete", "turn_complete", ""):
        event_label = "agent-turn-complete"
        message = recursive_assistant_message(parsed)
        if message:
            message_source = "payload"
    elif normalized_type == "request_user_input":
        event_label = "request-user-input"
        questions = []
        if isinstance(root, dict):
            questions = root.get("questions") or []
        if not questions:
            questions = parsed.get("questions") or []
        for question in questions:
            text = normalize_message(question.get("question") if isinstance(question, dict) else question)
            if text:
                message = text
                message_source = "payload"
                break
        if not message:
            message = recursive_assistant_message(parsed)
            if message:
                message_source = "payload"
    elif normalized_type == "exec_approval_request":
        event_label = "exec-approval-request"
        message = normalize_message(root.get("reason") if isinstance(root, dict) else "")
        if message:
            message_source = "payload"
        if not message:
            command = root.get("command") if isinstance(root, dict) else None
            if command is None and isinstance(parsed, dict):
                command = parsed.get("command")
            if isinstance(command, list):
                message = normalize_message(" ".join(to_text(part) for part in command))
                if message:
                    message_source = "payload"
            elif isinstance(command, str):
                message = normalize_message(command)
                if message:
                    message_source = "payload"
        if not message:
            parsed_cmd = []
            if isinstance(root, dict):
                parsed_cmd = root.get("parsed_cmd") or root.get("parsed-cmd") or []
            if not parsed_cmd:
                parsed_cmd = parsed.get("parsed_cmd") or parsed.get("parsed-cmd") or []
            if isinstance(parsed_cmd, list):
                pieces = []
                for item in parsed_cmd:
                    if isinstance(item, dict):
                        pieces.append(first_string(item.get("cmd"), item.get("path"), item.get("query"), item.get("name")))
                message = normalize_message(" ".join(piece for piece in pieces if piece))
                if message:
                    message_source = "payload"
    else:
        event_label = event_type or "agent-turn-complete"
        message = recursive_assistant_message(parsed)
        if message:
            message_source = "payload"

    if not message:
        message = prompt_message(parsed)
        if message:
            message_source = "payload"

    if not thread_id and env_thread_id:
        thread_id = env_thread_id
        thread_source = "env"

    if not message and event_label == "agent-turn-complete":
        rollout_lookup = "attempted"
        message, rollout_lookup = extract_rollout_message(
            thread_id,
            turn_id,
            attempts=5 if thread_source == "env" else 1,
            delay_seconds=0.2,
            require_recent=(thread_source == "env" and not payload_present and not turn_id),
        )
        if message:
            message_source = "rollout"
else:
    if env_thread_id:
        thread_id = env_thread_id
        thread_source = "env"
    message = normalize_message(payload)
    if message:
        message_source = "payload"

    if not message and event_label == "agent-turn-complete":
        rollout_lookup = "attempted"
        message, rollout_lookup = extract_rollout_message(
            thread_id,
            turn_id,
            attempts=5 if thread_source == "env" else 1,
            delay_seconds=0.2,
            require_recent=(thread_source == "env" and not payload_present and not turn_id),
        )
        if message:
            message_source = "rollout"

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
    "MESSAGE_SOURCE": message_source,
    "THREAD_SOURCE": thread_source,
    "ROLLOUT_LOOKUP": rollout_lookup,
    "ENV_THREAD_ID_PRESENT": env_thread_id_present,
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
  printf 'MESSAGE_SOURCE=%q\n' "$MESSAGE_SOURCE"
  printf 'THREAD_SOURCE=%q\n' "$THREAD_SOURCE"
  printf 'ROLLOUT_LOOKUP=%q\n' "$ROLLOUT_LOOKUP"
  printf 'ENV_THREAD_ID_PRESENT=%q\n' "$ENV_THREAD_ID_PRESENT"
  printf 'TMUX_SOCKET=%q\n' "$tmux_socket"
  printf 'TMUX_SESSION=%q\n' "$session_id"
  printf 'TMUX_WINDOW=%q\n' "$window_id"
  printf 'TMUX_PANE=%q\n' "$pane_id"
  printf 'CLIENT_TTY=%q\n' "$client_tty"
  printf 'TERMINAL_BUNDLE_ID=%q\n' 'com.mitchellh.ghostty'
  printf 'LOG_FILE=%q\n' "$log_file"
} >"$state_file"

log "notify start argc=${argc} arg1_is_placeholder=${arg1_is_placeholder} arg2_is_placeholder=${arg2_is_placeholder} stdin_present=${stdin_present} env_thread_id_present=${ENV_THREAD_ID_PRESENT:-0} source=${payload_source:-unknown} payload_len=${#payload} event=${EVENT_LABEL:-unknown} message_source=${MESSAGE_SOURCE:-unknown} thread_source=${THREAD_SOURCE:-none} rollout_lookup=${ROLLOUT_LOOKUP:-not_attempted} group=${GROUP_ID:-none} pane=${pane_id:-none} session=${session_id:-none} state=$state_file"

# Run the blocking notification flow in a detached helper so Codex can return immediately.
if nohup "$script_dir/show-and-wait.sh" "$state_file" >/dev/null 2>&1 & then
  log "notify helper=spawned pid=$! state=$state_file"
else
  log "notify helper=spawn-failed state=$state_file"
  rm -f "$state_file" 2>/dev/null || true
fi

exit 0
