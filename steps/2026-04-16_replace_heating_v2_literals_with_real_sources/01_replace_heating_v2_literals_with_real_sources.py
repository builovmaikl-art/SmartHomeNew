from pathlib import Path

path = Path("FB_Heating_System_Manager.st")
text = path.read_text(encoding="utf-8")

old = """fbHeatingV2Staging(
    VI_Zone_ID := 1,
    VI_Enable := TRUE,
    VI_Target_Temp := 22.0,
    VI_Valve_Position_Setpoint := 50.0,
    VI_Pump_Enable := TRUE,

    VI_Is_Active := TRUE,
    VI_Room_Temp := 21.0,
    VI_Supply_Temp := 35.0,
    VI_Return_Temp := 30.0,
    VI_Valve_Position_Actual := 50.0,
    VI_Alarm_Active := FALSE,

    VO_Command_Shadow => L_Heating_V2_Command_V2,
    VO_State_Shadow => L_Heating_V2_State_V2
);"""

new = """fbHeatingV2Staging(
    VI_Zone_ID := 1,
    VI_Enable := VO_Manifold_Pumps[1],
    VI_Target_Temp := L_Target_Supply_Temp,
    VI_Valve_Position_Setpoint := VO_Manifold_Valves[1],
    VI_Pump_Enable := VO_Manifold_Pumps[1],

    VI_Is_Active := VO_Manifold_Pumps[1],
    VI_Room_Temp := VI_Room_Temps[1],
    VI_Supply_Temp := VI_Manifold_Temps_Supply[1],
    VI_Return_Temp := VI_Manifold_Temps_Return[1],
    VI_Valve_Position_Actual := VO_Manifold_Valves[1],
    VI_Alarm_Active := GVL_STATE.G_Heating_IO_Fault OR GVL_STATE.G_Heating_Subsystem_Degraded,

    VO_Command_Shadow => L_Heating_V2_Command_V2,
    VO_State_Shadow => L_Heating_V2_State_V2
);"""

if old not in text:
    raise SystemExit("Heating V2 staging call block not found")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: replaced heating V2 staging literals with real sources")
