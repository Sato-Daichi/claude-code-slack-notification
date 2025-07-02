#!/bin/bash

# Slack通知スクリプト
# 任意のメッセージをSlackに通知します

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

# デフォルトメッセージ
DEFAULT_MESSAGE="作業が完了しました :white_check_mark:"
MESSAGE="${1:-$DEFAULT_MESSAGE}"

# 標準入力からJSONが与えられた場合、セッションIDを追加
if [ ! -t 0 ]; then
    JSON_INPUT=$(cat)
    SESSION_ID=$(echo "$JSON_INPUT" | jq -r '.session_id // empty' 2>/dev/null)
    if [ -n "$SESSION_ID" ]; then
        MESSAGE="${MESSAGE}\nセッションID: ${SESSION_ID}"
    fi
fi

# 実行時刻
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Slack通知の送信
curl -s -X POST "$SLACK_WEBHOOK_URL" \
    -H 'Content-Type: application/json' \
    -d @- <<EOF
{
  "username": "NotifyBot",
  "icon_emoji": ":bell:",
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*:robot_face: Claude Code 通知*"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "${MESSAGE}"
      }
    },
  ]
}
EOF
