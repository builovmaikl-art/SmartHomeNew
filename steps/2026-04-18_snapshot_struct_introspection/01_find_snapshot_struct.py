from pathlib import Path

ROOT = Path(".")

targets = []

for p in ROOT.rglob("*.st"):
    try:
        text = p.read_text(encoding="utf-8", errors="ignore")
    except:
        continue

    if "ST_State_Snapshot" in text:
        targets.append(p)

print("=== FILES WITH ST_State_Snapshot ===")
for t in targets:
    print(t)

print("\n=== STRUCT DEFINITIONS ===\n")

for t in targets:
    text = t.read_text(encoding="utf-8", errors="ignore")
    lines = text.splitlines()

    for i, l in enumerate(lines):
        if "TYPE ST_State_Snapshot" in l:
            print(f"\n--- {t} ---")
            for j in range(i, min(i+120, len(lines))):
                print(lines[j])
