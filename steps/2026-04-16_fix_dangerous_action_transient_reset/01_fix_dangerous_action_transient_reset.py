from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

old = """// Access level enforcement for dangerous actions
GVL_STATUS.G_Diagnostics.User_Access_Level_Active := GVL_COMMAND.CMD_User_Access_Level;
GVL_STATUS.G_Diagnostics.User_Access_Denied := FALSE;
GVL_STATUS.G_Diagnostics.User_Access_Deny_Reason := '';
"""

new = """// Access level enforcement for dangerous actions
GVL_STATUS.G_Diagnostics.User_Access_Level_Active := GVL_COMMAND.CMD_User_Access_Level;
GVL_STATUS.G_Diagnostics.User_Access_Denied := FALSE;
GVL_STATUS.G_Diagnostics.User_Access_Deny_Reason := '';
GVL_STATUS.G_Diagnostics.Operator_Action_Blocked := FALSE;
GVL_STATUS.G_Diagnostics.Operator_Block_Reason := '';
"""

if old not in text:
    raise SystemExit("Access enforcement reset block not found")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: transient dangerous-action block flags now reset each cycle")
