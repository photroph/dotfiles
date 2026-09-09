#!/bin/bash

# Open Neovide in the background without blocking the terminal
nvide() { neovide --fork "$@" }

_herdr_agent_with_icon() {
    local agent_command="$1"
    local agent_icon="$2"
    local pane_id="${HERDR_PANE_ID:-}"
    shift 2

    if [[ -n "$pane_id" ]] && command -v herdr >/dev/null 2>&1; then
        herdr pane report-metadata "$pane_id" \
            --source dotfiles:agent-icon \
            --display-agent "$agent_icon" >/dev/null 2>&1
    fi

    command "$agent_command" "$@"
    local exit_status=$?

    if [[ -n "$pane_id" ]] && command -v herdr >/dev/null 2>&1; then
        herdr pane report-metadata "$pane_id" \
            --source dotfiles:agent-icon \
            --clear-display-agent >/dev/null 2>&1
    fi

    return "$exit_status"
}

codex() { _herdr_agent_with_icon codex $'\uec81' "$@" }
claude() { _herdr_agent_with_icon claude $'\uec82' "$@" }

search_command() {
    COMMANDS_FILE="${HOME}/dotfiles/commands.sh"

    # Check that the commands file exists
    if [[ ! -f "${COMMANDS_FILE}" ]]; then
      echo "Error: Commands file not found at ${COMMANDS_FILE}" >&2
      exit 1
    fi

    # Use fzf to select a command
    selected_command=$(fzf --height 40% --border --prompt="Select command> " < "${COMMANDS_FILE}")

    # If no selection, exit silently
    if [[ -z "$selected_command" ]]; then
      exit 0
    fi

    # Strip comments (remove everything after #)
    selected_command="${selected_command%%#*}"
    # Trim trailing whitespace
    selected_command="${selected_command%${selected_command##*[![:space:]]}}"

    BUFFER="$selected_command"
    CURSOR=${#BUFFER}
}


start_session_with_ec2_instance(){
    local region=$1

    if [ $# -eq 0 ]; then
    echo 'No region name was passed as argument. Set the default region (us-west-2).'
    region='us-west-2'
    fi

    instance_id=$(aws ec2 describe-instances --region $region --query 'Reservations[].Instances[].[InstanceId, State.Name, InstanceType, PrivateIpAddress, Platform || `Linux`, Tags[?Key == `Name`].Value | [0]]' --output text | column -t | fzf --reverse | cut -d ' ' -f 1)
    aws ssm start-session --target ${instance_id} --region $region
}
