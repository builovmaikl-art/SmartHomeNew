from pathlib import Path

path = Path("FB_DHW_Manager.st")
text = path.read_text(encoding="utf-8")

old = """// ========================================
// DHW V2 staging execution
// ========================================
fbDHWV2Staging(
    VI_Tank_ID := 1,
    VI_Enable := TRUE,
    VI_Target_Temp := VI_Config.Target_Temp,
    VI_Pump_Enable := VO_Heating_Pump,
    VI_Heating_Priority := FALSE,

    VI_Is_Active := VO_Heating_Pump,
    VI_Tank_Temp := VO_Status.Temp,
    VI_Supply_Temp := VO_Status.Pressure,
    VI_Return_Temp := VO_Status.Temp,
    VI_Pump_Actual := VO_Heating_Pump,
    VI_Alarm_Active := VO_Status.Error,

    VO_Command_Shadow => L_DHW_V2_Command_V2,
    VO_State_Shadow => L_DHW_V2_State_V2
);
"""

new = """// ========================================
// DHW V2 shadow execution (phase2)
// Inlined from FB_DHW_V2_Staging
// ========================================
IF VO_Heating_Pump THEN
    L_DHW_V2_Command_V2.Pump_Enable := 1.0;
ELSE
    L_DHW_V2_Command_V2.Pump_Enable := 0.0;
END_IF;

L_DHW_V2_State_V2.Tank_Temp := VO_Status.Temp;
L_DHW_V2_State_V2.Supply_Temp := VO_Status.Pressure;
"""

if old not in text:
    raise SystemExit("DHW V2 staging call block not found")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: inlined DHW V2 staging logic into FB_DHW_Manager.st")
