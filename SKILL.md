---
name: research-stack
description: Set up an LLM-driven research collaboration stack with pi as student/executor and claude as teacher/mentor. Use at the start of any research project, or when the user says 初始化科研栈 or 配置 teacher or 配置 student or 开新研究项目 or 对齐 agent 职责. Scaffolds the file-driven handoff protocol, single-source data ledger, novelty-gated idea flow, and injects role-specific duties via the /skill:research-stack student or teacher command. Prevents the two fatal research-agent failure modes of data fabrication and rigorous-but-not-novel work.
---

# research-stack — LLM 驱动科研协作栈

把 **pi(执行 / student)+ claude(导师 / teacher)** 双 agent 协作纪律,一键铺进任何科研项目。
核心防两个致命坑:**数据造假/误记**(ledger + check_numbers)、**严谨但不新**(novelty-reviewer 闸门)。

## When to use
- 新开科研项目,需要对齐两个 agent 的职责与协作纪律时
- 用户说"初始化科研栈 / 配置 teacher / 配置 student / 开新研究项目"时

## 两个角色
- **teacher(导师 = Claude)**:审 idea 创新性、设计实验、把关诚信、写作定稿。
- **student(执行 = pi)**:跑实验/训练、写代码、更新数据进 ledger。

两者**共享铁律 0–10**(见 `references/rules.md`),职责全文见 `roles/{teacher,student}.md`。

## 两个平面(理解本 skill 的关键)
| 平面 | 载体 | 可换 |
|---|---|---|
| **数据/状态面** | 文件(LEDGER / NEXT_TASK / DONE_LOG / REVIEW / IDEAS) | ❌ 不可换,单一真源 + 审计轨迹 + check_numbers 核对对象 |
| **传输/控制面** | herdr(`HERDR_ENV=1`,自发现)或 tmux(`.pi-pane`+`send-keys`) | ✅ init.sh 自动选 |

## 命令

> **触发方式因工具而异,workflow 相同**:pi 显式打 `/skill:research-stack <role>`;claude 无 `/skill:` 前缀,靠本 skill 的 description 自动触发(你说"配置 teacher/student"即可)。两者都执行同一套:`bash <skill>/scripts/init.sh <role>` → 读 roles+rules → 对齐职责。本 skill 文件 pi(`~/.agents/skills/research-stack`)与 claude(`~/.claude/skills/research-stack`→符号链接)**共享同一份**。
>
> 推荐姿势(herdr):你自己 `herdr` → 开两个 pane 各 `cd 项目` → 分别跑 `pi`、`claude` → 在各自 pane 说"把我配置成 student/teacher"(或 pi 打 `/skill:research-stack <role>`)。两 agent **运行时自发现对方,零配置**。

### `/skill:research-stack student`  ← 在 **pi** 会话里跑
pi 自我配置为 student(执行):铺协作文件 → 读 `roles/student.md` + `references/rules.md` → 生成 `AGENTS.md` 指针 → 对齐"等 NEXT_TASK"。
- herdr 模式:自动铺 `collab.sh`(peer 自发现,**无 .pi-pane**)
- tmux 模式:自报 `$TMUX_PANE` → `.pi-pane`

### `/skill:research-stack teacher`  ← 在 **claude** 会话里跑
claude 自我配置为 teacher(导师):铺协作文件(若无)→ 读 `roles/teacher.md` + `references/rules.md` → 生成 `CLAUDE.md` 指针 → 对齐"审 idea/派活"。
- herdr 模式:派活用 `./collab.sh send pi "请读 NEXT_TASK.md"`(自发现)
- tmux 模式:读 `.pi-pane` 拿 student 的 pane target → `tmux send-keys`

### `/skill:research-stack start [session]`(可选)
不想手动开终端时一键起环境。herdr 模式:split 两 pane + `agent start`;tmux 模式:起 pi/claude/status 三 window。手动开的忽略此命令。

### `/skill:research-stack help`
显示用法。

> **顺序**:herdr 模式两命令**顺序无关**(各自自发现);tmux 模式**先 student(自报 pane)再 teacher(读 pane)**。
> **传输自动选**:`HERDR_ENV=1`→herdr,否则→tmux。**数据层(文件)两模式完全一致**——换传输不换真源。

