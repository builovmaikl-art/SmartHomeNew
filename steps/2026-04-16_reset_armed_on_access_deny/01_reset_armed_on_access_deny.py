from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

old = """        GVL_STATUS.G_Diagnostics.User_Access_Denied := TRUE;
        GVL_STATUS.G_Diagnostics.User_Access_Deny_Reason := 'Недостаточный уровень доступа для опасного действия';
        GVL_STATUS.G_Diagnostics.Operator_Action_Blocked := TRUE;
        GVL_STATUS.G_Diagnostics.Operator_Block_Reason := 'Требуется уровень ENGINEER для опасного действия';
        GVL_STATUS.G_Diagnostics.Dangerous_Action_Pending_Confirm := FALSE;
        GVL_STATUS.G_Diagnostics.Dangerous_Action_Confirm_Text := 'Доступ запрещён: требуется уровень ENGINEER';
"""

new = """        GVL_STATUS.G_Diagnostics.User_Access_Denied := TRUE;
        GVL_STATUS.G_Diagnostics.User_Access_Deny_Reason := 'Недостаточный уровень доступа для опасного действия';
        GVL_STATUS.G_Diagnostics.Operator_Action_Blocked := TRUE;
        GVL_STATUS.G_Diagnostics.Operator_Block_Reason := 'Требуется уровень ENGINEER для опасного действия';
        L_Dangerous_Action_Armed := FALSE;
        GVL_STATUS.G_Diagnostics.Dangerous_Action_Pending_Confirm := FALSE;
        GVL_STATUS.G_Diagnostics.Dangerous_Action_Confirm_Text := 'Доступ запрещён: требуется уровень ENGINEER';
"""

if old not in text:
    raise SystemExit("Access deny block not found")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: dangerous action armed state resets on access deny")
