from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

# 1. добавить prev
var_anchor = "L_User_Access_Denied_Prev : BOOL;\n"
var_insert = "L_Dangerous_Action_Request_Prev : BOOL;\n"

if var_insert not in text:
    if var_anchor not in text:
        raise SystemExit("VAR anchor not found")
    text = text.replace(var_anchor, var_anchor + var_insert, 1)

# 2. заменить блок
old = """IF GVL_COMMAND.CMD_Dangerous_Action_Request AND (GVL_COMMAND.CMD_User_Access_Level >= 2) THEN

    IF NOT L_Dangerous_Action_Armed THEN
        fbLogEvent(
            VI_Event_Type := 8,"""

new = """IF GVL_COMMAND.CMD_Dangerous_Action_Request AND
   NOT L_Dangerous_Action_Request_Prev AND
   (GVL_COMMAND.CMD_User_Access_Level >= 2) THEN

    IF NOT L_Dangerous_Action_Armed THEN
        fbLogEvent(
            VI_Event_Type := 8,"""

if old not in text:
    raise SystemExit("Dangerous request block not found")

text = text.replace(old, new, 1)

# 3. добавить фиксацию prev
tail_anchor = "L_User_Access_Denied_Prev := GVL_STATUS.G_Diagnostics.User_Access_Denied;\n"

tail_insert = """L_Dangerous_Action_Request_Prev := GVL_COMMAND.CMD_Dangerous_Action_Request;
"""

if tail_insert not in text:
    if tail_anchor not in text:
        raise SystemExit("Prev update anchor not found")
    text = text.replace(tail_anchor, tail_anchor + tail_insert, 1)

path.write_text(text, encoding="utf-8")
print("OK: dangerous action request now edge-triggered")
