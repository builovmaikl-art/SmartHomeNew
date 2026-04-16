from pathlib import Path

path = Path("FB_Ventilation_System_Manager.st")
text = path.read_text(encoding="utf-8")

old = """// Ventilation V2 shadow runtime integration (diagnostic only)
fbVentilationV2Staging(
    VI_Zone_ID := 1,
    VI_Enable := (NOT L_Policy_Safe_Stop) AND (NOT L_Policy_Freeze_Protection) AND (NOT GVL_STATE.G_Ventilation_IO_Fault),
    VI_Fan_Speed_Setpoint := BYTE_TO_REAL(VO_Supply_Fans[1]),
    VI_Damper_Position_Setpoint := 0.0,
    VI_Heat_Recovery_Enabled := L_Policy_Normal,
    VI_Is_Active := (VO_Supply_Fans[1] > 0) OR (VO_Exhaust_Fans[1] > 0),
    VI_Fan_Speed_Actual := BYTE_TO_REAL(VO_Supply_Fans[1]),
    VI_Supply_Temp := VI_Supply_Temps[1],
    VI_Extract_Temp := VI_Room_Temps[1],
    VI_Filter_Dirty := FALSE,
    VI_Alarm_Active := GVL_STATE.G_Ventilation_IO_Fault OR GVL_STATE.G_Ventilation_Subsystem_Degraded,
    VO_Command_Shadow => L_Vent_Command_Shadow,
    VO_State_Shadow => L_Vent_State_Shadow
);
"""

new = """// Ventilation V2 shadow runtime integration (diagnostic only)
// Inlined from FB_Ventilation_V2_Staging
L_Vent_Command_Shadow.Fan_Speed_Setpoint := BYTE_TO_REAL(VO_Supply_Fans[1]);
L_Vent_State_Shadow.Supply_Temp := VI_Supply_Temps[1];
"""

if old not in text:
    raise SystemExit("Ventilation V2 staging call block not found")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: inlined ventilation V2 staging logic into FB_Ventilation_System_Manager.st")
