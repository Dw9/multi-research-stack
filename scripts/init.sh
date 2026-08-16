#!/usr/bin/env bash
# init.sh — research-stack skill 角色配置
# 用法: bash init.sh <student|teacher|bootstrap> [project-name]
#
# 传输层自动选: HERDR_ENV=1 → herdr(自发现); 否则 → tmux(.pi-pane+send-keys)
# 数据层(文件)两模式一致 —— 换传输不换真源。
#
# 配置哲学(重要): 配置 = 只教三样【协作方式 + 铁律 + 严谨规则】,教完 standby。
#   不读项目、不提问、不主动规划/派活。等用户给方向后再按铁律行动。
#   所以 AGENTS.md/CLAUDE.md 是自包含的——pi/claude 进项目目录 auto-load 即完成自配置,
#   不依赖 /skill 命令(claude 没有 pi 的 /skill 系统)。bootstrap 可由你在终端跑一次铺好两指针。
set -e
SKILL="$(cd "$(dirname "$0")/.." && pwd -P)"   # pwd -P: 规范物理路径(不论从 pi 还是 claude 侧符号链接调起都一致)
ROLE="$1"; PROJ="${2:-$(basename "$PWD")}"

case "$ROLE" in
  student|teacher|bootstrap) ;;
  *) echo "用法: bash init.sh <student|teacher|bootstrap> [project-name]"
     echo "  student  → 生成 AGENTS.md(pi 自动加载)"
     echo "  teacher  → 生成 CLAUDE.md(claude 自动加载)"
     echo "  bootstrap→ 两个都生成(你在终端跑一次,再启 pi+claude)"
     exit 1 ;;
esac

if [ "${HERDR_ENV:-}" = 1 ]; then MODE=herdr; echo "→ 配置 [$PROJ]  传输=[herdr(自发现)]";
else                              MODE=tmux;  echo "→ 配置 [$PROJ]  传输=[tmux(legacy)]";    fi

# 1. 铺共用协作文件(skip 已有)
for f in COLLAB_PROTOCOL.md RESULTS_LEDGER.md check_numbers.py \
         NEXT_TASK.md DONE_LOG.md REVIEW.md IDEAS.md .gitignore; do
  if [ -e "$f" ]; then echo "  [skip] $f"; continue; fi
  cp "$SKILL/templates/$f" .; sed -i "s/<PROJECT_NAME>/$PROJ/g" "$f"; echo "  [ok] $f"
done
if [ "$MODE" = herdr ]; then
  if [ ! -e collab.sh ]; then cp "$SKILL/scripts/collab.sh" .; chmod +x collab.sh; echo "  [ok] collab.sh"; else echo "  [skip] collab.sh"; fi
else
  if [ ! -e tmux-status.sh ]; then cp "$SKILL/templates/tmux-status.sh" .; chmod +x tmux-status.sh 2>/dev/null||true; echo "  [ok] tmux-status.sh"; else echo "  [skip] tmux-status.sh"; fi
fi

# 速查表(内嵌进指针文件 = 教铁律,防 agent 不去读全文)
RULES_CS='# 铁律速查(全文 '$SKILL'/references/rules.md,硬约束,写代码/报数/下结论前逐条自检)
0 先确认现象真实且新(原版有?文献报道过?) | 1 有参考源码逐行对照再写不臆测 | 2 一改动一验证后组合 | 3 永远先跑 baseline 对照 | 4 监控 PRIMARY_METRIC 非代理指标 | 5 报数保守(全集/均值±std+样本量/宁低不高) | 6 称新前查文献30min | 7 沉没成本不是继续的理由 | 8 严谨工程师视角审 claim | 9 不确定就做最小证伪实验 | 10 数字必出 RESULTS_LEDGER.md 或源文件,无源只写"未测"(+eval数标"任何一改就移动它的参数",跨源对比先对齐口径,报配对差±SE非std) | 11 数据确认你自己假设时最该自我批判(先查混淆变量能否归因/换指标基线split还成立吗/证据只支持半句就只写半句/庆祝在干净归因之后) | 12 novelty门是持续闸门,claim每次变形(reframe/换假说/换机制)都重过,深搜必联网全文核实非训练记忆'

# standby 段(两角色共用)
STANDBY='## 配置后:standby(重要)
配置 = 只掌握三样就够:**协作方式**(文件驱动交接 + collab.sh)、**铁律 0–10**、**严谨规则**。
- **配置阶段不读项目**(README/代码/ledger 都别碰)、**不提问**、**不主动产 idea / 规划 / 取活/派活**。
- **standby,等用户给方向**(idea、任务、或明确指令)后再按铁律 + 协作方式行动。
- DOMAIN/PRIMARY_METRIC 等项目配置由**用户给方向时填写**,你不要自己读项目猜,也不要追问用户。'

