from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

# 1) add vars into main VAR section if missing
anchor = "L_Snapshot_Recovery_Prev : BOOL;"
insert = """L_Snapshot_Recovery_Prev : BOOL;
L_Snapshot_Last_Event_MS : UDINT;
L_Snapshot_Min_Interval_MS : UDINT;"""

if "L_Snapshot_Last_Event_MS : UDINT;" not in text:
    if anchor not in text:
        raise SystemExit("Anchor for snapshot debounce vars not found")
    text = text.replace(anchor, insert, 1)

old = """// === SNAPSHOT MULTI EVENT TRIGGER ===

// rate alert
IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active AND (NOT L_Snapshot_Trigger_Prev) THEN
    fbSnapshotMgr(
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
        VI_Trigger_Event  := TRUE,
        VI_Event_Code     := WORD#1,
        VI_Current_State  := L_Snapshot
    );
END_IF;

// fallback spike
IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Fallback_Per_Hour > 10.0 AND (NOT L_Snapshot_Fallback_Prev) THEN
    fbSnapshotMgr(
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
        VI_Trigger_Event  := TRUE,
        VI_Event_Code     := WORD#2,
        VI_Current_State  := L_Snapshot
    );
END_IF;

// recovery spike
IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Recovery_Per_Hour > 10.0 AND (NOT L_Snapshot_Recovery_Prev) THEN
    fbSnapshotMgr(
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
        VI_Trigger_Event  := TRUE,
        VI_Event_Code     := WORD#3,
        VI_Current_State  := L_Snapshot
    );
END_IF;

// update prev
L_Snapshot_Trigger_Prev := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active;
L_Snapshot_Fallback_Prev := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Fallback_Per_Hour > 10.0;
L_Snapshot_Recovery_Prev := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Recovery_Per_Hour > 10.0;"""

new = """// === SNAPSHOT MULTI EVENT TRIGGER ===
IF L_Snapshot_Min_Interval_MS = 0 THEN
    L_Snapshot_Min_Interval_MS := 5000;
END_IF;

// rate alert
IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active AND
   (NOT L_Snapshot_Trigger_Prev) AND
   ((L_Snapshot_Last_Event_MS = 0) OR
    ((GVL_STATUS.G_System_Time_MS - L_Snapshot_Last_Event_MS) >= L_Snapshot_Min_Interval_MS)) THEN
    fbSnapshotMgr(
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
        VI_Trigger_Event  := TRUE,
        VI_Event_Code     := WORD#1,
        VI_Current_State  := L_Snapshot
    );
    L_Snapshot_Last_Event_MS := GVL_STATUS.G_System_Time_MS;
END_IF;

// fallback spike
IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Fallback_Per_Hour > 10.0 AND
   (NOT L_Snapshot_Fallback_Prev) AND
   ((L_Snapshot_Last_Event_MS = 0) OR
    ((GVL_STATUS.G_System_Time_MS - L_Snapshot_Last_Event_MS) >= L_Snapshot_Min_Interval_MS)) THEN
    fbSnapshotMgr(
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
        VI_Trigger_Event  := TRUE,
        VI_Event_Code     := WORD#2,
        VI_Current_State  := L_Snapshot
    );
    L_Snapshot_Last_Event_MS := GVL_STATUS.G_System_Time_MS;
END_IF;

// recovery spike
IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Recovery_Per_Hour > 10.0 AND
   (NOT L_Snapshot_Recovery_Prev) AND
   ((L_Snapshot_Last_Event_MS = 0) OR
    ((GVL_STATUS.G_System_Time_MS - L_Snapshot_Last_Event_MS) >= L_Snapshot_Min_Interval_MS)) THEN
    fbSnapshotMgr(
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
        VI_Trigger_Event  := TRUE,
        VI_Event_Code     := WORD#3,
        VI_Current_State  := L_Snapshot
    );
    L_Snapshot_Last_Event_MS := GVL_STATUS.G_System_Time_MS;
END_IF;

// update prev
L_Snapshot_Trigger_Prev := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active;
L_Snapshot_Fallback_Prev := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Fallback_Per_Hour > 10.0;
L_Snapshot_Recovery_Prev := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Recovery_Per_Hour > 10.0;"""

if old not in text:
    raise SystemExit("Expected snapshot multi-event block not found exactly")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: snapshot debounce inserted")
