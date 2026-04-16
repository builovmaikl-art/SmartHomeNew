from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

old = """// HMI maintenance mode control (confirmation-aware)
IF L_Maintenance_Apply_Intent THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        GVL_CONFIG.G_Manifold_Pump_In_Service[L_i] := GVL_COMMAND.CMD_Set_Manifold_Pump_In_Service[L_i];
    END_FOR;
    GVL_CONFIG.G_DHW_Heating_Pump_In_Service := GVL_COMMAND.CMD_Set_DHW_Heating_Pump_In_Service;
    GVL_CONFIG.G_DHW_Circ_Pump_In_Service := GVL_COMMAND.CMD_Set_DHW_Circ_Pump_In_Service;
END_IF;
"""

new = """// HMI maintenance mode control (confirmation-aware)
IF L_Maintenance_Apply_Intent AND
   ((GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL) OR
    (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_DEGRADED)) THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        GVL_CONFIG.G_Manifold_Pump_In_Service[L_i] := GVL_COMMAND.CMD_Set_Manifold_Pump_In_Service[L_i];
    END_FOR;
    GVL_CONFIG.G_DHW_Heating_Pump_In_Service := GVL_COMMAND.CMD_Set_DHW_Heating_Pump_In_Service;
    GVL_CONFIG.G_DHW_Circ_Pump_In_Service := GVL_COMMAND.CMD_Set_DHW_Circ_Pump_In_Service;
END_IF;
"""

if old not in text:
    raise SystemExit("Maintenance apply block not found")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: maintenance apply now gated by system mode")
