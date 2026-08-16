# COLLAB_PROTOCOL.md — Claude(导师) × pi agent 共同规范

两个 agent 受同一套铁律 0–10(AGENTS.md / CLAUDE.md 全文)。本文件补协作细节。

## 分工
- **Claude(导师)**:审 claim 的创新性/严谨性、把关诚信、设计实验、写作定稿。
- **pi agent**:跑实验/训练、写代码、更新数据。

## 两个平面(务必分开理解)
| 平面 | 载体 | 可换吗 |
|---|---|---|
| **数据/状态面** | 文件(LEDGER / NEXT_TASK / DONE_LOG / REVIEW / IDEAS) | ❌ 不可换,这是单一真源 + 审计轨迹 + check_numbers.py 的核对对象 |
| **传输/控制面** | herdr(自发现 + `herdr agent prompt`)或 tmux(`.pi-pane`+`send-keys`) | ✅ 可换,init.sh 按 `HERDR_ENV` 自动选 |

> 铁律:**通信走文件,传输只发"请读 X.md"一行**。传输层换 herdr/tmux 不改变这一点。

## 数据(铁律 5/10 落地)
- 唯一真源:`RESULTS_LEDGER.md`。任何汇报/论文数字必须出自它,每行标源文件。
- 出新数据:从源文件(*.json/*.log/*.ckpt名)读 → 更新 ledger → 再引用。禁止口头/记忆报数。
- 交付前跑 `python check_numbers.py`:机械核对稿中数字都能在 ledger 溯源。

## 文件驱动交接 v1

### 职责分层
| 职责 | 载体 | 说明 |
|---|---|---|
| 指令传递 | `NEXT_TASK.md` | 取活/派活。**绝不**靠传输层逐行发长内容 |
| 审阅反馈 | `REVIEW.md` | Claude 审阅写这,pi 读后改 |
| 完成审计 | `DONE_LOG.md` | pi 完成后 append(数字标源) |
| idea 池 | `IDEAS.md` | 每个 idea 先过 `novelty-reviewer` 才能派活 |
| 实时观测 | herdr 侧边栏 / `./collab.sh status` | herdr 模式;tmux 模式用 `watch ./tmux-status.sh` |

### 状态机
`QUEUED` → `RUNNING` → `BLOCKED`(等什么) → `REVIEW`(等 Claude) → `DONE`

### 操作约定
- **派活**(Claude→pi):往 `NEXT_TASK.md` 的 QUEUED 区加条目;传输层只发一行"请读 NEXT_TASK.md"。
- **取活**(pi):读 `NEXT_TASK.md`,把 QUEUED 顶条移到 IN_PROGRESS 并标 RUNNING。
- **完成**(pi):数字从源文件读出标源 → append `DONE_LOG.md` → 更新 `RESULTS_LEDGER.md` → 本条移到 NEXT_TASK 的 DONE 区(只留 3 条)。
- **审阅**(Claude):结果进 `REVIEW.md`(PASS/REVISE/REJECT)。
- **任何消耗 GPU 的 idea**:先写进 `IDEAS.md` → 过 `novelty-reviewer`(判定非 INCREMENTAL/KNOWN)→ 才进 NEXT_TASK。

## 传输层 A:herdr 模式(`HERDR_ENV=1`,推荐)

peer **运行时自发现**,零配置、无静态文件、不怕 pane 重启换号:
> peer = `herdr agent list` 里 **workspace 相同 ∧ cwd 相同(项目根) ∧ kind 对端**(student=pi↔teacher=claude)

所有传输操作走 `./collab.sh`(init.sh 已铺进项目根):
```bash
./collab.sh peer                # 找对端 pane(缺省=我的对端 kind)
./collab.sh send pi "请读 NEXT_TASK.md"          # 派活(fire-and-forget,匹配旧 send-keys 语义)
./collab.sh send pi "请读 NEXT_TASK.md" --wait    # 短任务:确认 pi 收下并起跑;长训练别加
./collab.sh status              # 本项目两 agent 生命周期状态(替代 tmux-status.sh)
```
- 不再有 `.pi-pane`、不再有 `tmux send-keys`、不再怕"消息里有换行"(`agent prompt` 原子投递,感知粘贴模式)。
- herdr 侧边栏自带 agent 状态面板,无需另开 status 窗口。

## 传输层 B:tmux 模式(legacy,无 herdr 时自动回退)

student 自报 pane id → `.pi-pane`,teacher 读之 `send-keys`:
```bash
# student(pi)配置时自动: printf '%s\n' "$TMUX_PANE" > .pi-pane
# teacher(claude)派活:
P=$(cat .pi-pane); tmux send-keys -t "$P" -l "请读 NEXT_TASK.md"; tmux send-keys -t "$P" Enter
# .pi-pane 空/过期: tmux list-panes -a -F '#{pane_id} #{pane_current_command}' 找 pi
```
- 消息内**不能有换行**;长内容写文件,tmux 只发一行。
- 观测:`tmux split-window -h 'watch -n5 ./tmux-status.sh'`。

## 结论纪律(铁律 9)
- 不确定不硬下结论;理论可行就做能证伪的最小实验,用数据判断。
- 实验进行中:只报 checkpoint/日志里**实际存在**的数字;没到的明说"未到,等"。
