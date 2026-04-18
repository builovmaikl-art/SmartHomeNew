from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

# 1) add prev-state trigger variable into main VAR section
anchor = "L_Snapshot : ST_State_Snapshot;"
if "L_Snapshot_Trigger_Prev : BOOL;" not in text:
    if anchor not in text:
        raise SystemExit("Anchor for snapshot trigger prev not found in PRG_System.st")
    text = text.replace(anchor, anchor + "\nL_Snapshot_Trigger_Prev : BOOL;", 1)

old = """fbSnapshotMgr(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Trigger_Event  := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active,
    VI_Event_Code     := WORD#1,
    VI_Current_State  := L_Snapshot
);"""

new = """fbSnapshotMgr(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Trigger_Event  := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active AND (NOT L_Snapshot_Trigger_Prev),
    VI_Event_Code     := WORD#1,
    VI_Current_State  := L_Snapshot
);

L_Snapshot_Trigger_Prev := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active;"""

if old not in text:
    raise SystemExit("Snapshot manager call not found exactly in PRG_System.st")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: refined snapshot trigger to rising-edge behavior")
