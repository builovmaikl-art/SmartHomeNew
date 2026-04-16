#!/usr/bin/env python3
from pathlib import Path
import re
import sys

TARGET = Path('steps/MASTER_PIPELINE/004_import_dut_v6.py')
text = TARGET.read_text(encoding='utf-8')
original = text

# -----------------------------------------------------------------------------
# 1) Replace parse_struct_fields() so STRUCT parsing keeps optional initializer.
#    Return format becomes: (field_name, field_type, field_initializer_or_None)
# -----------------------------------------------------------------------------
parse_pattern = re.compile(
    r"def parse_struct_fields\(.*?\n(?=def )",
    re.DOTALL,
)

parse_replacement = '''def parse_struct_fields(body: str):
    """Parse STRUCT fields preserving optional initializer.

    Supported examples:
        A : INT;
        B : BOOL := TRUE;
        C : REAL := 0.0;
        D : E_Mode := E_Mode.Auto;
        E : STRING(20) := 'abc';

    Returns a list of tuples:
        (field_name, field_type, field_initializer_or_None)
    """
    fields = []

    for raw_line in body.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if line.startswith('//'):
            continue
        if line.startswith('(*') and line.endswith('*)'):
            continue

        if ';' not in line or ':' not in line:
            continue

        line = line.split('//', 1)[0].strip()
        if not line:
            continue

        # keep only one declaration per line
        decl = line.split(';', 1)[0].strip()
        if ':' not in decl:
            continue

        name, rest = decl.split(':', 1)
        name = name.strip()
        rest = rest.strip()
        if not name or not rest:
            continue

        initializer = None
        if ':=' in rest:
            field_type, initializer = rest.split(':=', 1)
            field_type = field_type.strip()
            initializer = initializer.strip()
            if initializer == '':
                initializer = None
        else:
            field_type = rest.strip()

        if field_type:
            fields.append((name, field_type, initializer))

    return fields

'''

text, parse_count = parse_pattern.subn(parse_replacement, text, count=1)
if parse_count != 1:
    print('ERROR: parse_struct_fields() replacement failed')
    sys.exit(1)

# -----------------------------------------------------------------------------
# 2) Replace build_struct_xml() so optional initializer is emitted into XML.
#    ENUM logic stays untouched.
# -----------------------------------------------------------------------------
build_pattern = re.compile(
    r"def build_struct_xml\(.*?\n(?=def )",
    re.DOTALL,
)

build_replacement = '''def build_struct_xml(dt_name: str, fields):
    dt = ET.Element(q('dataType'), {'name': dt_name})
    bt = ET.SubElement(dt, q('baseType'))
    st = ET.SubElement(bt, q('struct'))

    stats = {
        'total': 0,
        'with_initializer': 0,
        'without_initializer': 0,
        'unsupported_initializer': 0,
    }

    def _simple_initializer_kind(value: str):
        v = value.strip()
        if not v:
            return None
        if re.fullmatch(r"TRUE|FALSE", v, flags=re.IGNORECASE):
            return 'simple'
        if re.fullmatch(r"[+-]?\d+", v):
            return 'simple'
        if re.fullmatch(r"[+-]?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?", v):
            return 'simple'
        if re.fullmatch(r"'[^"]*'", v):
            return 'simple'
        if re.fullmatch(r'[A-Za-z_][A-Za-z0-9_\.]*', v):
            return 'simple'
        if re.fullmatch(r"(?:T|TOD|DT|DATE)#[^\s]+", v, flags=re.IGNORECASE):
            return 'simple'
        return None

    for item in fields:
        stats['total'] += 1

        if len(item) == 2:
            fname, ftype = item
            finit = None
        else:
            fname, ftype, finit = item

        var = ET.SubElement(st, q('variable'), {'name': fname})
        t = ET.SubElement(var, q('type'))
        append_type_node(t, ftype)

        if finit is None:
            stats['without_initializer'] += 1
            continue

        kind = _simple_initializer_kind(finit)
        if kind == 'simple':
            iv = ET.SubElement(var, q('initialValue'))
            ET.SubElement(iv, q('simpleValue'), {'value': finit})
            stats['with_initializer'] += 1
        else:
            stats['unsupported_initializer'] += 1
            stats['without_initializer'] += 1
            print(f"WARN: unsupported STRUCT initializer kept for follow-up: {dt_name}.{fname} := {finit}")

    print(
        f"STRUCT {dt_name}: total={stats['total']} "
        f"with_initializer={stats['with_initializer']} "
        f"without_initializer={stats['without_initializer']} "
        f"unsupported_initializer={stats['unsupported_initializer']}"
    )
    return dt

'''

text, build_count = build_pattern.subn(build_replacement, text, count=1)
if build_count != 1:
    print('ERROR: build_struct_xml() replacement failed')
    sys.exit(1)

if text == original:
    print('ERROR: target file unchanged')
    sys.exit(1)

TARGET.write_text(text, encoding='utf-8')
print('OK: patched 004_import_dut_v6.py for generic STRUCT initializer support')
