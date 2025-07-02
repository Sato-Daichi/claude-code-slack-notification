#!/bin/bash

# Slack通知スクリプト

# スクリプトのディレクトリと設定ファイル
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
CONFIG_FILE="${SCRIPT_DIR}/.env"

# 設定ファイルの読み込み
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "警告: 設定ファイル .env が見つかりません (${CONFIG_FILE})"
fi

# Webhook URLの確認
if [ -z "$SLACK_WEBHOOK_URL" ]; then
    echo "エラー: SLACK_WEBHOOK_URL が設定されていません" >&2
    echo "scripts/.env に SLACK_WEBHOOK_URL を設定してください" >&2
    exit 1
fi

# 初期メッセージの分岐
case "$1" in
    "Notification")
        TITLE="*ツール使用を許可してください*"
        ;;
    "Stop")
        TITLE="*実行が完了しました*"
        ;;
    *)
        TITLE="*第一引数を指定してください*"
        ;;
esac

# 標準入力からJSONが与えられた場合、プロジェクト名を取得する
if [ ! -t 0 ]; then
    JSON_INPUT=$(cat)

    # transcript_path からプロジェクト名抽出（連続した "-" のあとを取り出す）
    TRANSCRIPT_PATH=$(echo "$JSON_INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
    if [ -n "$TRANSCRIPT_PATH" ]; then
        PROJECT_DIR=$(basename "$(dirname "$TRANSCRIPT_PATH")")
        PROJECT_NAME=$(echo "$PROJECT_DIR" | sed -E 's/^.*-{2,}//')  # "--" 以上の連続ハイフンのあとを取得
        MESSAGE="プロジェクト名: ${PROJECT_NAME}"
    fi

fi

# Slack通知の送信
curl -s -X POST "$SLACK_WEBHOOK_URL" \
    -H 'Content-Type: application/json' \
    -d @- <<EOF
{
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "${TITLE}\n${MESSAGE}"
      }
    }
  ]
}
EOF
