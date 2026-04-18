from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

replacements = {
    "REAL(GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Window_MS)": "TO_REAL(GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Window_MS)",
    "REAL(GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count)": "TO_REAL(GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count)",
    "REAL(GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count)": "TO_REAL(GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count)",
    "REAL(GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Fallback_Count)": "TO_REAL(GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Fallback_Count)",
    "REAL(GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Fallback_Count)": "TO_REAL(GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Fallback_Count)",
    "REAL(GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Fallback_Count)": "TO_REAL(GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Fallback_Count)",
}

for old, new in replacements.items():
    if old not in text:
        raise SystemExit(f"Expected cast not found: {old}")
    text = text.replace(old, new)

path.write_text(text, encoding="utf-8")
print("OK: replaced REAL(...) casts with TO_REAL(...) in rate metrics block")
