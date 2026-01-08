#!/usr/bin/env bash
set -euo pipefail

COMMAND_HISTORY_FILE="$1"
if [[ $# -ge 2 ]]; then
    current_realdir="${2}"
    tac "$COMMAND_HISTORY_FILE" | \
        jq -r --arg realdir "$current_realdir" 'select(.realdir == $realdir) | "\t\(.command)"' 2>/dev/null | \
        awk '!a[$0]++' | \
        bat --plain --color always --language bash | \
        tr '\n' '\0' | sed -z 's/\t/\n/'
else
    tac "$COMMAND_HISTORY_FILE" | \
        jq -r '"\(.dir)\t\(.command)"' 2>/dev/null | \
        awk '!a[$0]++' | \
        bat --plain --color always --language bash | \
        tr '\n' '\0' | sed -z 's/\t/\n/'
fi
