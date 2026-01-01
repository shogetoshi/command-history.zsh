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

# コマンド履歴選択用ZLEウィジェット
_command_history_select() {
    # fzfが利用可能かチェック
    if ! command -v fzf &> /dev/null; then
        zle -M "fzfがインストールされていません"
        return 1
    fi

    # 履歴ファイルが存在しない場合
    if [[ ! -f "$COMMAND_HISTORY_FILE" ]]; then
        zle -M "履歴ファイルが存在しません: $COMMAND_HISTORY_FILE"
        return 1
    fi

    # JSONLからコマンドを抽出してfzfで選択（新しい順に表示）
    # macOS互換: tacがなければtail -rを使用
    local selected
    if command -v tac &> /dev/null; then
        selected=$(tac "$COMMAND_HISTORY_FILE" | jq -r '.command' 2>/dev/null | fzf --height 40% --reverse --prompt="履歴> ")
    else
        selected=$(tail -r "$COMMAND_HISTORY_FILE" | jq -r '.command' 2>/dev/null | fzf --height 40% --reverse --prompt="履歴> ")
    fi

    if [[ -n "$selected" ]]; then
        # 現在のバッファを置き換え
        LBUFFER="$selected"
        RBUFFER=""
    fi

    zle reset-prompt
}

# ZLEウィジェットとして登録
zle -N _command_history_select
