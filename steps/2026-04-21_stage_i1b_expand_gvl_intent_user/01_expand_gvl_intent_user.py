from pathlib import Path

path = Path('GVL_INTENT_USER.gvl')
text = path.read_text(encoding='utf-8')

anchor = "    I_Gas_Selective_Recover : BOOL := FALSE;\n"
insert = """

    // --- scenario / manual override ---
    I_Scenario_Request : E_SCENARIO_TYPE := E_SCENARIO_TYPE.SCENARIO_NONE;
    I_Lighting_Override_32 : ARRAY[1..32] OF BYTE;
    I_Blinds_Override_32 : ARRAY[1..32] OF BYTE;
    I_Socket_Override_32 : ARRAY[1..32] OF BOOL;
    I_Reset_Errors : BOOL := FALSE;

    // --- gateway climate / config / time intents ---
    I_Set_Temp_Req : BOOL := FALSE;
    I_Target_Zone : INT := 0;
    I_Target_Temperature : REAL := 0.0;
    I_Set_Vent_Req : BOOL := FALSE;
    I_Target_Vent_Speed : REAL := 0.0;
    I_Set_Config_Req : BOOL := FALSE;
    I_Time_Sync_Req : BOOL := FALSE;
    I_New_Time_MS : UDINT := 0;
"""

if anchor not in text:
    raise SystemExit('Anchor not found in GVL_INTENT_USER.gvl')

text = text.replace(anchor, anchor + insert, 1)
path.write_text(text, encoding='utf-8')
print('OK: expanded GVL_INTENT_USER with gateway/user producer fields')
