from pathlib import Path
import re

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

pattern = r"GVL_STATE\.G_Floor_Temp"
matches = re.findall(pattern, text)
count_before = len(matches)

if count_before == 0:
    raise SystemExit("No GVL_STATE.G_Floor_Temp occurrences found in PRG_System.st")

text = re.sub(pattern, "L_FloorTemps_8[1]", text)

count_after = len(re.findall(pattern, text))
path.write_text(text, encoding="utf-8")

print(f"count_before={count_before}")
print(f"count_after={count_after}")
print("OK: replaced all GVL_STATE.G_Floor_Temp occurrences with L_FloorTemps_8[1]")
