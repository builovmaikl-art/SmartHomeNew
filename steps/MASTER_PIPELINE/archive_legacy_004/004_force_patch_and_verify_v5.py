from pathlib import Path
import subprocess
import sys

TARGET = Path('steps/MASTER_PIPELINE/004_import_dut.py')
VERIFY = Path('steps/MASTER_PIPELINE/004_patch_verify_v5.log')

text = TARGET.read_text(encoding='utf-8')
start = text.index('def parse_enum(block: str):')
end = text.index('\n\ndef parse_struct_fields', start)
new_func = '''def parse_enum(block: str):
    name, body = split_header_body(block)
    if not name:
        return None

    m = re.match(
        r'(?is)^\(\s*(.*?)\s*\)\s*:?[ \t]*([A-Za-z_][A-Za-z0-9_]*)?\s*;?\s*$',
        body,
        flags=re.S,
    )
    if not m:
        return None

    values_raw = m.group(1).strip()
    base_type = (m.group(2) or 'INT').strip()
    parts = [p.strip() for p in values_raw.split(',') if p.strip()]
    values = []
    auto = 0

    for part in parts:
        mm = re.match(r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*(?::=\s*([^\s,]+))?\s*$', part)
        if not mm:
            return None
        vname = mm.group(1)
        explicit = mm.group(2)
        if explicit is not None:
            values.append((vname, explicit))
            try:
                auto = int(explicit, 0) + 1
            except Exception:
                auto += 1
        else:
            values.append((vname, str(auto)))
            auto += 1

    return {"kind": "ENUM", "name": name, "base_type": base_type, "values": values}
'''
text = text[:start] + new_func + text[end:]
TARGET.write_text(text, encoding='utf-8')

verify_text = TARGET.read_text(encoding='utf-8')
block = verify_text[verify_text.index('def parse_enum(block: str):'):verify_text.index('\n\ndef parse_struct_fields', verify_text.index('def parse_enum(block: str):'))]
VERIFY.write_text(block + '\n', encoding='utf-8')
print('patched and verified parse_enum v5')