# 2a. AGENTS.md(student 指针)
gen_agents() {
  cat > AGENTS.md <<EOF
# $PROJ — 你是 student(执行 = pi)。立即自配置。

> 你 auto-load 本文件即是 student,**无需 /skill**。现在读下面两文件掌握职责与铁律:
> - 职责全文: \`$SKILL/roles/student.md\`
> - 铁律全文: \`$SKILL/references/rules.md\`
> teacher(claude)在同目录,经 ./collab.sh(herdr)或 .pi-pane(tmux)通信。

$STANDBY

## 你的一句话职责
跑实验/训练、写代码、**如实把数据更新进 RESULTS_LEDGER.md**。判断创新留给 teacher + novelty-reviewer,你的价值在如实可复现。

$RULES_CS

## 协作(文件驱动,详见 ./COLLAB_PROTOCOL.md)
- 取活:读 ./NEXT_TASK.md,QUEUED 顶条 → IN_PROGRESS 标 RUNNING
- 完成:数字从源文件(*.json/*.log/*.ckpt)读出标源 → append ./DONE_LOG.md → 更新 ./RESULTS_LEDGER.md → 本条移到 DONE 区
- block:在 NEXT_TASK 标 BLOCKED(注明等什么),不闷头卡
- 审阅:读 ./REVIEW.md 据此改

## 与 teacher(claude)通信
$( if [ "$MODE" = herdr ]; then
echo '- peer 运行时自发现(同 workspace+cwd 的 claude): \`./collab.sh peer\`'
echo '- 主动通知 teacher(BLOCKED/完成/新数据): \`./collab.sh send claude "请看 NEXT_TASK.md(...)"\`'
echo '- 看双方状态: \`./collab.sh status\` 或 herdr 侧边栏'
else
echo '- teacher 用 .pi-pane 里的 pane id 给你发指令(启动时已自报 \$TMUX_PANE)'
echo '- 通信走文件;tmux 只收一行"请读 X.md"'
fi )

## 项目配置(用户给方向时填,你别自己读项目猜/问)
- DOMAIN: <待填>
- PRIMARY_METRIC: <待填>
EOF
  echo "  [ok] AGENTS.md (student)"
}

# 2b. CLAUDE.md(teacher 指针——claude 无 /skill,靠本文件自举)
gen_claude() {
  if [ "$MODE" = tmux ]; then
    PIPANE=""; [ -f .pi-pane ] && PIPANE="$(tr -d '[:space:]' < .pi-pane 2>/dev/null||true)"
    [ -n "$PIPANE" ] && echo "  [ok] 读到 student pane = $PIPANE" || echo "  [note] .pi-pane 空。先跑 student 或 bootstrap"
  fi
  cat > CLAUDE.md <<EOF
# $PROJ — 你是 teacher(导师 = Claude)。立即自配置。

> 你 auto-load 本文件即是 teacher,**无需 /skill**(claude 没有 pi 的 /skill 系统,靠本文件自举)。
> 现在读下面两文件掌握职责与铁律:
> - 职责全文: \`$SKILL/roles/teacher.md\`
> - 铁律全文: \`$SKILL/references/rules.md\`
> student(pi)在同目录,经 ./collab.sh(herdr)或 .pi-pane(tmux)通信。

$STANDBY

## 你的一句话职责
审 idea 创新性、设计实验、把关诚信、写作定稿。你是防"严谨但不新"(LLM 科研系统性失败)的核心闸门——novelty 不足的 idea 不许消耗 GPU。

$RULES_CS

## 核心职责(用户给方向后才履行,详见 roles/teacher.md)
1. **审 idea 创新性**:任何消耗 GPU 的 idea,**先用 novelty-reviewer 子 agent 审**,判定非 INCREMENTAL/KNOWN 才派给 student。
2. **设计实验**:基于 RESULTS_LEDGER 已识别的瓶颈设计(瓶颈驱动,不自由 brainstorm);每个 idea 配能**证伪**它的最小实验(铁律9)。
3. **把关诚信**:对 student 的 claim 对抗式审(铁律8);数字必溯源 ledger(铁律10);交付前跑 \`python check_numbers.py\`。
4. **写作定稿**:措辞红线(追平非超过 / 权重复用非迁移),规避已知审稿攻击点。

## 派活给 student(pi)
$( if [ "$MODE" = herdr ]; then
echo '- 自发现零配置:student 是同 workspace+cwd 的 pi'
echo '- 派活(发一行"请读 NEXT_TASK.md"):  \`./collab.sh send pi "请读 NEXT_TASK.md"\`'
echo '- 短任务确认起跑加 \`--wait\`;长训练 fire-and-forget 别加'
echo '- 找 student pane: \`./collab.sh peer\` ; 看双方状态: \`./collab.sh status\` 或 herdr 侧边栏'
else
echo '- **快捷方式**(推荐): \`bash '"$SKILL"'/scripts/notify.sh "请读 NEXT_TASK.md"\` (自动读 .pi-pane + 发送)'
echo '- 手动方式: \`P=\$(cat .pi-pane); tmux send-keys -t \$P -l "请读 NEXT_TASK.md"; tmux send-keys -t \$P Enter\`'
echo '- **.pi-pane 不存在时**:手动创建,内容是 student 的 pane id(格式 \`%数字\`,从 \`tmux list-panes -a\` 找 pi 那行)'
echo '- 消息不能有换行;长内容写文件,tmux 只发一行'
fi )

## 项目配置(用户给方向时填,你别自己读项目猜/问)
- DOMAIN: <待填>
- PRIMARY_METRIC: <待填>
EOF
  echo "  [ok] CLAUDE.md (teacher)"
}

# 3. 按角色生成指针
case "$ROLE" in
  student)  gen_agents;;
  teacher)  gen_claude;;
  bootstrap) gen_agents; gen_claude;;
esac

echo
echo "✓ [$ROLE] 配置完成(传输: $MODE)。配置=只教协作+铁律+严谨规则,教完 standby。"
if [ "$MODE" = herdr ]; then
  echo "  —— herdr 自发现 ——"; ./collab.sh status 2>&1 || echo "  (暂无 agent 在本目录: 启动 pi/claude 在此 cwd 后即互相可见)"
fi
case "$ROLE" in
  student)  echo "  下一步: standby 等用户/teacher 给方向 → 收到\"请读 NEXT_TASK.md\"后取活执行";;
  teacher)  echo "  下一步: standby 等用户给 idea/方向 → 给了才走 novelty-reviewer 闸门 → 设计实验 → 派活";;
  bootstrap) echo "  下一步: 在本目录启动 pi(自动加载 AGENTS.md)和 claude(自动加载 CLAUDE.md),两者配置完即 standby 等用户方向";;
esac
