from pathlib import Path

path = Path("DUT/ST_Persist.dut")
text = path.read_text(encoding="utf-8")

old = """TYPE ST_Persist :
STRUCT
    // --- Core system ---
    System_Mode : INT;

    // --- Safety latches ---
    Safety_Gas_Latched : BOOL;
    Safety_Smoke_Latched : BOOL;
    Safety_Leak_Latched : BOOL;

    // --- DHW ---
    DHW_Heating_Active : BOOL;

    // --- Versioning (future-proof) ---
    Version : UINT := 1;
END_STRUCT
END_TYPE
"""

new = """TYPE ST_Persist :
STRUCT
    // --- Core system ---
    System_Mode : E_System_Operating_Mode;

    // --- Safety latches ---
    Safety_Gas_Latched : BOOL;
    Safety_Smoke_Latched : BOOL;
    Safety_Leak_Latched : BOOL;

    // --- DHW runtime state mirrored to persistence ---
    DHW_Heating_Pump : BOOL;

    // --- Validity / versioning ---
    Valid : BOOL;
    Version : UINT := 1;
END_STRUCT
END_TYPE
"""

if old not in text:
    raise SystemExit("Target content not found in DUT/ST_Persist.dut")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: ST_Persist aligned to live types and semantics")
