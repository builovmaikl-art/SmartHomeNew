from pathlib import Path

path = Path('PRG_Safety.st')
text = path.read_text(encoding='utf-8')

replacements = {
    """IF GVL_STATE.G_Safety_Smoke_Latched THEN
    GVL_INTENT_SAFETY.I_System_Safe_Stop_Required := TRUE;
    GVL_INTENT_SAFETY.I_Evacuation_Mode_Active := TRUE;
    GVL_INTENT_SAFETY.I_Boiler_Stop_Required := TRUE;
    GVL_INTENT_SAFETY.I_Vent_Stop_Required := TRUE;
    GVL_INTENT_SAFETY.I_Lock_1_Force_Open := TRUE;
    GVL_INTENT_SAFETY.I_Lock_1_Force_Close_Block := TRUE;
    GVL_INTENT_SAFETY.I_Lock_2_Force_Open := TRUE;
    GVL_INTENT_SAFETY.I_Lock_2_Force_Close_Block := TRUE;
    GVL_COMMAND.G_Boiler_Stop := TRUE;
    GVL_COMMAND.G_Vent_Stop := TRUE;
    GVL_COMMAND.G_Supply_100_Req := FALSE;
    GVL_COMMAND.G_Supply_80_Req := FALSE;
    GVL_COMMAND.G_Vent_PV3_Boost := FALSE;
    GVL_COMMAND.G_Exhaust_100_Req := FALSE;
    GVL_COMMAND.G_Lock_1_Open := TRUE;
    GVL_COMMAND.G_Lock_1_Close := FALSE;
    GVL_COMMAND.G_Lock_2_Open := TRUE;
    GVL_COMMAND.G_Lock_2_Close := FALSE;
END_IF;""":
    """IF GVL_STATE.G_Safety_Smoke_Latched THEN
    GVL_INTENT_SAFETY.I_System_Safe_Stop_Required := TRUE;
    GVL_INTENT_SAFETY.I_Evacuation_Mode_Active := TRUE;
    GVL_INTENT_SAFETY.I_Boiler_Stop_Required := TRUE;
    GVL_INTENT_SAFETY.I_Vent_Stop_Required := TRUE;
    GVL_INTENT_SAFETY.I_Lock_1_Force_Open := TRUE;
    GVL_INTENT_SAFETY.I_Lock_1_Force_Close_Block := TRUE;
    GVL_INTENT_SAFETY.I_Lock_2_Force_Open := TRUE;
    GVL_INTENT_SAFETY.I_Lock_2_Force_Close_Block := TRUE;
END_IF;""",

    """IF GVL_STATE.G_Safety_Gas_Latched THEN
    GVL_INTENT_SAFETY.I_System_Safe_Stop_Required := TRUE;
    GVL_INTENT_SAFETY.I_Gas_Close_Required := TRUE;
    GVL_INTENT_SAFETY.I_Boiler_Stop_Required := TRUE;
    GVL_COMMAND.G_Gas_Valve_Close := TRUE;
    GVL_COMMAND.G_Boiler_Stop := TRUE;
END_IF;""":
    """IF GVL_STATE.G_Safety_Gas_Latched THEN
    GVL_INTENT_SAFETY.I_System_Safe_Stop_Required := TRUE;
    GVL_INTENT_SAFETY.I_Gas_Close_Required := TRUE;
    GVL_INTENT_SAFETY.I_Boiler_Stop_Required := TRUE;
END_IF;""",

    """IF GVL_STATE.G_Safety_Leak_Latched THEN
    GVL_INTENT_SAFETY.I_Water_Main_Close_Required := TRUE;
    GVL_COMMAND.G_Close_Valve_35 := TRUE;
    GVL_COMMAND.G_Close_Valve_36 := TRUE;
END_IF;""":
    """IF GVL_STATE.G_Safety_Leak_Latched THEN
    GVL_INTENT_SAFETY.I_Water_Main_Close_Required := TRUE;
END_IF;""",

    """IF GVL_STATE.G_Safety_Gas_Latched THEN
    GVL_INTENT_SAFETY.I_Vent_Force_PV3_Boost := TRUE;
    GVL_INTENT_SAFETY.I_Vent_Force_Supply_100 := TRUE;
    GVL_COMMAND.G_Vent_PV3_Boost := TRUE;
    GVL_COMMAND.G_Supply_100_Req := TRUE;
END_IF;""":
    """IF GVL_STATE.G_Safety_Gas_Latched THEN
    GVL_INTENT_SAFETY.I_Vent_Force_PV3_Boost := TRUE;
    GVL_INTENT_SAFETY.I_Vent_Force_Supply_100 := TRUE;
END_IF;""",

    """IF GVL_HEALTH_BRIDGE.G_CO_Warning_Level OR GVL_HEALTH_BRIDGE.G_CO_Alarm_Level THEN
    GVL_INTENT_SAFETY.I_Vent_Force_Supply_80 := TRUE;
    GVL_COMMAND.G_Supply_80_Req := TRUE;
END_IF;""":
    """IF GVL_HEALTH_BRIDGE.G_CO_Warning_Level OR GVL_HEALTH_BRIDGE.G_CO_Alarm_Level THEN
    GVL_INTENT_SAFETY.I_Vent_Force_Supply_80 := TRUE;
END_IF;""",
}

for old, new in replacements.items():
    if old not in text:
        raise SystemExit('Expected block not found during cleanup')
    text = text.replace(old, new, 1)

path.write_text(text, encoding='utf-8')
print('OK: removed core legacy GVL_COMMAND actuator writes from PRG_Safety')
