from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

# ------------------------------------------------------------
# 1) Add vars to main VAR section
# ------------------------------------------------------------
anchor = "L_Snapshot_Trigger_Prev : BOOL;"
vars_to_add = """L_Snapshot_Trigger_Prev : BOOL;
L_Snapshot_Event_Trigger : BOOL;
L_Snapshot_Event_Code : WORD;
L_Snapshot_Fallback_Count_Prev : UDINT;
L_Snapshot_Recovery_Count_Prev : UDINT;"""

if "L_Snapshot_Event_Trigger : BOOL;" not in text:
    if anchor not in text:
        raise SystemExit("Anchor for snapshot multi-event vars not found")
    text = text.replace(anchor, vars_to_add, 1)

# ------------------------------------------------------------
# 2) Replace current rising-edge trigger block
# ------------------------------------------------------------
old = """fbSnapshotMgr(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Trigger_Event  := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active AND (NOT L_Snapshot_Trigger_Prev),
    VI_Event_Code     := WORD#1,
    VI_Current_State  := L_Snapshot
);

L_Snapshot_Trigger_Prev := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active;"""

new = """// snapshot trigger arbitration: one snapshot max per cycle
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

if old not in text:
    raise SystemExit("Current snapshot trigger block not found exactly")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: snapshot multi-event trigger added")
