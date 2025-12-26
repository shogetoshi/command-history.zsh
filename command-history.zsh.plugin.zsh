# command-history.zsh - コマンド履歴をJSON形式で保存するzshプラグイン

# 履歴ファイルのパス（カスタマイズ可能）
: ${COMMAND_HISTORY_FILE:="${HOME}/.command_history.json"}

# JSON用の文字列エスケープ関数
_command_history_escape_json() {
    local str="$1"
    # バックスラッシュ、ダブルクォート、改行、タブをエスケープ
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\t'/\\t}"
    str="${str//$'\r'/\\r}"
    echo -n "$str"
}

# コマンド実行前に呼ばれるフック関数
_command_history_preexec() {
    local cmd="$1"
    local dir="$(pwd)"
    local timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    # 空のコマンドは記録しない
    [[ -z "$cmd" ]] && return

    # JSON用にエスケープ
    local escaped_cmd="$(_command_history_escape_json "$cmd")"
    local escaped_dir="$(_command_history_escape_json "$dir")"

    # JSONエントリを作成
    local json_entry="{\"command\":\"${escaped_cmd}\",\"directory\":\"${escaped_dir}\",\"timestamp\":\"${timestamp}\"}"

    # ファイルが存在しない場合は配列として初期化
    if [[ ! -f "$COMMAND_HISTORY_FILE" ]]; then
        echo "[$json_entry]" > "$COMMAND_HISTORY_FILE"
    else
        # 既存のファイルに追加（最後の ] を削除して追記）
        # ファイルサイズが2バイト以上（空配列[]以上）の場合
        local filesize=$(wc -c < "$COMMAND_HISTORY_FILE" | tr -d ' ')
        if [[ $filesize -le 2 ]]; then
            echo "[$json_entry]" > "$COMMAND_HISTORY_FILE"
        else
            # 末尾の ] と改行を削除し、カンマと新エントリを追加
            # sedを使用して末尾の]を削除し、新しいエントリを追加
            local tmp_file="${COMMAND_HISTORY_FILE}.tmp"
            sed '$ s/]$//' "$COMMAND_HISTORY_FILE" > "$tmp_file"
            echo ",$json_entry]" >> "$tmp_file"
            mv "$tmp_file" "$COMMAND_HISTORY_FILE"
        fi
    fi
}

# preexecフックに登録
autoload -Uz add-zsh-hook
add-zsh-hook preexec _command_history_preexec
