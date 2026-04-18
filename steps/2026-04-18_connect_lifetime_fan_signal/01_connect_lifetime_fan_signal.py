from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

old = "    VI_Device_Active  := FALSE,\n    VI_Device_ID      := GVL_Lifetime.G_Device_Fan,\n"

new = """    VI_Device_Active  := (
        GVL_STATE.G_Supply_Fans[1] > 0 OR
        GVL_STATE.G_Exhaust_Fans[1] > 0
    ),
    VI_Device_ID      := GVL_Lifetime.G_Device_Fan,
"""

if old not in text:
    raise SystemExit("Fan lifetime call pattern not found")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")

print("OK: connected fan lifetime to real ventilation activity")
