# Общая библиотека генерации PLCopen XML
# Используется в DUT, PRG, далее FB и др.

import re

def esc(s: str) -> str:
    return (s.replace("&", "&amp;")
             .replace("<", "&lt;")
             .replace(">", "&gt;")
             .replace('"', "&quot;"))

def parse_variable_line(line: str):
    line = line.strip()
    if not line or ':' not in line:
        return None

    if line.endswith(';'):
        line = line[:-1]

    name, rest = line.split(':', 1)
    name = name.strip()
    rest = rest.strip()

    init = None
    if ':=' in rest:
        type_part, init = rest.split(':=', 1)
        type_part = type_part.strip()
        init = init.strip()
    else:
        type_part = rest

    return {
        "name": name,
        "type": type_part.strip(),
        "init": init
    }

def build_type_ref(type_name: str) -> str:
    tn = type_name.strip().upper()

    simple = {
        'BOOL','BYTE','WORD','DWORD','LWORD',
        'SINT','USINT','INT','UINT','DINT','UDINT','LINT','ULINT',
        'REAL','LREAL'
    }

    if tn in simple:
        return f'<{tn} />'

    m = re.match(r'^ARRAY\[(\d+)\.\.(\d+)\]\s+OF\s+(.+)$', type_name, re.I)
    if m:
        lo, hi, inner = m.group(1), m.group(2), m.group(3)
        inner_xml = build_type_ref(inner)
        return f'<array><dimension lower="{lo}" upper="{hi}" /><baseType>{inner_xml}</baseType></array>'

    return f'<derived name="{esc(type_name)}" />'

def split_array(text: str):
    inner = text[1:-1]
    return [x.strip() for x in inner.split(',') if x.strip()]

def build_initializer_xml(init: str):
    if not init:
        return ""

    init = init.strip()

    if init.startswith('[') and init.endswith(']'):
        parts = split_array(init)
        values = "\n".join(
            f'                  <value><simpleValue value="{esc(p)}" /></value>'
            for p in parts
        )
        return f"""
              <initialValue>
                <arrayValue>
{values}
                </arrayValue>
              </initialValue>"""

    return f"""
              <initialValue>
                <simpleValue value="{esc(init)}" />
              </initialValue>"""

def build_variable_xml(var):
    name = var["name"]
    type_xml = build_type_ref(var["type"])
    init_xml = build_initializer_xml(var["init"])

    return f"""
            <variable name="{esc(name)}">
              <type>
                {type_xml}
              </type>{init_xml}
            </variable>"""
