from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

block = """
// === TREND MULTI-SIGNAL FOUNDATION ===
// Channel 1 is currently active (Outdoor Temp / TEMP_AIR).
// Channel 2 reserved for future integration.
// HMI may use GVL_Trend.G_Trend_Selected_Channel to switch active graph source.
"""

if "// === TREND MULTI-SIGNAL FOUNDATION ===" not in text:
    marker = "// === TREND → GVL FOR HMI ==="
    if marker not in text:
        raise SystemExit("Trend GVL marker not found in PRG_System.st")
    text = text.replace(marker, block + "\n" + marker, 1)

path.write_text(text, encoding="utf-8")
print("OK: added multi-signal trend foundation comment block to PRG_System")
