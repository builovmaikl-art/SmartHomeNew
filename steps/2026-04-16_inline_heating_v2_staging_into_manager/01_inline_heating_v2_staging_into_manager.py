from pathlib import Path

path = Path("FB_Heating_System_Manager.st")
text = path.read_text(encoding="utf-8")

old = """// ========================================
// Heating V2 staging execution
// ========================================
fbHeatingV2Staging(
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
);
"""

new = """// ========================================
// Heating V2 shadow execution (phase2)
// Inlined from FB_Heating_V2_Staging
// ========================================
L_Heating_V2_Command_V2.Valve_Position_Setpoint := VO_Manifold_Valves[1];
L_Heating_V2_State_V2.Room_Temp := VI_Room_Temps[1];
L_Heating_V2_State_V2.Supply_Temp := VI_Manifold_Temps_Supply[1];
"""

if old not in text:
    raise SystemExit("Heating V2 staging call block not found")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: inlined heating V2 staging logic into FB_Heating_System_Manager.st")
