from pathlib import Path

FILES = [
    "FB_Outdoor_Lighting_Controller.st",
    "FB_Presence_Playback.st",
    "FB_Presence_Simulator.st",
    "FB_Supply_Ventilation_Controller.st",
    "FB_Exhaust_Ventilation_Controller.st",
]

def extract_summary(text):
    lines = text.splitlines()

    header = []
    var_block = []
    body_preview = []

    in_var = False

    for l in lines[:260]:
        if "VAR" in l:
            in_var = True

        if in_var:
            var_block.append(l)

        if len(body_preview) < 90:
            body_preview.append(l)

        if "END_VAR" in l:
            in_var = False

        if len(header) < 45:
            header.append(l)

    return header, var_block, body_preview

print("=== SEMANTIC AUDIT BATCH 4 ===\n")

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
    print("\n".join(var_block[:90]))

    print("\n--- BODY PREVIEW ---")
    print("\n".join(preview[:90]))

    print("\n\n")
