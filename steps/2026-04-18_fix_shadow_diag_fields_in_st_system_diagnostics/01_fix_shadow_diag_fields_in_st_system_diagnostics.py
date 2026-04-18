from pathlib import Path

path = Path("ST_System_Diagnostics.dut")
text = path.read_text(encoding="utf-8")

anchor = """    Sensor_Fault : BOOL;
    IO_Offline : BOOL;
    Subsystem_Degraded : BOOL;
"""

insert = """    Sensor_Fault : BOOL;
    IO_Offline : BOOL;
    Subsystem_Degraded : BOOL;

    Sensor_Shadow_CO_Active : BOOL;
    Sensor_Shadow_CO_Diff : REAL;
    Sensor_Shadow_CO_Status_Text : STRING(80);

    Sensor_Shadow_Methane_Active : BOOL;
    Sensor_Shadow_Methane_Diff : REAL;
    Sensor_Shadow_Methane_Status_Text : STRING(80);

    Sensor_Shadow_Smoke_Active : BOOL;
    Sensor_Shadow_Smoke_Status_Text : STRING(80);
"""

if "Sensor_Shadow_CO_Active" not in text:
    if anchor not in text:
        raise SystemExit("Anchor block not found in ST_System_Diagnostics.dut")
    text = text.replace(anchor, insert, 1)

path.write_text(text, encoding="utf-8")
print("OK: added shadow diagnostics fields into ST_System_Diagnostics")
