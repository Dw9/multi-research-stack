#!/usr/bin/env bash
# notify.sh — 辅助脚本:tmux 模式下通知 student
# 用法: bash notify.sh "请读 REVIEW.md"
#
# 自动处理:
# - 读 .pi-pane 获取 student pane target
# - .pi-pane 不存在时提示如何创建
# - 发送消息 + Enter

set -e

MSG="${1:-请读 REVIEW.md}"

if [ ! -f .pi-pane ]; then
  echo "❌ .pi-pane 不存在。需要手动创建:"
  echo "   1. 找到 student(pi)的 pane:"
  echo "      tmux list-panes -a -F '#{pane_id} #{pane_current_command} #{pane_current_path}'"
  echo "   2. 找到显示 'pi' 且路径是本目录的那行,记下 pane_id(格式 %数字)"
  echo "   3. 写入 .pi-pane:"
  echo "      echo '%数字' > .pi-pane"
  echo ""
  echo "或者让 student 先跑: /skill:research-stack student (会自报 pane)"
  exit 1
fi

PANE="$(tr -d '[:space:]' < .pi-pane)"

if [ -z "$PANE" ]; then
  echo "❌ .pi-pane 是空的,按上述步骤填入 student 的 pane id"
  exit 1
fi

echo "→ 通知 student($PANE): $MSG"
tmux send-keys -t "$PANE" -l "$MSG"
tmux send-keys -t "$PANE" Enter
echo "✓ 已发送"
