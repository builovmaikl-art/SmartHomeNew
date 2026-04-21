from pathlib import Path

path = Path('PRG_Safety.st')
text = path.read_text(encoding='utf-8')

anchor = "// 7.5 Система защиты от протечек\n"
insert = """// === STAGE A: PARALLEL SAFETY INTENT RESET/PUBLISH ===
// During migration, PRG_Safety keeps legacy writes to GVL_COMMAND but also
// publishes equivalent safety constraints into GVL_INTENT_SAFETY.
GVL_INTENT_SAFETY.I_Source_Valid := TRUE;
GVL_INTENT_SAFETY.I_Last_Update_MS := GVL_STATUS.G_System_Time_MS;
GVL_INTENT_SAFETY.I_Fire_Alarm_Active := FALSE;
GVL_INTENT_SAFETY.I_Gas_Alarm_Active := FALSE;
GVL_INTENT_SAFETY.I_Leak_Alarm_Active := FALSE;
GVL_INTENT_SAFETY.I_CO_Warning_Active := FALSE;
GVL_INTENT_SAFETY.I_System_Safe_Stop_Required := FALSE;
GVL_INTENT_SAFETY.I_Freeze_Protection_Required := FALSE;
GVL_INTENT_SAFETY.I_Evacuation_Mode_Active := FALSE;
GVL_INTENT_SAFETY.I_Gas_Close_Required := FALSE;
GVL_INTENT_SAFETY.I_Boiler_Stop_Required := FALSE;
GVL_INTENT_SAFETY.I_Vent_Stop_Required := FALSE;
GVL_INTENT_SAFETY.I_Vent_Force_PV3_Boost := FALSE;
GVL_INTENT_SAFETY.I_Vent_Force_Supply_100 := FALSE;
GVL_INTENT_SAFETY.I_Vent_Force_Supply_80 := FALSE;
GVL_INTENT_SAFETY.I_Vent_Force_Exhaust_100 := FALSE;
GVL_INTENT_SAFETY.I_Water_Main_Close_Required := FALSE;
GVL_INTENT_SAFETY.I_Water_Selective_Recovery_Allowed := FALSE;
GVL_INTENT_SAFETY.I_Water_Recovery_Target_Zone := 0;
GVL_INTENT_SAFETY.I_Lock_1_Force_Open := FALSE;
GVL_INTENT_SAFETY.I_Lock_1_Force_Close_Block := FALSE;
GVL_INTENT_SAFETY.I_Lock_2_Force_Open := FALSE;
GVL_INTENT_SAFETY.I_Lock_2_Force_Close_Block := FALSE;
FOR L_i := 1 TO 32 DO
    GVL_INTENT_SAFETY.I_Water_Zone_Close_Required[L_i] := FALSE;
END_FOR;

"""

if anchor not in text:
    raise SystemExit('Anchor for Stage A insert not found')
text = text.replace(anchor, insert + anchor, 1)

