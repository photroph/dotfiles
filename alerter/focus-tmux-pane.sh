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

activate_terminal() {
  if [ "${CODEX_NOTIFY_SKIP_ACTIVATE:-0}" = "1" ]; then
    log "focus activate=skipped"
    return 0
  fi

  local bundle_id="${TERMINAL_BUNDLE_ID:-com.mitchellh.ghostty}"
  if command -v open >/dev/null 2>&1; then
    if open -b "$bundle_id" >/dev/null 2>&1; then
      log "focus activate=open-bundle bundle=$bundle_id"
      return 0
    fi
    if open -a Ghostty >/dev/null 2>&1; then
      log "focus activate=open-app app=Ghostty"
      return 0
    fi
  fi

  if command -v osascript >/dev/null 2>&1; then
    if osascript -e 'tell application id "com.mitchellh.ghostty" to activate' >/dev/null 2>&1; then
      log "focus activate=osascript bundle=com.mitchellh.ghostty"
      return 0
    fi
  fi

  log "focus activate=failed"
  return 0
}

activate_terminal

if ! command -v tmux >/dev/null 2>&1; then
  log "focus tmux=missing"
  exit 0
fi

if [ -z "${TMUX_SESSION:-}" ] || [ -z "${TMUX_PANE:-}" ]; then
  log "focus tmux=not-applicable session=${TMUX_SESSION:-none} pane=${TMUX_PANE:-none}"
  exit 0
fi

tmux_cmd=(tmux)
if [ -n "${TMUX_SOCKET:-}" ]; then
  tmux_cmd+=( -S "$TMUX_SOCKET" )
fi

if ! "${tmux_cmd[@]}" has-session -t "$TMUX_SESSION" >/dev/null 2>&1; then
  log "focus tmux=session-missing session=$TMUX_SESSION"
  exit 0
fi

target_client="${CLIENT_TTY:-}"
if [ -z "$target_client" ]; then
  target_client="$("${tmux_cmd[@]}" list-clients -t "$TMUX_SESSION" -F '#{client_tty}' 2>/dev/null | head -n 1 || true)"
fi

if [ -z "$target_client" ]; then
  log "focus tmux=client-missing session=$TMUX_SESSION"
  exit 0
fi

if "${tmux_cmd[@]}" switch-client -c "$target_client" -t "$TMUX_SESSION" >/dev/null 2>&1; then
  log "focus switch-client=ok client=$target_client session=$TMUX_SESSION"
else
  log "focus switch-client=failed client=$target_client session=$TMUX_SESSION"
fi

if [ -n "${TMUX_WINDOW:-}" ]; then
  if "${tmux_cmd[@]}" select-window -t "$TMUX_WINDOW" >/dev/null 2>&1; then
    log "focus select-window=ok window=$TMUX_WINDOW"
  else
    log "focus select-window=failed window=$TMUX_WINDOW"
  fi
fi

if "${tmux_cmd[@]}" select-pane -t "$TMUX_PANE" >/dev/null 2>&1; then
  log "focus select-pane=ok pane=$TMUX_PANE"
else
  log "focus select-pane=failed pane=$TMUX_PANE"
fi

exit 0
