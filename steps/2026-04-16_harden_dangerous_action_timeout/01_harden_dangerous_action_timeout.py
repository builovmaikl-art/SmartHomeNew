from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

old = """IF L_Dangerous_Action_Armed AND (GVL_STATUS.G_System_Time_MS > L_Dangerous_Action_Deadline_MS) THEN
    L_Dangerous_Action_Armed := FALSE;
    GVL_STATUS.G_Diagnostics.Dangerous_Action_Pending_Confirm := FALSE;
    GVL_STATUS.G_Diagnostics.Dangerous_Action_Confirm_Text := 'Окно подтверждения истекло';
END_IF;
"""

new = """IF L_Dangerous_Action_Armed AND (GVL_STATUS.G_System_Time_MS > L_Dangerous_Action_Deadline_MS) THEN
    L_Dangerous_Action_Armed := FALSE;
    L_Maintenance_Apply_Intent := FALSE;
    GVL_STATUS.G_Diagnostics.Dangerous_Action_Pending_Confirm := FALSE;
    GVL_STATUS.G_Diagnostics.Dangerous_Action_Confirm_Text := 'Окно подтверждения истекло';
END_IF;
"""

if old not in text:
    raise SystemExit("Dangerous action timeout block not found")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: dangerous action timeout path hardened")
