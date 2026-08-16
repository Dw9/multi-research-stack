# COLLAB_PROTOCOL.md — Claude(导师) × pi agent 共同规范

两个 agent 受同一套铁律 0–10（CLAUDE.md / AGENTS.md 全文）。本文件只补协作细节。

## 分工
- **Claude（导师）**：审 claim 的创新性/严谨性、把关诚信、设计实验、写作定稿。
- **pi agent**：跑实验/训练、写代码、更新数据。跑在 tmux `pi-sflow`（pi.dev, glm-5.2）。

## 数据（铁律 5/10 落地）
- 唯一真源：`RESULTS_LEDGER.md`。任何汇报/论文数字必须出自它，每行标源文件。
- 出新数据：从源文件（*.json/*.log/*.ckpt名）读 → 更新 ledger → 再引用。禁止口头/记忆报数。
- 交付前跑 `python check_numbers.py`：机械核对稿中数字都能在 ledger 溯源。

## tmux 通信纪律（pi 界面限制）
- 给 pi 的消息**只发单行**：`tmux send-keys -t pi-sflow -l "单行内容"` 后单独 `Enter`。
- 消息内**不能有换行**（会触发 pi 界面 "not in a mode" 报错，逐行失败）。
- 长内容/多步指令：写成文件，tmux 只发一行"请读 X.md"。
- 发完 `capture-pane` 确认干净落地，乱了改文件指针方式，不硬重发。

## 结论纪律（铁律 9）
- 不确定不硬下结论；理论可行就做能证伪的最小实验，用数据判断。
- 实验进行中：只报 checkpoint/日志里**实际存在**的数字；没到的明说"未到，等"。

## 新协作协议（文件驱动交接 v1）— 2026-08-03 起

解决 tmux 单行通信的脆弱性（不能有换行/容易乱），同时**保留 tmux 的实时观测价值**。
核心：**通信走文件，观测靠 tmux**。两边各司其职。

### 职责分层
| 职责 | 载体 | 说明 |
|---|---|---|
| 指令传递（通信） | `NEXT_TASK.md` | 取活/派活。告别 `send-keys` 单行地狱 |
| 审阅反馈 | `REVIEW.md` | Claude 审阅写这，pi 读后改 |
| 完成审计 | `DONE_LOG.md` | pi 完成后 append（数字标源） |
| idea 池 | `IDEAS.md` | 每个 idea 先过 `novelty-reviewer` 才能派活 |
| 实时观测 | tmux `pi-sflow`（不变）+ `watch -n5 ./tmux-status.sh` | attach 看 pi 干活；另开 pane 看状态速览 |

### 状态机
`QUEUED` → `RUNNING` → `BLOCKED`(等什么) → `REVIEW`(等 Claude) → `DONE`

### 操作约定
- **派活**（Claude→pi）：往 `NEXT_TASK.md` 的 QUEUED 区加条目；tmux 只发一行"请读 NEXT_TASK.md"。
- **取活**（pi）：读 `NEXT_TASK.md`，把 QUEUED 顶条移到 IN_PROGRESS 并标 RUNNING。
- **完成**（pi）：数字从源文件读出标源 → append `DONE_LOG.md` → 更新 `RESULTS_LEDGER.md` → 本条移到 NEXT_TASK 的 DONE 区（只留 3 条）。
- **审阅**（Claude）：结果进 `REVIEW.md`（PASS/REVISE/REJECT）。
- **任何消耗 GPU 的 idea**：先写进 `IDEAS.md` → 过 `novelty-reviewer`（判定非 INCREMENTAL/KNOWN）→ 才进 NEXT_TASK。

### tmux 用法（观测面板）
```bash
tmux split-window -h 'watch -n5 ./tmux-status.sh'   # 左边看 pi，右边看状态速览
```

### tmux 通信纪律（保留，但用量大减）
- 长内容仍写成文件指针（"请读 X.md"），tmux 只发一行。
- send-keys 后仍 `capture-pane` 确认落地。但日常派活不再逐行发指令——指针即可。

## 结果产物不可覆盖(2026-08-13 新规, 因 B1 事故)

**事故**: `bench_a100.json` 被 v2 重跑覆盖, 且 git 未跟踪 → 已入 ledger 并经导师批准的 v1 数字
(40.42/197.20/RTF 0.01607)**在磁盘上不复存在**, 按铁律10 只能整体作废重写。

**新规(硬约束)**:
1. **结果产物一律写版本化文件名**(`bench_a100_v2.json`), **禁止覆盖已被 ledger 引用的文件**。
2. ledger 每行除文件名外**记录 sha256 前 16 位**, 使"活源"可验证而非仅可寻址。
3. 重跑产生新版本时: 新文件 + ledger 新行 + 旧行标注"已被 vN 取代", **不得原地改数字**。
4. 交付前 `check_numbers.py` 之外, 另需确认被引文件的 sha256 与 ledger 一致。

## 恒等式校验(2026-08-13 固化, 导师1 提出 / mentor2 背书)

**动机**:本项目两次数据事故**都是这一类**,且都在"数字方向符合我们想要的叙事"时发生:
1. **RTF 错 3 倍**(48kHz 样本数误按 16000 除)——单位/量纲;
2. **能耗错且方向反转**(`bench_jetson.py:186` 公式退化为 `P/30`)——量纲闭合。
两次都不是靠事后对抗审查发现的,是靠**一个五秒钟的算式**。

**硬规矩:每个新测量量,必须配一个"物理上必须成立"的恒等式,并在 json 里报校验结果。**

### 检查一:量纲闭合(dimensional closure)
把量按定义展开,单位必须自洽。本项目现行恒等式清单:
- `每秒音频能耗 = 平均功率 × RTF`(等价:`P × wall_s / audio_s`)
- `增量能耗 = (P_total − P_idle) × wall_s / audio_s`
- `RTF = latency / audio_duration`(**per-file 与 mean-of-means 是两个不同量,禁混用**)
- `N=K 延迟 ≈ K × 单步前向 + 一次 iSTFT`
- `加速比 = 延迟比`
- `fp32 权重字节 = 参数量 × 4`
- `Σ 单句耗时 = 总墙钟`(允许调度开销)

### 检查二:极限 sanity(limit sanity)
把参数推到极限,结果必须退化为已知量:
- 缩容 `c→1` 必须复现原模型(逐位);
- `N=1` 时求解器必须退化为单步;
- 功耗档最高时延迟必须最小、功率必须最大;
- `idle 功率 < 满载功率`;
- 等价性改动的 `|Δ| → 0`。

### ⚠️ 边界(mentor2 指出,必须一起记住)
恒等式校验是**必要不充分**。它**查不出**:
- **口径错配**——per-file RTF vs mean-of-means 两个数都能通过各自的恒等式,但混用即错;
- **归因混淆**——complex32 机制"成立"却"不足以解释量级",恒等式对此完全无感。
→ 所以恒等式校验**不替代**对抗式审查与"机制成立≠机制足够"的量级检。两者叠加,不是二选一。

## 教训(2026-08-15, fp16 悬案终局): 凡复用管线先 diff 入口函数
- 事故: 手写 load_audio 替代旧脚本同名函数, 漏 48k→16k 重采样, 48kHz 直灌 16kHz 模型必塌; 引发两条错误结论("pure 算子摧毁质量"/"顺序依赖假象")各存活数小时, 一天内连续作废两次。
- 规矩: **复用任何既有管线(哪怕只搬一个函数), 先 diff 新旧入口函数**(load_audio/enhance/spec/metric 计算与归一化), 确认数据口径(采样率/声道/dtype/归一化)逐项一致后才跑; 入口函数不一致 = 不同实验, 不得混比。

## 教训(2026-08-16, M55 终检): 汇报"已修"须附代码 grep 证据 — 铁律14 自查版
- 事故: M55 五项汇报"全落", 实际 GTCRN 去棒一项 `yerr=[gtq[1]]` 仍在代码里(我分段 replace 的六小步中该步 anchor 没匹配上, 静默跳过), 导师终检 grep 抓到并代修。
- 规矩: **凡汇报"已改/已修/已落", 必附 grep/运行输出证据**(改了什么就 grep 什么); 多步替换必须逐步断言成功(`assert n==len(steps)`), 任一步 anchor 未中即报失败, **不许静默跳过** — 这正是铁律14"告警不是把关"在自查场景的镜像: 口头'已修'不是证据。

## 第二课(2026-08-16, M57 终审): 修显示层 bug 先审结构, 不只改参数
- 事故: Fig6.2 双刻度叠印, 我在第一个 twinx 上 set_ylim(44,48) 汇报"修毕"; 根因是 **twinx 在循环体内被建了两次**(两档各一个右轴), 我只改了第一轴的参数, 第二轴自动刻度照旧叠印。导师结构修: twinx 移出循环建一次, 两档共轴, 治根。
- 规矩: 修显示/绘图 bug 前, **先数清结构: 几个 axis、几个 artist、谁在循环内谁在循环外**; 参数级修补(set_ylim/label)只有在结构正确后才有意义。汇报修复时附结构证据(如 grep twinx 计数), 不只附参数行。
