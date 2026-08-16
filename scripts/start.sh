#!/usr/bin/env bash
# start.sh — 一键起 research 协作环境(可选;手动开终端的可跳过)
# 用法: ./start.sh [session-name] [project-dir]
#   session-name 仅 tmux 模式用;project-dir 缺省=当前目录
#
# herdr 模式(HERDR_ENV=1): 在当前 workspace split 两 sibling pane →
#   herdr agent start student --kind pi / start teacher --kind claude → 打印角色配置提示
# tmux 模式(legacy): 起 tmux session(pi/claude/status 三 window)
set -e
DIR="${2:-$PWD}"

if [ "${HERDR_ENV:-}" = 1 ]; then
  # ---------------- herdr ----------------
  command -v herdr >/dev/null 2>&1 || { echo "ERR: herdr 不在 PATH" >&2; exit 1; }
  command -v python3 >/dev/null 2>&1 || { echo "ERR: python3 不在 PATH" >&2; exit 1; }
  cd "$DIR"

  echo "→ split sibling pane(右) 给 student"
  P1=$(herdr pane split --current --direction right --cwd "$DIR" --no-focus | python3 -c 'import json,sys;print(json.load(sys.stdin)["result"]["pane"]["pane_id"])')
  echo "  pane = $P1"

  echo "→ split sibling pane(下) 给 teacher"
  P2=$(herdr pane split --current --direction down --cwd "$DIR" --no-focus | python3 -c 'import json,sys;print(json.load(sys.stdin)["result"]["pane"]["pane_id"])')
  echo "  pane = $P2"

  echo "→ 起 student(pi) @ $P1  (命名 student,供按名寻址)"
  herdr agent start student --kind pi --pane "$P1"
  echo "→ 起 teacher(claude) @ $P2  (命名 teacher)"
  herdr agent start teacher --kind claude --pane "$P2"

  cat <<EOF

✓ herdr 协作环境就绪(@ $DIR):
   student = pi     @ $P1
   teacher = claude @ $P2
状态: ./collab.sh status   或看 herdr 侧边栏

现在去各 pane 里下发角色配置(顺序无关,各自自发现对方):
   在 student(pi) pane 说:   把我配置成 student   (或 /skill:research-stack student)
   在 teacher(claude) pane 说: 把我配置成 teacher  (或 /skill:research-stack teacher)
EOF
  exit 0
fi

# ---------------- tmux (legacy) ----------------
SESS="${1:-research}"
if [ ! -f "$DIR/AGENTS.md" ] && [ ! -f "$DIR/CLAUDE.md" ]; then
  echo "[warn] $DIR 里没有 AGENTS.md/CLAUDE.md。先跑: /skill:research-stack student|teacher" >&2
fi
if tmux has-session -t "$SESS" 2>/dev/null; then
  echo "session [$SESS] 已存在 → attach"; exec tmux attach-session -t "$SESS"
fi
cd "$DIR"
tmux new-session   -d -s "$SESS" -n pi     -c "$DIR" 'pi'
tmux new-window    -t "$SESS" -n claude -c "$DIR" 'claude'
tmux new-window    -t "$SESS" -n status -c "$DIR" 'watch -n5 ./tmux-status.sh'
tmux select-window -t "$SESS:claude"
cat <<EOF

✓ tmux session [$SESS] 已起(Ctrl+b 数字切换):
   0 pi      ← pi 执行端            1 claude ← 你主交互(导师)[当前]   2 status ← 观测
先在 pi window 跑 /skill:research-stack student(自报 pane→.pi-pane),再在 claude 跑 teacher。
派活: P=\$(cat .pi-pane); tmux send-keys -t \$P -l "请读 NEXT_TASK.md"; tmux send-keys -t \$P Enter
EOF
exec tmux attach-session -t "$SESS"
