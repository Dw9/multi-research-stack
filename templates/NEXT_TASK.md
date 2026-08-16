# 当前任务队列

> **协议**:pi agent 每轮读这个文件取活;完成后 append 到 `DONE_LOG.md` 并把本条移到底部 DONE 区(只留最近 3 条)。
> Claude(导师)审阅结果写 `REVIEW.md`,pi 读后改。
> 状态机:`QUEUED` → `RUNNING` → `BLOCKED`(等什么) → `REVIEW`(等 Claude) → `DONE`
> 人类观测:tmux attach 看 pi 干活;另开 pane 跑 `watch -n5 ./tmux-status.sh` 看速览。

---

## 🔴 IN_PROGRESS(pi 正在做)
<!-- 没有 = pi 空闲,等 Claude 派活。派活前 idea 须先过 novelty-reviewer -->
- _(空)_

## 🟡 QUEUED(排队,等 pi 接)
- _(空)_

## ⚪ DONE(最近 3 条;完整记录见 `DONE_LOG.md`)
- _(空)_
