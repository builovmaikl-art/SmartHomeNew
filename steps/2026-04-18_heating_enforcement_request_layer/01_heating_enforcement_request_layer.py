from pathlib import Path

# ------------------------------------------------------------
# 1) Extend diagnostics with request-layer fields
# ------------------------------------------------------------
dut = Path("ST_System_Diagnostics.dut")
dut_text = dut.read_text(encoding="utf-8")

anchor = "    Heating_Protection_Summary_Text : STRING(160);\n\n\n\nEND_STRUCT"
insert = """    Heating_Protection_Summary_Text : STRING(160);

    // === HEATING ENFORCEMENT REQUEST LAYER (ISOLATED) ===
    Heating_Pump_Force_Request_Active : BOOL;
    Heating_Overheat_Enforcement_Request_Active : BOOL;
    Heating_Enforcement_Request_Text : STRING(160);



END_STRUCT"""

if "Heating_Pump_Force_Request_Active : BOOL;" not in dut_text:
    if anchor not in dut_text:
        raise SystemExit("Diagnostics anchor not found in ST_System_Diagnostics.dut")
    dut_text = dut_text.replace(anchor, insert, 1)

dut.write_text(dut_text, encoding="utf-8")

# ------------------------------------------------------------
# 2) Insert request-layer logic in PRG_System right after observer
# ------------------------------------------------------------
prg = Path("PRG_System.st")
prg_text = prg.read_text(encoding="utf-8")

observer_tail = """ELSE
    GVL_STATUS.G_Diagnostics.Heating_Protection_Summary_Text := 'Heating protection normal';
END_IF;

"""

request_block = """// === HEATING ENFORCEMENT REQUEST LAYER ===
GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Request_Active :=
    GVL_STATUS.G_Diagnostics.Heating_Freeze_Pump_Force_Request;

GVL_STATUS.G_Diagnostics.Heating_Overheat_Enforcement_Request_Active :=
    GVL_STATUS.G_Diagnostics.Heating_Overheat_Detected;

IF GVL_STATUS.G_Diagnostics.Heating_Overheat_Enforcement_Request_Active THEN
    GVL_STATUS.G_Diagnostics.Heating_Enforcement_Request_Text := 'Request: lock overheated circuits';
ELSIF GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Request_Active THEN
    GVL_STATUS.G_Diagnostics.Heating_Enforcement_Request_Text := 'Request: force heating pump';
ELSE
    GVL_STATUS.G_Diagnostics.Heating_Enforcement_Request_Text := 'No heating enforcement requests';
END_IF;

"""

if "// === HEATING ENFORCEMENT REQUEST LAYER ===" not in prg_text:
    if observer_tail not in prg_text:
        raise SystemExit("Observer tail anchor not found in PRG_System.st")
    prg_text = prg_text.replace(observer_tail, observer_tail + request_block, 1)

prg.write_text(prg_text, encoding="utf-8")
print("OK: heating enforcement request layer integrated")
