from pathlib import Path
import re


def replace_once(text: str, pattern: str, replacement: str, name: str) -> str:
    new_text, count = re.subn(pattern, replacement, text, count=1, flags=re.DOTALL)
    if count != 1:
        raise SystemExit(f"Expected exactly one replacement for {name}, got {count}")
    return new_text


# 1) Create policy bridge GVL
Path('GVL_POLICY.gvl').write_text(
    """VAR_GLOBAL
    // Bridge from upstream orchestration into PRG_Policy.
    G_Rule_Preheat_Request : BOOL := FALSE;
END_VAR
""",
    encoding='utf-8'
)

# 2) Create policy program foundation
Path('PRG_Policy.st').write_text(
    """PROGRAM PRG_Policy
VAR
    L_i : INT;
END_VAR

// ============================================================
// POLICY LAYER FOUNDATION
// ============================================================
// This program owns policy-level request shaping that must not be
// duplicated across subsystem PRGs:
// - ventilation safety / degraded requests
// - heating request publication
// - evacuation guidance and activation

// ------------------------------------------------------------
// 1. Ventilation policy requests
// ------------------------------------------------------------
IF GVL_STATE.G_Safety_Smoke_Latched THEN
    GVL_COMMAND.G_Vent_Stop := TRUE;
    GVL_COMMAND.G_Supply_100_Req := FALSE;
    GVL_COMMAND.G_Supply_80_Req := FALSE;
    GVL_COMMAND.G_Vent_PV3_Boost := FALSE;
    GVL_COMMAND.G_Exhaust_100_Req := FALSE;
ELSIF GVL_STATE.G_Safety_Gas_Latched THEN
    GVL_COMMAND.G_Vent_PV3_Boost := TRUE;
    GVL_COMMAND.G_Supply_100_Req := TRUE;
    GVL_COMMAND.G_Vent_Stop := FALSE;
ELSIF GVL_HEALTH_BRIDGE.G_CO_Warning_Level OR GVL_HEALTH_BRIDGE.G_CO_Alarm_Level THEN
    GVL_COMMAND.G_Supply_80_Req := TRUE;
    GVL_COMMAND.G_Vent_Stop := FALSE;
END_IF;

IF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_DEGRADED THEN
    GVL_COMMAND.G_Vent_PV3_Boost := FALSE;
    GVL_COMMAND.G_Supply_100_Req := FALSE;
    GVL_COMMAND.G_Exhaust_100_Req := FALSE;
    GVL_COMMAND.G_Supply_80_Req := TRUE;
END_IF;

// ------------------------------------------------------------
// 2. Heating request publication
// ------------------------------------------------------------
GVL_STATE.G_Preheat_Request := GVL_POLICY.G_Rule_Preheat_Request;
GVL_STATE.G_Freeze_Request :=
    (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_FREEZE_PROTECTION);

// ------------------------------------------------------------
// 3. Evacuation guidance policy
// ------------------------------------------------------------
FOR L_i := 1 TO 32 DO
    GVL_STATE.G_Evac_Guidance[L_i] := 0;
    IF GVL_STATE.G_Evac_Hazard_Zone[L_i] THEN
        GVL_STATE.G_Evac_Guidance[L_i] := -1;
    END_IF;
    IF GVL_CONFIG.G_Evac_Exit_Zones[L_i] AND NOT GVL_STATE.G_Evac_Hazard_Zone[L_i] THEN
        GVL_STATE.G_Evac_Guidance[L_i] := 1;
    END_IF;
END_FOR;

GVL_STATUS.G_Evac_Target_Zone_Name := '';
GVL_STATUS.G_Evac_Hazard_Zone_Name := '';
FOR L_i := 1 TO 32 DO
    IF (GVL_STATUS.G_Evac_Hazard_Zone_Name = '') AND GVL_STATE.G_Evac_Hazard_Zone[L_i] THEN
        GVL_STATUS.G_Evac_Hazard_Zone_Name := GVL_CONFIG.G_Evac_Zone_Names[L_i];
        IF GVL_STATUS.G_Evac_Hazard_Zone_Name = '' THEN
            GVL_STATUS.G_Evac_Hazard_Zone_Name := CONCAT('Zone ', INT_TO_STRING(L_i));
        END_IF;
    END_IF;
    IF (GVL_STATUS.G_Evac_Target_Zone_Name = '') AND (GVL_STATE.G_Evac_Guidance[L_i] = 1) THEN
        GVL_STATUS.G_Evac_Target_Zone_Name := GVL_CONFIG.G_Evac_Zone_Names[L_i];
        IF GVL_STATUS.G_Evac_Target_Zone_Name = '' THEN
            GVL_STATUS.G_Evac_Target_Zone_Name := CONCAT('Zone ', INT_TO_STRING(L_i));
        END_IF;
    END_IF;
END_FOR;

IF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP AND GVL_STATE.G_Safety_Smoke_Latched THEN
    GVL_STATE.G_Evacuation_Lighting_Active := TRUE;
ELSE
    GVL_STATE.G_Evacuation_Lighting_Active := FALSE;
END_IF;
""",
    encoding='utf-8'
)

