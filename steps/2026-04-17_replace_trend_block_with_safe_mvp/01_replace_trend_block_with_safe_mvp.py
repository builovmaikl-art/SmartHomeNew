from pathlib import Path
import re

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

start_marker = "// === TREND EXECUTION (MVP) ==="
end_marker = "// >>> BULK_SYNC_ANCHOR: PRG_System <<<"

if start_marker not in text:
    raise SystemExit("Trend start marker not found in PRG_System.st")
if end_marker not in text:
    raise SystemExit("Trend end marker not found in PRG_System.st")

start = text.index(start_marker)
end = text.index(end_marker)

new_block = """// === TREND EXECUTION (SAFE MVP) ===
L_Trend_Data.config.param_type := 1;
L_Trend_Data.config.zone_id := 0;
L_Trend_Data.config.enabled := TRUE;
L_Trend_Data.config.deviation_threshold_percent := 1.0;
L_Trend_Data.config.history_days := 1;

L_Trend_Logger(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Config := L_Trend_Data.config,
    VI_Current_Value := GVL_STATE.G_Outdoor_Temp
);

L_Trend_Data := L_Trend_Logger.VO_Data;

// === TREND → HISTORY WRITE (EDGE, SAFE MVP) ===
L_Trend_Write := (L_Trend_Data.record_count > 0);

IF L_Trend_Write AND NOT L_Trend_Write_Prev THEN
    L_Trend_Event.event_code := 1001;
    IF L_Trend_Data.record_count > 0 THEN
        L_Trend_Event.event_value := L_Trend_Data.sum_values / UDINT_TO_REAL(L_Trend_Data.record_count);
    ELSE
        L_Trend_Event.event_value := 0.0;
    END_IF;
    L_Trend_Event.zone_id := 0;
    L_Trend_Event.operator_id := '';
    L_History_Write_Event := TRUE;
    L_History_Event := L_Trend_Event;
END_IF;

L_Trend_Write_Prev := L_Trend_Write;

"""

text = text[:start] + new_block + text[end:]

# also kill any stale forbidden assignment that may still be present
text = text.replace(
    "GVL_STATUS.G_Diagnostics.HMI_Last_Message",
    "GVL_GATEWAY.G_Gateway_HMI_Status_Message"
)

path.write_text(text, encoding="utf-8")
print("OK: replaced trend block with safe MVP and normalized stale HMI message target")
