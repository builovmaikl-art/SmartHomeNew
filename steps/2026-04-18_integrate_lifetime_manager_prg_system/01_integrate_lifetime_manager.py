from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

# --- VAR BLOCK ---
var_block = """
// === LIFETIME MANAGERS ===
fbLifetimePump : FB_Lifetime_Manager;
fbLifetimeFan  : FB_Lifetime_Manager;
"""

if "fbLifetimePump" not in text:
    text = text.replace("VAR", "VAR\n" + var_block, 1)

# --- CALL BLOCK ---
call_block = """
// === LIFETIME UPDATE ===

// pump (временно FALSE — до реального сигнала)
fbLifetimePump(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Device_Active  := FALSE,
    VI_Device_ID      := GVL_Lifetime.G_Device_Pump,
    VIO_Status        := GVL_Lifetime.G_Status[1]
);

// fan (временно FALSE — до реального сигнала)
fbLifetimeFan(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Device_Active  := FALSE,
    VI_Device_ID      := GVL_Lifetime.G_Device_Fan,
    VIO_Status        := GVL_Lifetime.G_Status[2]
);
"""

if "// === LIFETIME UPDATE ===" not in text:
    marker = "// === TREND → HISTORY WRITE"
    if marker not in text:
        raise SystemExit("Trend marker not found")
    text = text.replace(marker, call_block + "\n" + marker, 1)

path.write_text(text, encoding="utf-8")
print("OK: integrated FB_Lifetime_Manager into PRG_System")
