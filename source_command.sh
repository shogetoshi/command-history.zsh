#!/usr/bin/env bash
set -euo pipefail

COMMAND_HISTORY_FILE="$1"
if [[ $# -ge 2 ]]; then
    current_realdir="${2}"
    tac "$COMMAND_HISTORY_FILE" | \
        jq -r --arg realdir "$current_realdir" 'select(.realdir == $realdir) | .command' 2>/dev/null | \
        awk '!a[$0]++' | \
        bat --plain --color always --language bash
else
    tac "$COMMAND_HISTORY_FILE" | \
        jq -r '.command' 2>/dev/null | \
        bat --plain --color always --language bash
fi
