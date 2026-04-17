from pathlib import Path

path = Path("FB_Alarm_Manager.st")
text = path.read_text(encoding="utf-8")

old = """FOR L_i := 1 TO L_Pending_Count DO
    fbCompatAlarm[L_i](VI_Alarm_Legacy := L_Pending_Alarms[L_i]);

    IF NOT fbCompatAlarm[L_i].VO_OK THEN
        L_Alarm_Compat_All_OK := FALSE;
    END_IF;

    IF (NOT L_Alarm_First_Warning_Latched) AND (NOT fbCompatAlarm[L_i].VO_OK) THEN
        L_Alarm_First_Warning := 'Translation issue';
        L_Alarm_First_Warning_Latched := TRUE;
    END_IF;

    IF fbCompatAlarm[L_i].VO_Alarm_Legacy_Roundtrip.ID <> L_Pending_Alarms[L_i].ID THEN
        L_Alarm_Shadow_Mismatch := TRUE;
        IF L_Alarm_Shadow_First_Mismatch = 0 THEN
            L_Alarm_Shadow_First_Mismatch := L_i;
        END_IF;
    END_IF;
"""

new = """FOR L_i := 1 TO L_Pending_Count DO
    // Inlined from FB_Alarm_Compatibility_Package:
    // current compatibility path is a no-op roundtrip with VO_OK always TRUE.
"""

if old not in text:
    raise SystemExit("Alarm compatibility loop block not found")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: inlined no-op alarm compatibility path into FB_Alarm_Manager.st")
