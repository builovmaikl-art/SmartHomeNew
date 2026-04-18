from pathlib import Path
import re

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

# ------------------------------------------------------------
# 1) Ensure VARs exist in main VAR section
# ------------------------------------------------------------
var_anchor = "L_Snapshot_Trigger_Prev : BOOL;"
if var_anchor not in text:
    raise SystemExit("VAR anchor L_Snapshot_Trigger_Prev not found in PRG_System.st")

needed = [
    "L_Snapshot_Event_Trigger : BOOL;",
    "L_Snapshot_Event_Code : WORD;",
    "L_Snapshot_Fallback_Count_Prev : UDINT;",
    "L_Snapshot_Recovery_Count_Prev : UDINT;",
]

if not all(v in text for v in needed):
    insert = var_anchor + "\n" + "\n".join(needed)
    text = text.replace(var_anchor, insert, 1)

# ------------------------------------------------------------
# 2) Replace snapshot trigger block robustly
#    We replace from fbSnapshotMgr( ... ); through the single trailing
#    L_Snapshot_Trigger_Prev := ...;
# ------------------------------------------------------------
pattern = re.compile(
    r"fbSnapshotMgr\(\n"
    r"(?:.*\n)*?"
    r"\);\n\n"
    r"L_Snapshot_Trigger_Prev := GVL_STATUS\.G_Diagnostics\.Sensor_Shadow_Rate_Alert_Active;",
    re.DOTALL
)

replacement = """// snapshot trigger arbitration: one snapshot max per cycle
L_Snapshot_Event_Trigger := FALSE;
L_Snapshot_Event_Code := WORD#0;

// priority 1: rate alert edge
IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active AND (NOT L_Snapshot_Trigger_Prev) THEN
    L_Snapshot_Event_Trigger := TRUE;
    L_Snapshot_Event_Code := WORD#1;

// priority 2: any fallback counter increment
ELSIF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count <> L_Snapshot_Fallback_Count_Prev THEN
    L_Snapshot_Event_Trigger := TRUE;
    L_Snapshot_Event_Code := WORD#2;

// priority 3: any recovery counter increment
ELSIF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count <> L_Snapshot_Recovery_Count_Prev THEN
    L_Snapshot_Event_Trigger := TRUE;
    L_Snapshot_Event_Code := WORD#3;
END_IF;

fbSnapshotMgr(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Trigger_Event  := L_Snapshot_Event_Trigger,
    VI_Event_Code     := L_Snapshot_Event_Code,
    VI_Current_State  := L_Snapshot
);

L_Snapshot_Trigger_Prev := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active;
L_Snapshot_Fallback_Count_Prev := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count;
L_Snapshot_Recovery_Count_Prev := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count;"""

new_text, count = pattern.subn(replacement, text, count=1)
if count != 1:
    raise SystemExit("Snapshot trigger block replacement failed: expected exactly 1 match")

path.write_text(new_text, encoding="utf-8")
print("OK: snapshot multi-event trigger block updated")