replacements = [
    ("GVL_ALARM.G_Fire_Alarm_Active := GVL_HEALTH_BRIDGE.G_Smoke_Detected;\nGVL_ALARM.G_Gas_Alarm_Active := GVL_HEALTH_BRIDGE.G_Gas_Detected OR GVL_HEALTH_BRIDGE.G_CO_Alarm_Level;\n",
     "GVL_ALARM.G_Fire_Alarm_Active := GVL_HEALTH_BRIDGE.G_Smoke_Detected;\nGVL_ALARM.G_Gas_Alarm_Active := GVL_HEALTH_BRIDGE.G_Gas_Detected OR GVL_HEALTH_BRIDGE.G_CO_Alarm_Level;\nGVL_INTENT_SAFETY.I_Fire_Alarm_Active := GVL_ALARM.G_Fire_Alarm_Active;\nGVL_INTENT_SAFETY.I_Gas_Alarm_Active := GVL_ALARM.G_Gas_Alarm_Active;\nGVL_INTENT_SAFETY.I_CO_Warning_Active := GVL_HEALTH_BRIDGE.G_CO_Warning_Level;\n"),
    ("IF GVL_STATE.G_Safety_Smoke_Latched THEN\n",
     "IF GVL_STATE.G_Safety_Smoke_Latched THEN\n    GVL_INTENT_SAFETY.I_System_Safe_Stop_Required := TRUE;\n    GVL_INTENT_SAFETY.I_Evacuation_Mode_Active := TRUE;\n    GVL_INTENT_SAFETY.I_Boiler_Stop_Required := TRUE;\n    GVL_INTENT_SAFETY.I_Vent_Stop_Required := TRUE;\n    GVL_INTENT_SAFETY.I_Lock_1_Force_Open := TRUE;\n    GVL_INTENT_SAFETY.I_Lock_1_Force_Close_Block := TRUE;\n    GVL_INTENT_SAFETY.I_Lock_2_Force_Open := TRUE;\n    GVL_INTENT_SAFETY.I_Lock_2_Force_Close_Block := TRUE;\n"),
    ("IF GVL_STATE.G_Safety_Gas_Latched THEN\n    GVL_COMMAND.G_Gas_Valve_Close := TRUE;\n    GVL_COMMAND.G_Boiler_Stop := TRUE;\nEND_IF;\n",
     "IF GVL_STATE.G_Safety_Gas_Latched THEN\n    GVL_INTENT_SAFETY.I_System_Safe_Stop_Required := TRUE;\n    GVL_INTENT_SAFETY.I_Gas_Close_Required := TRUE;\n    GVL_INTENT_SAFETY.I_Boiler_Stop_Required := TRUE;\n    GVL_COMMAND.G_Gas_Valve_Close := TRUE;\n    GVL_COMMAND.G_Boiler_Stop := TRUE;\nEND_IF;\n"),
    ("IF GVL_STATE.G_Safety_Leak_Latched THEN\n    GVL_COMMAND.G_Close_Valve_35 := TRUE;\n    GVL_COMMAND.G_Close_Valve_36 := TRUE;\nEND_IF;\n",
     "IF GVL_STATE.G_Safety_Leak_Latched THEN\n    GVL_INTENT_SAFETY.I_Water_Main_Close_Required := TRUE;\n    GVL_COMMAND.G_Close_Valve_35 := TRUE;\n    GVL_COMMAND.G_Close_Valve_36 := TRUE;\nEND_IF;\n"),
    ("IF GVL_STATE.G_Safety_Gas_Latched THEN\n    GVL_COMMAND.G_Vent_PV3_Boost := TRUE;\n    GVL_COMMAND.G_Supply_100_Req := TRUE;\nEND_IF;\n",
     "IF GVL_STATE.G_Safety_Gas_Latched THEN\n    GVL_INTENT_SAFETY.I_Vent_Force_PV3_Boost := TRUE;\n    GVL_INTENT_SAFETY.I_Vent_Force_Supply_100 := TRUE;\n    GVL_COMMAND.G_Vent_PV3_Boost := TRUE;\n    GVL_COMMAND.G_Supply_100_Req := TRUE;\nEND_IF;\n"),
    ("IF GVL_HEALTH_BRIDGE.G_CO_Warning_Level OR GVL_HEALTH_BRIDGE.G_CO_Alarm_Level THEN\n    GVL_COMMAND.G_Supply_80_Req := TRUE;\nEND_IF;\n",
     "IF GVL_HEALTH_BRIDGE.G_CO_Warning_Level OR GVL_HEALTH_BRIDGE.G_CO_Alarm_Level THEN\n    GVL_INTENT_SAFETY.I_Vent_Force_Supply_80 := TRUE;\n    GVL_COMMAND.G_Supply_80_Req := TRUE;\nEND_IF;\n"),
    ("GVL_STATE.G_Safety_Leak_Alarm := GVL_ALARM.G_Flood_Alarm_Active;\nGVL_STATE.G_Safety_Gas_Alarm := GVL_ALARM.G_Gas_Alarm_Active;\nGVL_STATE.G_Safety_Smoke_Alarm := GVL_ALARM.G_Fire_Alarm_Active;\n",
     "GVL_STATE.G_Safety_Leak_Alarm := GVL_ALARM.G_Flood_Alarm_Active;\nGVL_STATE.G_Safety_Gas_Alarm := GVL_ALARM.G_Gas_Alarm_Active;\nGVL_STATE.G_Safety_Smoke_Alarm := GVL_ALARM.G_Fire_Alarm_Active;\nGVL_INTENT_SAFETY.I_Leak_Alarm_Active := GVL_STATE.G_Safety_Leak_Alarm;\nGVL_INTENT_SAFETY.I_Gas_Alarm_Active := GVL_STATE.G_Safety_Gas_Alarm;\nGVL_INTENT_SAFETY.I_Fire_Alarm_Active := GVL_STATE.G_Safety_Smoke_Alarm;\n"),
    ("GVL_STATUS.G_Diagnostics.Water_Recovery_Selective_Allowed := TRUE;\n    GVL_STATUS.G_Diagnostics.Water_Recovery_Selective_Text := CONCAT('Селективное восстановление возможно для зоны ', GVL_STATUS.G_Diagnostics.Active_Leak_Zone_Name);\n",
     "GVL_STATUS.G_Diagnostics.Water_Recovery_Selective_Allowed := TRUE;\n    GVL_INTENT_SAFETY.I_Water_Selective_Recovery_Allowed := TRUE;\n    GVL_INTENT_SAFETY.I_Water_Recovery_Target_Zone := GVL_STATUS.G_Diagnostics.Water_Recovery_Target_Zone_Index;\n    GVL_STATUS.G_Diagnostics.Water_Recovery_Selective_Text := CONCAT('Селективное восстановление возможно для зоны ', GVL_STATUS.G_Diagnostics.Active_Leak_Zone_Name);\n"),
    ("IF GVL_STATE.G_Freeze_Hardware_Degraded THEN\n    GVL_STATUS.G_Diagnostics.Freeze_Hardware_Event_Pending := TRUE;\nEND_IF;\n",
     "IF GVL_STATE.G_Freeze_Hardware_Degraded THEN\n    GVL_INTENT_SAFETY.I_Freeze_Protection_Required := TRUE;\n    GVL_STATUS.G_Diagnostics.Freeze_Hardware_Event_Pending := TRUE;\nEND_IF;\n")
]

for old, new in replacements:
    if old not in text:
        raise SystemExit(f'Migration replacement anchor not found:\n{old}')
    text = text.replace(old, new, 1)

path.write_text(text, encoding='utf-8')
print('OK: Stage A parallel safety intent publication added to PRG_Safety')
