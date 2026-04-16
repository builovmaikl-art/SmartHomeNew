from pathlib import Path

path = Path("FB_Lighting_Blinds_Manager.st")
text = path.read_text(encoding="utf-8")

old = """// ========================================
// Lighting V2 shadow execution (phase2)
// ========================================
fbLightingV2Staging(
    VI_Zone_ID := 1,
    VI_Enable := (VO_Lighting_Levels[1] > 0),
    VI_Brightness_Setpoint := BYTE_TO_REAL(VO_Lighting_Levels[1]),
    VI_Scene_ID := TO_INT(L_Effective_Scenario),
    VI_Manual_Override := (VI_Manual_Light_Override[1] > 0),
    VI_Transition_Time_MS := 5000,

    VI_Is_Active := (VO_Lighting_Levels[1] > 0),
    VI_Brightness_Actual := BYTE_TO_REAL(VO_Lighting_Levels[1]),
    VI_Motion_Active := VI_Motion_Sensors[1],
    VI_Ambient_Lux := 0.0,
    VI_Alarm_Active := GVL_STATE.G_Lighting_IO_Fault OR GVL_STATE.G_Lighting_Subsystem_Degraded,

    VO_Command_Shadow => L_Lighting_V2_Command_Shadow,
    VO_State_Shadow => L_Lighting_V2_State_Shadow
);
"""

new = """// ========================================
// Lighting V2 shadow execution (phase2)
// Inlined from FB_Lighting_V2_Staging
// ========================================
L_Lighting_V2_Command_Shadow.Brightness_Setpoint := BYTE_TO_REAL(VO_Lighting_Levels[1]);
L_Lighting_V2_State_Shadow.Brightness_Actual := BYTE_TO_REAL(VO_Lighting_Levels[1]);
L_Lighting_V2_State_Shadow.Motion_Active := VI_Motion_Sensors[1];
"""

if old not in text:
    raise SystemExit("Lighting V2 staging call block not found")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: inlined lighting V2 staging logic into FB_Lighting_Blinds_Manager.st")
