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
// PRG_Safety must publish safety facts, latched conditions, diagnostics and
// safety-related commands only.
// System mode is owned exclusively by PRG_System via:
// FB_System_Health -> FB_State_Manager -> GVL_STATE.G_System_Mode.
// Any mode arbitration logic must stay out of PRG_Safety to preserve a single
// source of truth for runtime mode.

"""

count = text.count(old)
if count != 1:
    raise SystemExit(f'Expected exactly one system mode arbitration block, got {count}')

text = text.replace(old, new)
path.write_text(text, encoding='utf-8')
print('OK: removed system mode ownership from PRG_Safety')
