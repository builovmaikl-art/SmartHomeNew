from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

lines = text.splitlines()

targets = {
    "    L_Trend_Avg : REAL;",
    "    L_Trend_Min : REAL;",
    "    L_Trend_Max : REAL;",
    "    L_Trend_Up : BOOL;",
    "    L_Trend_Down : BOOL;",
}

seen = {t: 0 for t in targets}
out = []

for line in lines:
    if line in targets:
        seen[line] += 1
        if seen[line] > 1:
            continue
    out.append(line)

path.write_text("\n".join(out) + "\n", encoding="utf-8")

for k, v in seen.items():
    print(f"{k} -> kept={1 if v else 0}, found={v}")
print("OK: duplicate trend vars removed from PRG_System")
