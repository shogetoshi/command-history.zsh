# command-history.zsh - コマンド履歴をJSONL形式で保存するzshプラグイン

SCRIPT_DIR="${0:A:h}"

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

# コマンド履歴選択用ZLEウィジェット
_command_history_select() {
    # 履歴ファイルが存在しない場合
    if [[ ! -f "$COMMAND_HISTORY_FILE" ]]; then
        touch "$COMMAND_HISTORY_FILE"
    fi

    # 現在のディレクトリのrealpath（シンボリックリンク解決後）
    local current_realdir="$(pwd -P)"

    # JSONLから現在のrealdirと一致するエントリのみ抽出してfzfで選択（新しい順に表示）
    local selected=$(bash $SCRIPT_DIR/source_command.sh $COMMAND_HISTORY_FILE $current_realdir | \
        fzf --read0 --multi --ansi --wrap --delimiter '\n' --nth '2..' \
        --bind "ctrl-r:reload:bash $SCRIPT_DIR/source_command.sh $COMMAND_HISTORY_FILE" \
    )

    if [[ -n "$selected" ]]; then
        # 現在のバッファを置き換え
        LBUFFER="$selected"
        RBUFFER=""
    fi

    zle reset-prompt
}

# ZLEウィジェットとして登録
zle -N _command_history_select
