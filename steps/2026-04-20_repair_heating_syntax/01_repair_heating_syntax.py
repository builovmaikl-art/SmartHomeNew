from pathlib import Path
import re

# -------------------------
# 1. FIX PRG_System (freeze request)
# -------------------------
p = Path("PRG_System.st")
text = p.read_text(encoding="utf-8")

# заменить опасную форму на безопасную
text = re.sub(
    r"GVL_STATE\.G_Freeze_Request\s*:=\s*\(.*?\);",
    """IF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_FREEZE_PROTECTION THEN
    GVL_STATE.G_Freeze_Request := TRUE;
ELSE
    GVL_STATE.G_Freeze_Request := FALSE;
END_IF;""",
    text,
    flags=re.S
)

p.write_text(text, encoding="utf-8")

# -------------------------
# 2. FIX Heating Manager (убрать кривые вставки)
# -------------------------
p = Path("FB_Heating_System_Manager.st")
text = p.read_text(encoding="utf-8")

# удалить любые строки, попавшие в VAR блок
text = re.sub(
    r"VAR.*?GVL_STATE\.G_Target_Temperature.*?END_VAR",
    lambda m: re.sub(r"GVL_STATE\.G_Target_Temperature.*\n", "", m.group(0)),
    text,
    flags=re.S
)

# нормализовать injection
text = re.sub(
    r"// --- HEATING TARGET INJECTION ---.*?END_IF;",
    """// --- HEATING TARGET INJECTION ---
IF GVL_STATE.G_Target_Temperature > 0.0 THEN
    L_Target_Supply_Temp := GVL_STATE.G_Target_Temperature;
END_IF;""",
    text,
    flags=re.S
)

p.write_text(text, encoding="utf-8")

# -------------------------
# 3. FIX PRG_Heating (убрать дубли)
# -------------------------
p = Path("PRG_Heating.st")
text = p.read_text(encoding="utf-8")

# оставить только один consolidated блок
blocks = re.findall(
    r"// --- CONSOLIDATED HEATING REQUEST.*?END_CASE;",
    text,
    flags=re.S
)

if len(blocks) > 1:
    text = text.replace(blocks[1], "")

p.write_text(text, encoding="utf-8")

print("OK: syntax repaired")
