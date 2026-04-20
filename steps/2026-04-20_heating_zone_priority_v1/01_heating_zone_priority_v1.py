from pathlib import Path
import re

p = Path("FB_Heating_System_Manager.st")
text = p.read_text(encoding="utf-8")

# -----------------------------
# 1. Add priority weight logic inside loop
# -----------------------------
pattern = r"(L_Adaptive_Weight\s*:=\s*[^;]+;)"

replacement = r"""\1

        // --- ZONE PRIORITY WEIGHT ---
        IF VI_Zone_Configs[L_Adaptive_Zone_i].zone >= 1 AND VI_Zone_Configs[L_Adaptive_Zone_i].zone <= 4 THEN
            L_Adaptive_Weight := L_Adaptive_Weight * 1.2;
        ELSIF VI_Zone_Configs[L_Adaptive_Zone_i].zone >= 9 THEN
            L_Adaptive_Weight := L_Adaptive_Weight * 0.7;
        END_IF;"""

new_text, count = re.subn(pattern, replacement, text, count=1)

if count != 1:
    raise SystemExit(f"Expected exactly 1 weight insertion, got {count}")

text = new_text

# -----------------------------
# 2. Optional safety clamp for weight
# -----------------------------
if "L_Adaptive_Weight > 2.0" not in text:
    clamp_block = """

        // --- WEIGHT CLAMP ---
        IF L_Adaptive_Weight > 2.0 THEN
            L_Adaptive_Weight := 2.0;
        ELSIF L_Adaptive_Weight < 0.2 THEN
            L_Adaptive_Weight := 0.2;
        END_IF;"""

    text = text.replace("L_Adaptive_Weight_Total := L_Adaptive_Weight_Total + L_Adaptive_Weight;", clamp_block + "\n        L_Adaptive_Weight_Total := L_Adaptive_Weight_Total + L_Adaptive_Weight;", 1)

p.write_text(text, encoding="utf-8")

print("OK: zone priority weighting applied")
