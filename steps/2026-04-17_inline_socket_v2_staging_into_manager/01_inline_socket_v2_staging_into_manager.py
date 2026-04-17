from pathlib import Path

path = Path("FB_Socket_Manager.st")
text = path.read_text(encoding="utf-8")

old = """// ========================================
// Socket V2 shadow execution (phase2)
// ========================================
fbSocketV2Staging(
    VI_Socket_ID := 1,
    VI_Enable := TRUE,
    VI_Target_State := VO_Socket_States[1],
    VI_Manual_Override := VI_Manual_Override[1],
    VI_Safety_Lock := (VI_Fire_Alarm OR VI_Flood_Alarm),
    VI_Scenario_ID := TO_INT(VI_Scenario),

    VI_Is_On := VO_Socket_States[1],
    VI_Manual_Override_Active := VI_Manual_Override[1],
    VI_Safety_Blocked := (VI_Fire_Alarm OR VI_Flood_Alarm),
    VI_Alarm_Active := (VI_Fire_Alarm OR VI_Flood_Alarm),

    VO_Command_Shadow => L_Socket_V2_Command_Shadow,
    VO_State_Shadow => L_Socket_V2_State_Shadow
);
"""

new = """// ========================================
// Socket V2 shadow execution (phase2)
// Inlined from FB_Socket_V2_Staging
// ========================================
L_Socket_V2_Command_Shadow.Target_State := VO_Socket_States[1];
L_Socket_V2_State_Shadow.Is_On := VO_Socket_States[1];
L_Socket_V2_State_Shadow.Safety_Blocked := (VI_Fire_Alarm OR VI_Flood_Alarm);
"""

if old not in text:
    raise SystemExit("Socket V2 staging call block not found")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: inlined socket V2 staging logic into FB_Socket_Manager.st")
