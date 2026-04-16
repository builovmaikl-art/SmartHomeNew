from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

var_anchor = "    L_Gateway_Writes_Allowed : BOOL;\n"
var_insert = "    L_Last_Policy_Event_Time_MS : UDINT;\n"

if var_insert not in text:
    if var_anchor not in text:
        raise SystemExit("VAR anchor not found")
    text = text.replace(var_anchor, var_anchor + var_insert, 1)

old5 = """            fbLogEvent(
                VI_Event_Type := 5,
                VI_Timestamp := GVL_STATUS.G_System_Time_MS,
                VI_Param1 := TO_UDINT(L_Scenario_Source),
                VI_Param2 := TO_UDINT(E_SCENARIO_TYPE.SCENARIO_AWAY)
            );
"""

new5 = """            IF (L_Last_Policy_Event_Time_MS = 0) OR
               ((GVL_STATUS.G_System_Time_MS - L_Last_Policy_Event_Time_MS) >= 5000) THEN
                fbLogEvent(
                    VI_Event_Type := 5,
                    VI_Timestamp := GVL_STATUS.G_System_Time_MS,
                    VI_Param1 := TO_UDINT(L_Scenario_Source),
                    VI_Param2 := TO_UDINT(E_SCENARIO_TYPE.SCENARIO_AWAY)
                );
                L_Last_Policy_Event_Time_MS := GVL_STATUS.G_System_Time_MS;
            END_IF;
"""

old6 = """                fbLogEvent(
                    VI_Event_Type := 6,
                    VI_Timestamp := GVL_STATUS.G_System_Time_MS,
                    VI_Param1 := TO_UDINT(L_Scenario_Source),
                    VI_Param2 := TO_UDINT(E_SCENARIO_TYPE.SCENARIO_AWAY)
                );
"""

new6 = """                IF (L_Last_Policy_Event_Time_MS = 0) OR
                   ((GVL_STATUS.G_System_Time_MS - L_Last_Policy_Event_Time_MS) >= 5000) THEN
                    fbLogEvent(
                        VI_Event_Type := 6,
                        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
                        VI_Param1 := TO_UDINT(L_Scenario_Source),
                        VI_Param2 := TO_UDINT(E_SCENARIO_TYPE.SCENARIO_AWAY)
                    );
                    L_Last_Policy_Event_Time_MS := GVL_STATUS.G_System_Time_MS;
                END_IF;
"""

old7 = """                fbLogEvent(
                    VI_Event_Type := 7,
                    VI_Timestamp := GVL_STATUS.G_System_Time_MS,
                    VI_Param1 := TO_UDINT(L_Scenario_Source),
                    VI_Param2 := TO_UDINT(E_SCENARIO_TYPE.SCENARIO_SLEEP)
                );
"""

new7 = """                IF (L_Last_Policy_Event_Time_MS = 0) OR
                   ((GVL_STATUS.G_System_Time_MS - L_Last_Policy_Event_Time_MS) >= 5000) THEN
                    fbLogEvent(
                        VI_Event_Type := 7,
                        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
                        VI_Param1 := TO_UDINT(L_Scenario_Source),
                        VI_Param2 := TO_UDINT(E_SCENARIO_TYPE.SCENARIO_SLEEP)
                    );
                    L_Last_Policy_Event_Time_MS := GVL_STATUS.G_System_Time_MS;
                END_IF;
"""

for old, new in [(old5, new5), (old6, new6), (old7, new7)]:
    if old not in text:
        raise SystemExit("Target policy event block not found")
    text = text.replace(old, new, 1)

path.write_text(text, encoding="utf-8")
print("OK: added 5s cooldown for policy scenario events")
