from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

# 1) add snapshot temp variable into main VAR section
anchor = "L_Window_Hours : REAL;"
if "L_Snapshot : ST_State_Snapshot;" not in text:
    if anchor not in text:
        raise SystemExit("Main VAR anchor not found for L_Snapshot insertion")
    text = text.replace(anchor, anchor + "\nL_Snapshot : ST_State_Snapshot;", 1)

# 2) replace broken snapshot block with exact safe block
old = """// === SNAPSHOT LAYER (PHASE 1) ===
VAR
    L_Snapshot : ST_State_Snapshot;
END_VAR

// заполнение snapshot
L_Snapshot.timestamp_ms := GVL_SYSTEM.G_System_Time;
L_Snapshot.trigger_event_code := 0;

// минимальный набор
L_Snapshot.shadow_alert_active :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active;

L_Snapshot.shadow_dominant_channel :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Dominant_Channel;

L_Snapshot.total_fallback :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count;

L_Snapshot.total_recovery :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count;

// trigger (пока простой)
fbSnapshotMgr(
    VI_System_Time_MS := GVL_SYSTEM.G_System_Time,
    VI_Trigger_Event  := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active,
    VI_Event_Code     := WORD#1,
    VI_Current_State  := L_Snapshot
);
"""

new = """// === SNAPSHOT LAYER (PHASE 1) ===
// safe in-memory snapshot using real ST_State_Snapshot fields
L_Snapshot.timestamp_ms := GVL_STATUS.G_System_Time_MS;
L_Snapshot.operator_id := 'SYSTEM';
L_Snapshot.scenario_id := GVL_STATUS.G_Current_Scenario;
L_Snapshot.lighting_levels := GVL_STATE.G_Lighting_Levels;
L_Snapshot.floor_heating_setpoints := GVL_CONFIG.G_HMI_Heating_Setpoints;
L_Snapshot.alarm_active := GVL_ALARM.G_Global_Critical OR GVL_ALARM.G_Global_Warning;
L_Snapshot.crc32 := DWORD#0;

fbSnapshotMgr(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Trigger_Event  := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active,
    VI_Event_Code     := WORD#1,
    VI_Current_State  := L_Snapshot
);
"""

if old not in text:
    raise SystemExit("Broken snapshot block not found exactly in PRG_System.st")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: snapshot layer phase1 fixed to real ST_State_Snapshot fields")
