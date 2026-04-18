from pathlib import Path

path = Path("GVL_Lifetime.gvl")
text = path.read_text(encoding="utf-8")

insert = """
    // === LIFETIME LIMITS ===
    G_Pump_Nominal_Hours : REAL := 10000.0;
    G_Fan_Nominal_Hours  : REAL := 15000.0;

    // === WARNING THRESHOLDS ===
    G_Maintenance_Threshold_Percent : REAL := 20.0;
"""

if "G_Pump_Nominal_Hours" not in text:
    text = text.replace("END_VAR", insert + "\nEND_VAR")

path.write_text(text, encoding="utf-8")
print("OK: added lifetime nominal hours and threshold to GVL_Lifetime")
