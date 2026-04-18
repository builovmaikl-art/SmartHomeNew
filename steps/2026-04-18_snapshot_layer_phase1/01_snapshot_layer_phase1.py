from pathlib import Path

# ------------------------------------------------------------
# 1) Ensure instance in PRG_System VAR
# ------------------------------------------------------------
prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

var_anchor = "VAR\n"
if "fbSnapshotMgr : FB_State_Snapshot_Manager;" not in text:
    text = text.replace(
        var_anchor,
        var_anchor + "    fbSnapshotMgr : FB_State_Snapshot_Manager;\n",
        1
    )

# ------------------------------------------------------------
# 2) Insert snapshot call block
# ------------------------------------------------------------
marker = "// === LIFETIME UPDATE ==="

block = """// === SNAPSHOT LAYER (PHASE 1) ===
VAR
    L_Snapshot : ST_State_Snapshot;
END_VAR

// заполнение snapshot
L_Snapshot.timestamp_ms := GVL_SYSTEM.G_System_Time;
L_Snapshot.trigger_event_code := 0;

// минимальный набор
L_Snapshot.shadow_alert_active :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active;

L_Snapshot.shadow_dominant_channel :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Dominant_Channel;

L_Snapshot.total_fallback :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count;

L_Snapshot.total_recovery :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count;

// trigger (пока простой)
fbSnapshotMgr(
    VI_System_Time_MS := GVL_SYSTEM.G_System_Time,
    VI_Trigger_Event  := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active,
    VI_Event_Code     := WORD#1,
    VI_Current_State  := L_Snapshot
);

"""

if "// === SNAPSHOT LAYER (PHASE 1) ===" not in text:
    if marker not in text:
        raise SystemExit("LIFETIME marker not found")
    text = text.replace(marker, block + marker, 1)

prg.write_text(text, encoding="utf-8")
print("OK: snapshot layer phase1 added")
