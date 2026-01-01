# command-history.zsh - コマンド履歴をJSONL形式で保存するzshプラグイン

# 履歴ファイルのパス（カスタマイズ可能）
: ${COMMAND_HISTORY_FILE:="${HOME}/.command_history.jsonl"}

# コマンド実行前に呼ばれるフック関数
_command_history_preexec() {
    local cmd="$1"
    local dir="$(pwd)"
    local realdir="$(pwd -P)"
    local timestamp="$(TZ='Asia/Tokyo' date +"%Y-%m-%dT%H:%M:%S+09:00")"

    # 空のコマンドは記録しない
    [[ -z "$cmd" ]] && return

    # jqを使ってJSONL行を作成（エスケープはjqに任せる）
    jq -c -n \
        --arg cmd "$cmd" \
        --arg dir "$dir" \
        --arg realdir "$realdir" \
        --arg ts "$timestamp" \
        '{command: $cmd, dir: $dir, realdir: $realdir, timestamp: $ts}' \
        >> "$COMMAND_HISTORY_FILE"
}

# preexecフックに登録
autoload -Uz add-zsh-hook
add-zsh-hook preexec _command_history_preexec
