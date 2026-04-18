from pathlib import Path

path = Path("FB_Lifetime_Manager.st")
text = path.read_text(encoding="utf-8")

if "VI_Nominal_Hours" not in text:
    text = text.replace(
        "    VI_Device_ID      : BYTE;\n",
        "    VI_Device_ID      : BYTE;\n    VI_Nominal_Hours : REAL;\n"
    )

old = """// === BASIC FLAGS ===
VIO_Status.device_id := VI_Device_ID;
VIO_Status.last_calc_timestamp := VI_System_Time_MS;
"""

new = """// === BASIC LIFETIME ESTIMATION ===
IF VI_Nominal_Hours > 0.0 THEN
    IF VIO_Status.runtime_hours >= VI_Nominal_Hours THEN
        VIO_Status.remaining_hours := 0.0;
        VIO_Status.remaining_percent := 0.0;
    ELSE
        VIO_Status.remaining_hours := VI_Nominal_Hours - VIO_Status.runtime_hours;
        VIO_Status.remaining_percent := (VIO_Status.remaining_hours / VI_Nominal_Hours) * 100.0;
    END_IF;
ELSE
    VIO_Status.remaining_hours := 0.0;
    VIO_Status.remaining_percent := 0.0;
END_IF;

VIO_Status.maintenance_required := VIO_Status.remaining_percent <= 20.0;

// === BASIC FLAGS ===
VIO_Status.device_id := VI_Device_ID;
VIO_Status.last_calc_timestamp := VI_System_Time_MS;
"""

if old not in text:
    raise SystemExit("Expected BASIC FLAGS block not found in FB_Lifetime_Manager.st")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: patched FB_Lifetime_Manager with basic lifetime estimation")
