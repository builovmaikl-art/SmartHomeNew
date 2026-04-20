#!/usr/bin/env python3
from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

anchor = "GVL_STATE.G_System_Mode := GVL_PERSISTENT.P_System_Mode;"

if anchor not in text:
    raise SystemExit("Recovery anchor not found")

replacement = anchor + """

    // restore DHW pump state (symmetry with persist builder)
    GVL_STATE.G_DHW_Heating_Pump := GVL_PERSISTENT.P_DHW_Heating_Active;
"""

text = text.replace(anchor, replacement, 1)
path.write_text(text, encoding="utf-8")

print("OK: added DHW recovery for persistence symmetry")
