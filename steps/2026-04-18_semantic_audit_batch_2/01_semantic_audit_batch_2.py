from pathlib import Path

FILES = [
    "FB_FloorHeating_Freeze_Protection.st",
    "FB_FloorHeating_Overheat_Protection.st",
    "FB_Manifold_Pump_Controller.st",
    "FB_Pre_Departure_Heating.st",
    "FB_Calibration_Manager.st",
    "FB_Sensor_Distribution.st",
]

def extract_summary(text):
    lines = text.splitlines()

    header = []
    var_block = []
    body_preview = []

    in_var = False

    for l in lines[:200]:
        if "VAR" in l:
            in_var = True

        if in_var:
            var_block.append(l)

        if len(body_preview) < 60:
            body_preview.append(l)

        if "END_VAR" in l:
            in_var = False

        if len(header) < 30:
            header.append(l)

    return header, var_block, body_preview

print("=== SEMANTIC AUDIT BATCH 2 ===\n")

for fname in FILES:
    p = Path(fname)
    if not p.exists():
        print(f"{fname}: NOT FOUND\n")
        continue

    text = p.read_text(encoding="utf-8", errors="ignore")

    header, var_block, preview = extract_summary(text)

    print(f"=== {fname} ===")
    print("\n--- HEADER ---")
    print("\n".join(header))

    print("\n--- VAR BLOCK (trimmed) ---")
    print("\n".join(var_block[:60]))

    print("\n--- BODY PREVIEW ---")
    print("\n".join(preview[:60]))

    print("\n\n")
