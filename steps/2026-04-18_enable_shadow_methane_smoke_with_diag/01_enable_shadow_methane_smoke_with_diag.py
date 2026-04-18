from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

selector_marker = "// === SAFETY SELECTOR LAYER ==="
if selector_marker not in text:
    raise SystemExit("SAFETY SELECTOR LAYER marker not found")

insert_lines = []
if "GVL_Safety_Selector.G_Use_Shadow_Methane := TRUE;" not in text:
    insert_lines.append("GVL_Safety_Selector.G_Use_Shadow_Methane := TRUE;")
if "GVL_Safety_Selector.G_Use_Shadow_Smoke := TRUE;" not in text:
    insert_lines.append("GVL_Safety_Selector.G_Use_Shadow_Smoke := TRUE;")

if insert_lines:
    text = text.replace(
        selector_marker,
        selector_marker + "\n" + "\n".join(insert_lines),
        1
    )

diag_marker = "// === SHADOW CO DIAGNOSTIC EXPORT ==="
if diag_marker not in text:
    raise SystemExit("SHADOW CO DIAGNOSTIC EXPORT marker not found")

diag_block = """// === SHADOW METHANE/SMOKE DIAGNOSTIC EXPORT ===
GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Active := GVL_Safety_Selector.G_Use_Shadow_Methane;
GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Diff := GVL_Safety_Bridge.G_Methane_Diff;
GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Active := GVL_Safety_Selector.G_Use_Shadow_Smoke;

IF GVL_Safety_Selector.G_Use_Shadow_Methane THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Status_Text := 'Methane shadow ACTIVE';
ELSE
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Status_Text := 'Methane shadow OFF';
END_IF;

IF GVL_Safety_Selector.G_Use_Shadow_Smoke THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Status_Text := 'Smoke shadow ACTIVE';
ELSE
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Status_Text := 'Smoke shadow OFF';
END_IF;

"""

if "Sensor_Shadow_Methane_Active" not in text:
    text = text.replace(diag_marker, diag_block + diag_marker, 1)

path.write_text(text, encoding="utf-8")
print("OK: enabled methane/smoke shadow and added diagnostics")
