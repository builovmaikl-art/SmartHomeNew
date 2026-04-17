from pathlib import Path

path = Path("FB_Lighting_Blinds_Manager.st")
text = path.read_text(encoding="utf-8")

old = """// ========================================
// Blinds V2 shadow execution (phase2)
// ========================================
fbBlindsV2Staging(
    VI_Blind_ID := 1,
    VI_Enable := TRUE,
    VI_Position_Setpoint := VO_Blinds_Positions[1],
    VI_Manual_Override := (VI_Manual_Blinds_Override[1] > 0),
    VI_Scenario_ID := TO_INT(L_Effective_Scenario),
    VI_Safety_Mode := FALSE,

    VI_Position_Actual := VO_Blinds_Positions[1],
    VI_Manual_Override_Active := (VI_Manual_Blinds_Override[1] > 0),
    VI_Is_Moving := FALSE,
    VI_Alarm_Active := GVL_STATE.G_Lighting_IO_Fault,

    VO_Command_Shadow => L_Blinds_V2_Command_Shadow,
    VO_State_Shadow => L_Blinds_V2_State_Shadow
);
"""

new = """// ========================================
// Blinds V2 shadow execution (phase2)
// Inlined from FB_Blinds_V2_Staging
// ========================================
L_Blinds_V2_Command_Shadow.Position_Setpoint := VO_Blinds_Positions[1];
L_Blinds_V2_State_Shadow.Position_Actual := VO_Blinds_Positions[1];
"""

if old not in text:
    raise SystemExit("Blinds V2 staging call block not found")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: inlined blinds V2 staging logic into FB_Lighting_Blinds_Manager.st")
