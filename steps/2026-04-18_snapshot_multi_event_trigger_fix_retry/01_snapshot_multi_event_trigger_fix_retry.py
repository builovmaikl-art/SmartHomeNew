from pathlib import Path
import re

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

anchor = "L_Snapshot_Trigger_Prev : BOOL;"
needed = [
    "L_Snapshot_Event_Trigger : BOOL;",
    "L_Snapshot_Event_Code : WORD;",
    "L_Snapshot_Fallback_Count_Prev : UDINT;",
    "L_Snapshot_Recovery_Count_Prev : UDINT;",
]

if anchor not in text:
    raise SystemExit("Anchor L_Snapshot_Trigger_Prev : BOOL; not found")

for v in needed:
    if v not in text:
        text = text.replace(anchor, anchor + "\n" + v, 1)
        anchor = v

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

IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active AND (NOT L_Snapshot_Trigger_Prev) THEN
    L_Snapshot_Event_Trigger := TRUE;
    L_Snapshot_Event_Code := WORD#1;
ELSIF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count <> L_Snapshot_Fallback_Count_Prev THEN
    L_Snapshot_Event_Trigger := TRUE;
    L_Snapshot_Event_Code := WORD#2;
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
    raise SystemExit(f"Snapshot trigger block replacement failed, matches={count}")

path.write_text(new_text, encoding="utf-8")
print("OK: snapshot multi-event trigger block updated")
