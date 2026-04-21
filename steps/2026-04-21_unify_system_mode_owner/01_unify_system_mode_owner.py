from pathlib import Path

path = Path('PRG_Safety.st')
text = path.read_text(encoding='utf-8')

old = """// === Global System Arbitration ===
IF GVL_STATE.G_Safety_Emergency_Stop THEN
    GVL_STATE.G_System_Mode := E_System_Operating_Mode.MODE_SAFE_STOP;

ELSIF GVL_STATE.G_Safety_Smoke_Latched THEN
    GVL_STATE.G_System_Mode := E_System_Operating_Mode.MODE_SAFE_STOP;

ELSIF GVL_STATE.G_Safety_Gas_Latched THEN
    GVL_STATE.G_System_Mode := E_System_Operating_Mode.MODE_SAFE_STOP;

ELSIF GVL_STATE.G_Safety_Freeze_Risk THEN
    GVL_STATE.G_System_Mode := E_System_Operating_Mode.MODE_FREEZE_PROTECTION;

ELSIF GVL_STATE.G_Freeze_Hardware_Degraded OR GVL_STATUS.G_Diagnostics.IO_Offline THEN
    GVL_STATE.G_System_Mode := E_System_Operating_Mode.MODE_DEGRADED;

ELSE
    GVL_STATE.G_System_Mode := GVL_STATE.G_System_Mode;
END_IF;

// === AUTO-RECOVERY FROM DEGRADED ===
// Disabled in current compile pass: mode recovery is handled by PRG_System / StateManager.


"""

new = """// === SYSTEM MODE OWNERSHIP ===
// System mode is owned exclusively by PRG_System via:
// FB_System_Health -> FB_State_Manager -> GVL_STATE.G_System_Mode.
// PRG_Safety must publish safety facts / latched conditions only and must not
// perform parallel mode arbitration here.

"""

count = text.count(old)
if count != 1:
    raise SystemExit(f'Expected exactly one target block in PRG_Safety.st, got {count}')

text = text.replace(old, new)
path.write_text(text, encoding='utf-8')
print('OK: removed parallel system mode arbitration from PRG_Safety.st')
