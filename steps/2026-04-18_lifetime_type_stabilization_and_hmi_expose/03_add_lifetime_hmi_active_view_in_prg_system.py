from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

block = """
// === LIFETIME HMI ACTIVE VIEW ===
IF GVL_Lifetime.G_Active_Device_Index = 2 THEN
    GVL_Lifetime.G_Active_Runtime_Hours := GVL_Lifetime.G_Status[2].runtime_hours;
    GVL_Lifetime.G_Active_Remaining_Hours := GVL_Lifetime.G_Status[2].remaining_hours;
    GVL_Lifetime.G_Active_Remaining_Percent := GVL_Lifetime.G_Status[2].remaining_percent;
    GVL_Lifetime.G_Active_Maintenance_Required := GVL_Lifetime.G_Status[2].maintenance_required;
    GVL_Lifetime.G_Active_Label := GVL_Lifetime.G_Device2_Label;
ELSE
    GVL_Lifetime.G_Active_Runtime_Hours := GVL_Lifetime.G_Status[1].runtime_hours;
    GVL_Lifetime.G_Active_Remaining_Hours := GVL_Lifetime.G_Status[1].remaining_hours;
    GVL_Lifetime.G_Active_Remaining_Percent := GVL_Lifetime.G_Status[1].remaining_percent;
    GVL_Lifetime.G_Active_Maintenance_Required := GVL_Lifetime.G_Status[1].maintenance_required;
    GVL_Lifetime.G_Active_Label := GVL_Lifetime.G_Device1_Label;
END_IF;
"""

if "// === LIFETIME HMI ACTIVE VIEW ===" not in text:
    marker = "// === TREND → HISTORY WRITE"
    if marker not in text:
        raise SystemExit("Trend marker not found in PRG_System.st")
    text = text.replace(marker, block + "\n" + marker, 1)

path.write_text(text, encoding="utf-8")
print("OK: added lifetime HMI active-view logic to PRG_System")
