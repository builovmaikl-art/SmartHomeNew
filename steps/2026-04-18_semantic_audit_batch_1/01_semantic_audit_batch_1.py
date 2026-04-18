from pathlib import Path

FILES = [
    "FB_CO_Detector.st",
    "FB_Gas_Methane_Detector.st",
    "FB_Smoke_Detector.st",
    "FB_Gas_Valve_Controller.st",
    "FB_Water_Valve_Controller.st",
    "FB_Emergency_Valve_Open.st",
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

        if len(body_preview) < 40:
            body_preview.append(l)

        if "END_VAR" in l:
            in_var = False

        if len(header) < 20:
            header.append(l)

    return header, var_block, body_preview

print("=== SEMANTIC AUDIT BATCH 1 ===\n")

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
    print("\n".join(var_block[:40]))

    print("\n--- BODY PREVIEW ---")
    print("\n".join(preview[:40]))

    print("\n\n")
