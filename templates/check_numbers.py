#!/usr/bin/env python3
"""机械检查:稿件里的实验数字是否都能在 RESULTS_LEDGER.md 找到。
不依赖任何 agent 的自觉——交付/汇报前跑一次。发现稿中出现、ledger 里没有的
数字 → 报警(可能是编造或未入账)。

用法:
  python check_numbers.py                    # 自动扫描 manuscript*/draft*/paper*/report* 及中文稿
  python check_numbers.py doc1.md doc2.md    # 指定稿件
"""
import re, sys, os, glob

LEDGER = "RESULTS_LEDGER.md"
# 协作/纪律文件,不当作稿件扫描
EXCLUDE = {
    "RESULTS_LEDGER.md", "AGENTS.md", "CLAUDE.md", "COLLAB_PROTOCOL.md",
    "NEXT_TASK.md", "DONE_LOG.md", "REVIEW.md", "IDEAS.md", "STARTUP.md",
}

# 关注"实验指标量级"的数字:带小数点、2-4位小数(如 PESQ 3.062 / loss 0.0156 / 12.34dB)。
# 放过年份/编号/引用号(它们通常不带这种小数格式)。
NUM_RE = re.compile(r"(?<![\w.])\d\.\d{2,4}(?![\w])")

def default_docs():
    if sys.argv[1:]:
        return sys.argv[1:]
    pats = ["manuscript*.md", "draft*.md", "paper*.md", "report*.md", "*稿*.md", "*manuscript*"]
    found = set()
    for p in pats:
        for f in glob.glob(p):
            if os.path.basename(f) not in EXCLUDE:
                found.add(f)
    return sorted(found)

def load_ledger_numbers(path):
    if not os.path.exists(path):
        print(f"[FATAL] 找不到 {path}"); sys.exit(2)
    txt = open(path, encoding="utf-8").read()
    return set(NUM_RE.findall(txt))

def approx_in(num, ledger_nums):
    if num in ledger_nums:
        return True
    try:
        v = float(num)
        for l in ledger_nums:
            if abs(float(l) - v) <= 0.001:
                return True
    except ValueError:
        pass
    return False

def main():
    docs = default_docs()
    ledger_nums = load_ledger_numbers(LEDGER)
    print(f"ledger 中指标数字 {len(ledger_nums)} 个: {sorted(ledger_nums)}\n")
    if not docs:
        print(f"[note] 未找到默认稿件(manuscript*/draft*/paper*/report*)。用 `python check_numbers.py <稿件.md>` 指定。")
        return
    any_flag = False
    for doc in docs:
        if not os.path.exists(doc):
            print(f"[skip] {doc} 不存在"); continue
        txt = open(doc, encoding="utf-8").read()
        flagged = []
        for m in NUM_RE.finditer(txt):
            num = m.group()
            if not approx_in(num, ledger_nums):
                line = txt[:m.start()].count("\n") + 1
                flagged.append((line, num))
        if flagged:
            any_flag = True
            print(f"[WARN] {doc}: 以下数字在 ledger 中查无来源(可能编造/未入账):")
            for line, num in flagged:
                print(f"    L{line}: {num}")
        else:
            print(f"[OK] {doc}: 所有指标数字均可在 ledger 溯源。")
    print()
    if any_flag:
        print(">>> 有查无来源的数字。要么把它从源文件补进 RESULTS_LEDGER.md,要么删除/改'未测'。")
        sys.exit(1)
    print(">>> 全部通过:稿中数字均可溯源到 ledger。")

if __name__ == "__main__":
    main()
