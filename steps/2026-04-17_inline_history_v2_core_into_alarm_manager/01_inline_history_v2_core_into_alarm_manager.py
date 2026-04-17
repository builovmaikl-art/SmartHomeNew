from pathlib import Path

path = Path("FB_Alarm_Manager.st")
text = path.read_text(encoding="utf-8")

old = """// Shadow bridge: Alarm -> History V2 (diagnostic only)
fbHistoryV2Core(
    VI_Event_Pulse := VO_Event_Pulse,
    VI_Event_Code := VO_Event_Code,
    VI_Event_Value := VO_Event_Value,
    VI_System_Time_MS := VI_System_Time_MS,
    VIO_History_Buffer := L_History_V2_Buffer_Shadow
);
"""

new = """// Shadow bridge: Alarm -> History V2 (diagnostic only)
// Inlined from FB_History_V2_Core
IF VO_Event_Pulse THEN
    L_History_V2_Buffer_Shadow[1].Event_Code := TO_UINT(VO_Event_Code);
    L_History_V2_Buffer_Shadow[1].Event_Value := VO_Event_Value;
END_IF;
"""

if old not in text:
    raise SystemExit("History V2 core call block not found")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: inlined history V2 core logic into FB_Alarm_Manager.st")
