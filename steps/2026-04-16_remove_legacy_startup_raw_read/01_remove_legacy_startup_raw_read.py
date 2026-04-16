from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

old_var = "    L_Config_Loaded : BOOL;\n"
if old_var not in text:
    raise SystemExit("Target variable L_Config_Loaded not found")
text = text.replace(old_var, "", 1)

old_block = """IF NOT L_Config_Loaded THEN
    // keep one startup READ for future recovery compatibility
    L_NVRAM_Cmd := 2;
    L_Config_Loaded := TRUE;

ELSIF GVL_CONFIG.G_HMI_Apply_Settings THEN
"""

new_block = """IF GVL_CONFIG.G_HMI_Apply_Settings THEN
"""

if old_block not in text:
    raise SystemExit("Target startup READ block not found")

text = text.replace(old_block, new_block, 1)
path.write_text(text, encoding="utf-8")
print("OK: removed legacy startup raw READ from PRG_System.st")
