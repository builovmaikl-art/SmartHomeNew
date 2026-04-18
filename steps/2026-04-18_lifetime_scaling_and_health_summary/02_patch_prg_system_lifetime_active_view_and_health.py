from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

old_block = """// === LIFETIME HMI ACTIVE VIEW ===
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

new_block = """// === LIFETIME HMI ACTIVE VIEW ===
IF GVL_Lifetime.G_Active_Device_Index < 1 THEN
    GVL_Lifetime.G_Active_Device_Index := 1;
ELSIF GVL_Lifetime.G_Active_Device_Index > 4 THEN
    GVL_Lifetime.G_Active_Device_Index := 4;
END_IF;

GVL_Lifetime.G_Active_Runtime_Hours := GVL_Lifetime.G_Status[GVL_Lifetime.G_Active_Device_Index].runtime_hours;
GVL_Lifetime.G_Active_Remaining_Hours := GVL_Lifetime.G_Status[GVL_Lifetime.G_Active_Device_Index].remaining_hours;
GVL_Lifetime.G_Active_Remaining_Percent := GVL_Lifetime.G_Status[GVL_Lifetime.G_Active_Device_Index].remaining_percent;
GVL_Lifetime.G_Active_Maintenance_Required := GVL_Lifetime.G_Status[GVL_Lifetime.G_Active_Device_Index].maintenance_required;
GVL_Lifetime.G_Active_Label := GVL_Lifetime.G_Device_Labels[GVL_Lifetime.G_Active_Device_Index];

// === LIFETIME HEALTH SUMMARY ===
GVL_Lifetime.G_Any_Maintenance_Required :=
    GVL_Lifetime.G_Status[1].maintenance_required OR
    GVL_Lifetime.G_Status[2].maintenance_required OR
    GVL_Lifetime.G_Status[3].maintenance_required OR
    GVL_Lifetime.G_Status[4].maintenance_required;

GVL_Lifetime.G_Maintenance_Warning :=
    (GVL_Lifetime.G_Status[1].remaining_percent <= 20) OR
    (GVL_Lifetime.G_Status[2].remaining_percent <= 20) OR
    (GVL_Lifetime.G_Status[3].remaining_percent <= 20) OR
    (GVL_Lifetime.G_Status[4].remaining_percent <= 20);

GVL_Lifetime.G_Maintenance_Critical :=
    (GVL_Lifetime.G_Status[1].remaining_percent <= 5) OR
    (GVL_Lifetime.G_Status[2].remaining_percent <= 5) OR
    (GVL_Lifetime.G_Status[3].remaining_percent <= 5) OR
    (GVL_Lifetime.G_Status[4].remaining_percent <= 5);
"""

if old_block not in text:
    raise SystemExit("Old lifetime HMI block not found in PRG_System.st")

text = text.replace(old_block, new_block, 1)
path.write_text(text, encoding="utf-8")
print("OK: patched PRG_System lifetime active-view + health summary")
