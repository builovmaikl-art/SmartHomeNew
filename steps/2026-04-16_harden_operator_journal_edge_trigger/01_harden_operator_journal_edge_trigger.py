from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

var_anchor = "    L_Last_Operator_Journal_Seq : UDINT;\n"
var_insert = "    L_Last_Maintenance_Action_Code : UDINT;\n"

if var_insert not in text:
    if var_anchor not in text:
        raise SystemExit("VAR anchor not found")
    text = text.replace(var_anchor, var_anchor + var_insert, 1)

old_block = """IF GVL_CONFIG.G_DHW_Heating_Pump_In_Service <> L_Last_DHW_Heating_In_Service THEN
    GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq := GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq + 1;
    IF GVL_CONFIG.G_DHW_Heating_Pump_In_Service THEN
        GVL_STATUS.G_Diagnostics.Maintenance_Last_Action := 'Насос загрузки ГВС возвращён из ТО';
    ELSE
        GVL_STATUS.G_Diagnostics.Maintenance_Last_Action := 'Насос загрузки ГВС выведен в ТО';
    END_IF;
END_IF;
L_Last_DHW_Heating_In_Service := GVL_CONFIG.G_DHW_Heating_Pump_In_Service;
IF GVL_CONFIG.G_DHW_Circ_Pump_In_Service <> L_Last_DHW_Circ_In_Service THEN
    GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq := GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq + 1;
    IF GVL_CONFIG.G_DHW_Circ_Pump_In_Service THEN
        GVL_STATUS.G_Diagnostics.Maintenance_Last_Action := 'Насос рециркуляции ГВС возвращён из ТО';
    ELSE
        GVL_STATUS.G_Diagnostics.Maintenance_Last_Action := 'Насос рециркуляции ГВС выведен в ТО';
    END_IF;
END_IF;
L_Last_DHW_Circ_In_Service := GVL_CONFIG.G_DHW_Circ_Pump_In_Service;
"""

new_block = """IF GVL_CONFIG.G_DHW_Heating_Pump_In_Service <> L_Last_DHW_Heating_In_Service THEN
    IF GVL_CONFIG.G_DHW_Heating_Pump_In_Service THEN
        GVL_STATUS.G_Diagnostics.Maintenance_Last_Action := 'Насос загрузки ГВС возвращён из ТО';
        IF L_Last_Maintenance_Action_Code <> 1101 THEN
            GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq := GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq + 1;
            L_Last_Maintenance_Action_Code := 1101;
        END_IF;
    ELSE
        GVL_STATUS.G_Diagnostics.Maintenance_Last_Action := 'Насос загрузки ГВС выведен в ТО';
        IF L_Last_Maintenance_Action_Code <> 1102 THEN
            GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq := GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq + 1;
            L_Last_Maintenance_Action_Code := 1102;
        END_IF;
    END_IF;
END_IF;
L_Last_DHW_Heating_In_Service := GVL_CONFIG.G_DHW_Heating_Pump_In_Service;
IF GVL_CONFIG.G_DHW_Circ_Pump_In_Service <> L_Last_DHW_Circ_In_Service THEN
    IF GVL_CONFIG.G_DHW_Circ_Pump_In_Service THEN
        GVL_STATUS.G_Diagnostics.Maintenance_Last_Action := 'Насос рециркуляции ГВС возвращён из ТО';
        IF L_Last_Maintenance_Action_Code <> 1201 THEN
            GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq := GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq + 1;
            L_Last_Maintenance_Action_Code := 1201;
        END_IF;
    ELSE
        GVL_STATUS.G_Diagnostics.Maintenance_Last_Action := 'Насос рециркуляции ГВС выведен в ТО';
        IF L_Last_Maintenance_Action_Code <> 1202 THEN
            GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq := GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq + 1;
            L_Last_Maintenance_Action_Code := 1202;
        END_IF;
    END_IF;
END_IF;
L_Last_DHW_Circ_In_Service := GVL_CONFIG.G_DHW_Circ_Pump_In_Service;
"""

if old_block not in text:
    raise SystemExit("Maintenance journal block not found")

text = text.replace(old_block, new_block, 1)

path.write_text(text, encoding="utf-8")
print("OK: operator journal maintenance actions now use edge codes")
