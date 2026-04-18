from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

# ------------------------------------------------------------
# 1) Add previous-state vars
# ------------------------------------------------------------
anchor = "L_Dangerous_Action_Request_Prev : BOOL;"
if anchor not in text:
    raise SystemExit("VAR anchor not found in PRG_System.st")

insert = """L_Dangerous_Action_Request_Prev : BOOL;

L_Shadow_CO_Enabled_Prev : BOOL;
L_Shadow_Methane_Enabled_Prev : BOOL;
L_Shadow_Smoke_Enabled_Prev : BOOL;"""

if "L_Shadow_CO_Enabled_Prev" not in text:
    text = text.replace(anchor, insert, 1)

# ------------------------------------------------------------
# 2) Add event logging block after quality text block
# ------------------------------------------------------------
quality_block_end = """ELSE
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Quality_Text := 'Shadow safety quality OK';
END_IF;
"""

if quality_block_end not in text:
    raise SystemExit("Quality text block end not found in PRG_System.st")

event_block = """ELSE
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Quality_Text := 'Shadow safety quality OK';
END_IF;

// === SHADOW POLICY EVENT LOGGING ===
// Event codes:
// 2101 CO shadow fallback
// 2102 CO shadow recovery
// 2111 Methane shadow fallback
// 2112 Methane shadow recovery
// 2121 Smoke shadow fallback
// 2122 Smoke shadow recovery

IF (NOT GVL_Safety_Selector.G_Use_Shadow_CO) AND L_Shadow_CO_Enabled_Prev THEN
    fbLogEvent(
        VI_Event_Type := 21,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 2101,
        VI_Param2 := 0
    );
END_IF;

IF GVL_Safety_Selector.G_Use_Shadow_CO AND (NOT L_Shadow_CO_Enabled_Prev) THEN
    fbLogEvent(
        VI_Event_Type := 22,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 2102,
        VI_Param2 := 1
    );
END_IF;

IF (NOT GVL_Safety_Selector.G_Use_Shadow_Methane) AND L_Shadow_Methane_Enabled_Prev THEN
    fbLogEvent(
        VI_Event_Type := 23,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 2111,
        VI_Param2 := 0
    );
END_IF;

IF GVL_Safety_Selector.G_Use_Shadow_Methane AND (NOT L_Shadow_Methane_Enabled_Prev) THEN
    fbLogEvent(
        VI_Event_Type := 24,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 2112,
        VI_Param2 := 1
    );
END_IF;

IF (NOT GVL_Safety_Selector.G_Use_Shadow_Smoke) AND L_Shadow_Smoke_Enabled_Prev THEN
    fbLogEvent(
        VI_Event_Type := 25,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 2121,
        VI_Param2 := 0
    );
END_IF;

IF GVL_Safety_Selector.G_Use_Shadow_Smoke AND (NOT L_Shadow_Smoke_Enabled_Prev) THEN
    fbLogEvent(
        VI_Event_Type := 26,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 2122,
        VI_Param2 := 1
    );
END_IF;

L_Shadow_CO_Enabled_Prev := GVL_Safety_Selector.G_Use_Shadow_CO;
L_Shadow_Methane_Enabled_Prev := GVL_Safety_Selector.G_Use_Shadow_Methane;
L_Shadow_Smoke_Enabled_Prev := GVL_Safety_Selector.G_Use_Shadow_Smoke;
"""

if "// === SHADOW POLICY EVENT LOGGING ===" not in text:
    text = text.replace(quality_block_end, event_block, 1)

path.write_text(text, encoding="utf-8")
print("OK: added shadow policy event logging")
