from pathlib import Path

p = Path('steps/MASTER_PIPELINE/004_import_dut.py')
text = p.read_text(encoding='utf-8')
old = """def parse_enum(block: str):\n    name, body = split_header_body(block)\n    if not name:\n        return None\n    m = re.search(r'(?is)^\\(\\s*(.*?)\\s*\\)\\s*(?::\\s*([A-Za-z_][A-Za-z0-9_]*))?\\s*;?\\s*$', body, flags=re.S)\n    if not m:\n        return None\n    values_raw = m.group(1).strip()\n    base_type = (m.group(2) or 'INT').strip()\n"""
new = """def parse_enum(block: str):\n    name, body = split_header_body(block)\n    if not name:\n        return None\n    m = re.match(\n        r'(?is)^\\(\\s*(.*?)\\s*\\)\\s*(?::\\s*)?([A-Za-z_][A-Za-z0-9_]*)?\\s*;?\\s*$',\n        body,\n        flags=re.S,\n    )\n    if not m:\n        return None\n    values_raw = m.group(1).strip()\n    base_type = (m.group(2) or 'INT').strip()\n"""
if old not in text:
    raise SystemExit('target snippet not found')
text = text.replace(old, new, 1)
p.write_text(text, encoding='utf-8')
print('patched parse_enum to v3')
