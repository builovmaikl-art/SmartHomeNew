from pathlib import Path

# ------------------------------------------------------------
# 1) Extend ST_System_Diagnostics.dut
# ------------------------------------------------------------
dut = Path("ST_System_Diagnostics.dut")
dut_text = dut.read_text(encoding="utf-8")

anchor = """    Sensor_Shadow_Dominant_Channel : STRING(32);
    Sensor_Shadow_Policy_Summary_Text : STRING(160);
"""
insert = """    Sensor_Shadow_Dominant_Channel : STRING(32);
    Sensor_Shadow_Policy_Summary_Text : STRING(160);

    Sensor_Shadow_Recent_Window_MS : UDINT;

    Sensor_Shadow_CO_Last_Fallback_MS : UDINT;
    Sensor_Shadow_CO_Last_Recovery_MS : UDINT;
    Sensor_Shadow_Methane_Last_Fallback_MS : UDINT;
    Sensor_Shadow_Methane_Last_Recovery_MS : UDINT;
    Sensor_Shadow_Smoke_Last_Fallback_MS : UDINT;
    Sensor_Shadow_Smoke_Last_Recovery_MS : UDINT;

    Sensor_Shadow_CO_Recent_Fallback : BOOL;
    Sensor_Shadow_CO_Recent_Recovery : BOOL;
    Sensor_Shadow_Methane_Recent_Fallback : BOOL;
    Sensor_Shadow_Methane_Recent_Recovery : BOOL;
    Sensor_Shadow_Smoke_Recent_Fallback : BOOL;
    Sensor_Shadow_Smoke_Recent_Recovery : BOOL;

    Sensor_Shadow_Recent_Activity_Text : STRING(160);
"""

if "Sensor_Shadow_Recent_Window_MS" not in dut_text:
    if anchor not in dut_text:
        raise SystemExit("Summary anchor not found in ST_System_Diagnostics.dut")
    dut_text = dut_text.replace(anchor, insert, 1)

dut.write_text(dut_text, encoding="utf-8")

# ------------------------------------------------------------
# 2) Patch PRG_System event block: timestamps on events
# ------------------------------------------------------------
prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

repls = [
    (
"""    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Fallback_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Fallback_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count + 1;""",
"""    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Fallback_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Fallback_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Last_Fallback_MS := GVL_STATUS.G_System_Time_MS;"""
    ),
    (
"""    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Recovery_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Recovery_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count + 1;""",
"""    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Recovery_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Recovery_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Last_Recovery_MS := GVL_STATUS.G_System_Time_MS;"""
    ),
    (
"""    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Fallback_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Fallback_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count + 1;""",
"""    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Fallback_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Fallback_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Last_Fallback_MS := GVL_STATUS.G_System_Time_MS;"""
    ),
    (
"""    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Recovery_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Recovery_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count + 1;""",
"""    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Recovery_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Recovery_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Last_Recovery_MS := GVL_STATUS.G_System_Time_MS;"""
    ),
    (
"""    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Fallback_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Fallback_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count + 1;""",
"""    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Fallback_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Fallback_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Last_Fallback_MS := GVL_STATUS.G_System_Time_MS;"""
    ),
    (
"""    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Recovery_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Recovery_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count + 1;""",
"""    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Recovery_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Recovery_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Last_Recovery_MS := GVL_STATUS.G_System_Time_MS;"""
    ),
]

for old, new in repls:
    if old not in text:
        raise SystemExit("Expected aggregation pattern not found in PRG_System.st")
    text = text.replace(old, new, 1)

# ------------------------------------------------------------
# 3) Add recent-activity window summary block
# ------------------------------------------------------------
marker = "// === LIFETIME UPDATE ==="
if marker not in text:
    raise SystemExit("LIFETIME marker not found in PRG_System.st")

block = """// === SHADOW POLICY RECENT ACTIVITY WINDOW ===
IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Window_MS = 0 THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Window_MS := 3600000; // 1 hour default
END_IF;

GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Recent_Fallback :=
    (GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Last_Fallback_MS > 0) AND
    ((GVL_STATUS.G_System_Time_MS - GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Last_Fallback_MS) <=
      GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Window_MS);

GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Recent_Recovery :=
    (GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Last_Recovery_MS > 0) AND
    ((GVL_STATUS.G_System_Time_MS - GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Last_Recovery_MS) <=
      GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Window_MS);

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Recent_Fallback :=
    (GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Last_Fallback_MS > 0) AND
    ((GVL_STATUS.G_System_Time_MS - GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Last_Fallback_MS) <=
      GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Window_MS);

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Recent_Recovery :=
    (GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Last_Recovery_MS > 0) AND
    ((GVL_STATUS.G_System_Time_MS - GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Last_Recovery_MS) <=
      GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Window_MS);

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Recent_Fallback :=
    (GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Last_Fallback_MS > 0) AND
    ((GVL_STATUS.G_System_Time_MS - GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Last_Fallback_MS) <=
      GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Window_MS);

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Recent_Recovery :=
    (GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Last_Recovery_MS > 0) AND
    ((GVL_STATUS.G_System_Time_MS - GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Last_Recovery_MS) <=
      GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Window_MS);

IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Recent_Fallback OR
   GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Recent_Fallback OR
   GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Recent_Fallback THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Activity_Text := 'Recent shadow fallback activity';
ELSIF GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Recent_Recovery OR
      GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Recent_Recovery OR
      GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Recent_Recovery THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Activity_Text := 'Recent shadow recovery activity';
ELSE
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Activity_Text := 'No recent shadow policy activity';
END_IF;

"""

if "// === SHADOW POLICY RECENT ACTIVITY WINDOW ===" not in text:
    text = text.replace(marker, block + marker, 1)

prg.write_text(text, encoding="utf-8")
print("OK: added shadow policy recent activity window")
