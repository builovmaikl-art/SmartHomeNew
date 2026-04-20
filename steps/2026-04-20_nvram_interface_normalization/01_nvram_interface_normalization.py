#!/usr/bin/env python3
from pathlib import Path

path = Path("FB_NVRAM_Manager.st")
text = path.read_text(encoding="utf-8")

# 1. Обновляем комментарий VI_Command
old_comment = "    VI_Command                  : BYTE; // 1=WRITE, 2=READ\n"
new_comment = "    VI_Command                  : BYTE; // 1=WRITE (READ not implemented)\n"

if old_comment not in text:
    raise SystemExit("VI_Command comment not found")

text = text.replace(old_comment, new_comment, 1)

# 2. Добавляем явный guard для READ
insert_anchor = "IF VI_Command = 1 THEN // ЗАПИСЬ (WRITE)"
guard_block = """IF VI_Command = 2 THEN
    VO_Error := TRUE;
    VO_ErrorID := 16#150D;
    VO_HMI_Status_Message := 'NVRAM: READ not implemented';
    VO_Done := TRUE;
    RETURN;
END_IF;

"""

if insert_anchor not in text:
    raise SystemExit("WRITE block anchor not found")

text = text.replace(insert_anchor, guard_block + insert_anchor, 1)

path.write_text(text, encoding="utf-8")

print("OK: normalized NVRAM manager interface (READ disabled explicitly)")