# 3) MAIN: insert PRG_Policy after PRG_System
main_path = Path('MAIN.st')
main_text = main_path.read_text(encoding='utf-8')
old = "PRG_System();\nPRG_Safety();"
new = "PRG_System();\nPRG_Policy();\nPRG_Safety();"
if old not in main_text:
    raise SystemExit('Expected MAIN fragment not found')
main_text = main_text.replace(old, new, 1)
main_path.write_text(main_text, encoding='utf-8')

# 4) PRG_System: keep only bridge publication
prg_system_path = Path('PRG_System.st')
prg_system_text = prg_system_path.read_text(encoding='utf-8')
prg_system_text = replace_once(
    prg_system_text,
    r"// 3\.6a\. Расчёт направленной эвакуации.*?// 4\. Астрономический таймер",
    "// 3.6a. Evacuation policy moved to PRG_Policy\n// 4. Астрономический таймер",
    'PRG_System evacuation block'
)
prg_system_text = replace_once(
    prg_system_text,
    r"// --- HEATING REQUEST WRITE LAYER ---.*?END_IF;\n\n\n\n",
    "// --- POLICY BRIDGE: rule-driven heating request ---\nGVL_POLICY.G_Rule_Preheat_Request := fbRuleEngine.VO_Preheat_Request;\n\n\n",
    'PRG_System heating request block'
)
prg_system_path.write_text(prg_system_text, encoding='utf-8')

# 5) PRG_Safety: remove ventilation request ownership
prg_safety_path = Path('PRG_Safety.st')
prg_safety_text = prg_safety_path.read_text(encoding='utf-8')
prg_safety_text = replace_once(
    prg_safety_text,
    r"// 3\.1 Вентиляционные команды: единый owner = PRG_Safety.*?// Формирование зон опасности для направленной эвакуации через программную конфигурацию\.",
    "// 3.1 Ventilation request ownership moved to PRG_Policy\n// PRG_Safety publishes safety facts / latches only.\n\n// Формирование зон опасности для направленной эвакуации через программную конфигурацию.",
    'PRG_Safety ventilation block'
)
prg_safety_path.write_text(prg_safety_text, encoding='utf-8')

# 6) PRG_Ventilation: remove local arbitration
prg_vent_path = Path('PRG_Ventilation.st')
prg_vent_text = prg_vent_path.read_text(encoding='utf-8')
prg_vent_text = replace_once(
    prg_vent_text,
    r"// === Ventilation Arbitration ===.*?// 11\. Управление вентиляцией",
    "// === Ventilation Arbitration ===\n// Request shaping is owned by PRG_Policy.\n// PRG_Ventilation consumes already-shaped requests only.\n\nL_Vent_PV3_Boost_Req := GVL_COMMAND.G_Vent_PV3_Boost;\nL_Supply_100_Req := GVL_COMMAND.G_Supply_100_Req;\nL_Exhaust_100_Req := GVL_COMMAND.G_Exhaust_100_Req;\nL_Supply_80_Req := GVL_COMMAND.G_Supply_80_Req;\nL_Vent_Stop_Req := GVL_COMMAND.G_Vent_Stop;\n\n// 11. Управление вентиляцией",
    'PRG_Ventilation arbitration block'
)
prg_vent_path.write_text(prg_vent_text, encoding='utf-8')

print('OK: extracted policy layer foundation')
