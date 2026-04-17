from pathlib import Path

path = Path("FB_Alarm_Manager.st")
text = path.read_text(encoding="utf-8")

old1 = """// Shadow comparison: execute Alarm V2 core on a separate shadow list.
// Legacy path remains authoritative; this is diagnostics only.
IF L_Alarm_V2_Shadow_Compare_Enabled THEN
    fbAlarmV2Core(
        VI_System_Time_MS := VI_System_Time_MS,
        VI_Pending_Alarms := L_Pending_Alarms,
        VIO_Alarm_List := L_Alarm_V2_List_Shadow,
        VIO_Next_ID := L_Alarm_V2_Next_ID_Shadow,
        VO_Event_Pulse => L_Alarm_V2_Event_Pulse,
        VO_Event_Code => L_Alarm_V2_Event_Code,
        VO_Event_Value => L_Alarm_V2_Event_Value
    );
END_IF;
"""

# Fallback in case param name is VIO_Next_Alarm_ID in actual file
old1b = """// Shadow comparison: execute Alarm V2 core on a separate shadow list.
// Legacy path remains authoritative; this is diagnostics only.
IF L_Alarm_V2_Shadow_Compare_Enabled THEN
    fbAlarmV2Core(
        VI_System_Time_MS := VI_System_Time_MS,
        VI_Pending_Alarms := L_Pending_Alarms,
        VIO_Alarm_List := L_Alarm_V2_List_Shadow,
        VIO_Next_Alarm_ID := L_Alarm_V2_Next_ID_Shadow,
        VO_Event_Pulse => L_Alarm_V2_Event_Pulse,
        VO_Event_Code => L_Alarm_V2_Event_Code,
        VO_Event_Value => L_Alarm_V2_Event_Value
    );
END_IF;
"""

new1 = """// Shadow comparison: Alarm V2 core is currently a no-op.
// Inlined from FB_Alarm_V2_Core
IF L_Alarm_V2_Shadow_Compare_Enabled THEN
    L_Alarm_V2_Event_Pulse := FALSE;
    L_Alarm_V2_Event_Code := 0;
    L_Alarm_V2_Event_Value := 0.0;
END_IF;
"""

old2 = """// Staging integration: Alarm V2 core is called behind the phase-4 switch scaffold.
// Current state: switch remains disabled, so legacy path stays authoritative.
IF L_Alarm_V2_Switch_Enabled AND L_Alarm_V2_Path_Ready THEN
    fbAlarmV2Core(
        VI_System_Time_MS := VI_System_Time_MS,
        VI_Pending_Alarms := L_Pending_Alarms,
        VIO_Alarm_List := VO_Alarm_List,
        VIO_Next_ID := VIO_Next_Alarm_ID
    );
END_IF;
"""

old2b = """// Staging integration: Alarm V2 core is called behind the phase-4 switch scaffold.
// Current state: switch remains disabled, so legacy path stays authoritative.
IF L_Alarm_V2_Switch_Enabled AND L_Alarm_V2_Path_Ready THEN
    fbAlarmV2Core(
        VI_System_Time_MS := VI_System_Time_MS,
        VI_Pending_Alarms := L_Pending_Alarms,
        VIO_Alarm_List := VO_Alarm_List,
        VIO_Next_Alarm_ID := VIO_Next_Alarm_ID
    );
END_IF;
"""

new2 = """// Staging integration: Alarm V2 core is currently a no-op.
// Inlined from FB_Alarm_V2_Core
IF L_Alarm_V2_Switch_Enabled AND L_Alarm_V2_Path_Ready THEN
    // No runtime mutation in current V2 core.
END_IF;
"""

if old1 in text:
    text = text.replace(old1, new1, 1)
elif old1b in text:
    text = text.replace(old1b, new1, 1)
else:
    raise SystemExit("Alarm V2 shadow call block not found")

if old2 in text:
    text = text.replace(old2, new2, 1)
elif old2b in text:
    text = text.replace(old2b, new2, 1)
else:
    raise SystemExit("Alarm V2 guarded call block not found")

path.write_text(text, encoding="utf-8")
print("OK: inlined no-op alarm V2 core into FB_Alarm_Manager.st")