## 你(agent)收到角色命令后的自我配置 workflow
1. 解析参数:`role` = student|teacher;`project-name` = 缺省当前目录名。无效 → 显示 help。
2. 运行:`bash <skill目录>/scripts/init.sh <role> <project-name>`(它按 `HERDR_ENV` 自动选传输层)
3. 读对应 `roles/<role>.md` + `references/rules.md`,**按角色职责对齐自己**(student 准备取活;teacher 准备审 idea/派活)。
4. **peer 对齐**(传输层):
   - herdr:无需手动——`collab.sh` 运行时按"同 workspace+cwd+对端 kind"自发现 partner。
   - tmux:student 确认 `.pi-pane` 已写;teacher 读 `.pi-pane` 拿 target。
5. 引导用户填 DOMAIN / PRIMARY_METRIC,提示对端 agent 跑对端角色命令。

## 铺进项目的协作文件(共用,不分角色)
| 文件 | 作用 |
|---|---|
| COLLAB_PROTOCOL.md | 文件驱动交接协议(两平面分离) |
| RESULTS_LEDGER.md | 唯一数据真源(防铁律10) |
| check_numbers.py | 交付前机械核对数字可溯源 |
| NEXT_TASK.md | 任务队列+状态机(student 取活) |
| DONE_LOG.md | 完成审计轨迹 |
| REVIEW.md | teacher 审阅(student 读后改) |
| IDEAS.md | idea 池(过 novelty-reviewer 闸门) |
| collab.sh | herdr 协作助手:peer 自发现 + 派活 + 状态(**herdr 模式铺**,替代 tmux-status.sh) |
| tmux-status.sh | tmux 观测面板(**tmux 模式铺**) |
| .gitignore | 忽略 logs/权重/产物 |

另按角色生成:`AGENTS.md`(student,pi 自动加载)或 `CLAUDE.md`(teacher,claude 自动加载)——内容是指针,指向本 skill 的 roles + rules + 项目特定配置。

## 协作循环(速览)
- **派活**(teacher→student):idea 先过 novelty-reviewer → 写 NEXT_TASK → **传输层立即通知**"请读 NEXT_TASK.md"(herdr:`./collab.sh send pi ...`;tmux:`bash <skill>/scripts/notify.sh "请读 NEXT_TASK.md"` 或手动 `send-keys`)
- **取活**(student):读 NEXT_TASK → 标 RUNNING → 跑 → 数字标源 → append DONE_LOG + 更新 RESULTS_LEDGER
- **审阅**(teacher):看产出 → 对抗式审(铁律8)→ 写 REVIEW.md(PASS/REVISE/REJECT)→ **立即通知** student "请读 REVIEW.md"
- **技术讨论**(student→teacher):发起讨论 → teacher 对抗式质疑 → 写 REVIEW.md(或指定文件)→ **立即通知** student
- **交付前**:`python check_numbers.py`

**重要**:生成审阅/回复后**必须通知对端**,否则对方看不到。tmux 模式:`.pi-pane` 不存在时需手动创建(内容是 student 的 `$TMUX_PANE`,格式 `%数字`,从 `tmux list-panes -a` 找)。

## 依赖
- `novelty-reviewer` 子 agent(user 级,`~/.agents/novelty-reviewer.md`,跨项目自动可用)。teacher 用它给 idea 过闸门。若缺失,先重建(见 references/troubleshooting)。
- herdr 模式额外需要:`herdr` 在 PATH、`python3`(collab.sh 解析 JSON)、`HERDR_ENV=1`。三者缺一则 init.sh 自动回退 tmux 模式。

## 一键起环境 + 观测(可选)
手动派工时跳过本节。需要时:
```bash
bash <skill目录>/scripts/start.sh [session] [project-dir]
```
- herdr:`pane split` 出两 pane → `herdr agent start student --kind pi` / `start teacher --kind claude`;状态看 herdr 侧边栏或 `./collab.sh status`。
- tmux:起 session 含 pi/claude/status 三 window;Ctrl+b 数字切换。

无论手动还是 start.sh,**派活都走文件**(NEXT_TASK.md),传输只发一行"请读 X.md"。详见 COLLAB_PROTOCOL.md「两个平面」。
