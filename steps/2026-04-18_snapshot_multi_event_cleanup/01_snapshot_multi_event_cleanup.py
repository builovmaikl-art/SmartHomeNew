from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

bad = """// === SNAPSHOT MULTI EVENT TRIGGER ===

// rate alert
IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active AND (NOT L_Snapshot_Trigger_Prev) THEN
    // === SNAPSHOT MULTI EVENT (SAFE ADD) ===
L_Snapshot_Event_Trigger := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active AND (NOT L_Snapshot_Trigger_Prev);
L_Snapshot_Event_Code := WORD#1;

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
L_Snapshot_Recovery_Prev := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Recovery_Per_Hour > 10.0;
"""

good = """// === SNAPSHOT MULTI EVENT TRIGGER ===

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
L_Snapshot_Recovery_Prev := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Recovery_Per_Hour > 10.0;
"""

if bad not in text:
    raise SystemExit("Expected broken snapshot multi-event block not found exactly")

text = text.replace(bad, good, 1)

# defensive cleanup in case half-applied remnants remain elsewhere
text = text.replace("L_Snapshot_Event_Trigger := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active AND (NOT L_Snapshot_Trigger_Prev);\n", "")
text = text.replace("L_Snapshot_Event_Code := WORD#1;\n", "")
text = text.replace("    // === SNAPSHOT MULTI EVENT (SAFE ADD) ===\n", "")
text = text.replace("// === SNAPSHOT MULTI EVENT (SAFE ADD) ===\n", "")

path.write_text(text, encoding="utf-8")
print("OK: cleaned broken safe-add insertion and restored valid snapshot multi-event block")
