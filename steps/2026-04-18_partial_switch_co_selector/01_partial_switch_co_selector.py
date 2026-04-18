from pathlib import Path
import re

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

# ------------------------------------------------------------
# Find Gas_Smoke_Manager call and replace only CO input
# ------------------------------------------------------------

pattern = re.compile(
    r"(VI_CO_.*?:=\s*)(GVL_STATE\.G_CO_Sensors\[1\])",
    re.MULTILINE
)

if not pattern.search(text):
    raise SystemExit("CO input pattern not found in Gas_Smoke_Manager call")

text = pattern.sub(
    r"\1GVL_Safety_Selector.G_CO_Effective",
    text,
    count=1
)

path.write_text(text, encoding="utf-8")

print("OK: switched CO input to selector")
