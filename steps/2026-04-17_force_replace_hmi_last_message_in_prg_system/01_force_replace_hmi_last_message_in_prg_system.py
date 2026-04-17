from pathlib import Path
import re

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

pattern = r"GVL_STATUS\.G_Diagnostics\.HMI_Last_Message"
matches = re.findall(pattern, text)
count_before = len(matches)

if count_before == 0:
    raise SystemExit("No HMI_Last_Message references found in PRG_System.st")

text = re.sub(
    pattern,
    "GVL_GATEWAY.G_Gateway_HMI_Status_Message",
    text
)

count_after = len(re.findall(pattern, text))
path.write_text(text, encoding="utf-8")

print(f"count_before={count_before}")
print(f"count_after={count_after}")
print("OK: replaced all PRG_System HMI_Last_Message references with gateway status channel")
