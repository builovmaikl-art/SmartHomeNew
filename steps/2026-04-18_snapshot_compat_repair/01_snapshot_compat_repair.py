from pathlib import Path

# -----------------------------
# 1) Fix PRG_System.st
# -----------------------------
prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

# 1a. Ensure main VAR contains L_Snapshot
anchor = "L_Window_Hours : REAL;"
if "L_Snapshot : ST_State_Snapshot;" not in text:
    if anchor not in text:
        raise SystemExit("Anchor for L_Snapshot declaration not found in PRG_System.st")
    text = text.replace(anchor, anchor + "\nL_Snapshot : ST_State_Snapshot;", 1)

old_block = """// === SNAPSHOT LAYER (PHASE 1) ===
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

new_block = """// === SNAPSHOT LAYER (PHASE 1) ===
// safe in-memory snapshot using real ST_State_Snapshot fields
L_Snapshot.timestamp_ms := GVL_STATUS.G_System_Time_MS;
L_Snapshot.operator_id := 'SYSTEM';
L_Snapshot.scenario_id := GVL_STATUS.G_Current_Scenario;
L_Snapshot.lighting_levels := GVL_STATE.G_Lighting_Levels;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    L_Snapshot.floor_heating_setpoints[L_i] := GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].design_temp;
END_FOR;

L_Snapshot.alarm_active := GVL_ALARM.G_Global_Critical OR GVL_ALARM.G_Global_Warning;
L_Snapshot.crc32 := DWORD#0;

fbSnapshotMgr(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Trigger_Event  := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active,
    VI_Event_Code     := WORD#1,
    VI_Current_State  := L_Snapshot
);
"""

if old_block not in text:
    raise SystemExit("Expected snapshot block not found exactly in PRG_System.st")

text = text.replace(old_block, new_block, 1)
prg.write_text(text, encoding="utf-8")

# -----------------------------
# 2) Fix FB_State_Snapshot_Manager.st
# -----------------------------
fb = Path("FB_State_Snapshot_Manager.st")
fb_text = fb.read_text(encoding="utf-8")

old_mgr = """IF VI_Trigger_Event THEN
    L_Snapshot_Buffer[L_Write_Idx] := VI_Current_State;
    L_Snapshot_Buffer[L_Write_Idx].timestamp_ms := VI_System_Time_MS;
    L_Snapshot_Buffer[L_Write_Idx].trigger_event_code := VI_Event_Code;
    
    L_Write_Idx := (L_Write_Idx MOD GVL_CONSTANTS.C_MAX_STATE_SNAPSHOTS) + 1;
    VO_Snapshot_Saved := TRUE;
ELSE
    VO_Snapshot_Saved := FALSE;
END_IF;"""

new_mgr = """IF VI_Trigger_Event THEN
    L_Snapshot_Buffer[L_Write_Idx] := VI_Current_State;
    L_Snapshot_Buffer[L_Write_Idx].timestamp_ms := VI_System_Time_MS;
    
    // NOTE:
    // ST_State_Snapshot no longer contains trigger_event_code in live project.
    // VI_Event_Code is reserved for future snapshot metadata extension.
    
    L_Write_Idx := (L_Write_Idx MOD GVL_CONSTANTS.C_MAX_STATE_SNAPSHOTS) + 1;
    VO_Snapshot_Saved := TRUE;
ELSE
    VO_Snapshot_Saved := FALSE;
END_IF;"""

if old_mgr not in fb_text:
    raise SystemExit("Expected body not found exactly in FB_State_Snapshot_Manager.st")

fb_text = fb_text.replace(old_mgr, new_mgr, 1)
fb.write_text(fb_text, encoding="utf-8")

print("OK: repaired snapshot compatibility in PRG_System and FB_State_Snapshot_Manager")
