from pathlib import Path
import re
import uuid
import sys

BASE = Path("steps/MASTER_PIPELINE/003_RESULT.xml")
OUT = Path("steps/MASTER_PIPELINE/004_RESULT.xml")
LOG = Path("steps/MASTER_PIPELINE/004_import_dut_v11.log")
ROOT = Path(".")

TYPE_PREFIXES = ("E_", "ST_")


def new_guid() -> str:
    return str(uuid.uuid4())


def esc(s: str) -> str:
    return (s.replace("&", "&amp;")
             .replace("<", "&lt;")
             .replace(">", "&gt;")
             .replace('"', "&quot;"))


def normalize_ws(s: str) -> str:
    return s.replace("\r\n", "\n").replace("\r", "\n")


def strip_comments(text: str) -> str:
    text = re.sub(r'\(\*.*?\*\)', '', text, flags=re.S)
    text = re.sub(r'//.*', '', text)
    text = re.sub(r'(?m)^\s*\{[^\n]*\}\s*$', '', text)
    return text


def parse_type_blocks(text: str):
    text = normalize_ws(text)
    text = strip_comments(text)
    out = []
    for m in re.finditer(r'(?is)\bTYPE\b(.*?)\bEND_TYPE\b', text):
        block = m.group(1).strip()
        if block:
            out.append(block)
    return out


def split_header_body(block: str):
    m = re.match(r'(?is)^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*)$', block, flags=re.S)
    if not m:
        return None, None
    return m.group(1).strip(), m.group(2).strip()


def parse_enum(block: str):
    name, body = split_header_body(block)
    if not name:
        return None
    m = re.match(r'(?is)^\(\s*(.*?)\s*\)\s*:?[ \t]*([A-Za-z_][A-Za-z0-9_]*)?\s*;?\s*$', body, flags=re.S)
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


def parse_struct_fields(body: str):
    lines = [ln.strip() for ln in normalize_ws(body).split('\n')]
    fields = []
    for ln in lines:
        if not ln:
            continue
        if ln.endswith(';'):
            ln = ln[:-1].strip()
        m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.+)$', ln)
        if not m:
            continue
        fname = m.group(1).strip()
        rest = m.group(2).strip()
        finit = None
        if ':=' in rest:
            ftype, finit = rest.split(':=', 1)
            ftype = ftype.strip()
            finit = finit.strip() or None
        else:
            ftype = rest.strip()
        fields.append((fname, ftype, finit))
    return fields


def parse_struct(block: str):
    name, body = split_header_body(block)
    if not name:
        return None
    m = re.match(r'(?is)^STRUCT\s*(.*?)\s*END_STRUCT\s*;?\s*$', body, flags=re.S)
    if not m:
        return None
    return {"kind": "STRUCT", "name": name, "fields": parse_struct_fields(m.group(1))}


def build_type_ref(type_name: str) -> str:
    tn = type_name.strip()
    simple = {
        'BOOL','BYTE','WORD','DWORD','LWORD',
        'SINT','USINT','INT','UINT','DINT','UDINT','LINT','ULINT',
        'REAL','LREAL','TIME','LTIME','DATE','LDATE',
        'TIME_OF_DAY','TOD','LTOD','DATE_AND_TIME','DT','LDT',
        'STRING','WSTRING'
    }
    if tn.upper() in simple:
        return f'<{tn.upper()} />'
    m = re.match(r'(?is)^STRING\s*\[\s*([0-9]+)\s*\]$', tn)
    if m:
        return f'<string length="{m.group(1)}" />'
    m = re.match(r'(?is)^WSTRING\s*\[\s*([0-9]+)\s*\]$', tn)
    if m:
        return f'<wstring length="{m.group(1)}" />'
    m = re.match(r'(?is)^ARRAY\s*\[\s*([0-9]+)\s*\.\.\s*([0-9]+)\s*\]\s+OF\s+(.+)$', tn)
    if m:
        lo, hi, inner = m.group(1), m.group(2), m.group(3).strip()
        inner_xml = build_type_ref(inner)
        return f'<array><dimension lower="{lo}" upper="{hi}" /><baseType>{inner_xml}</baseType></array>'
    return f'<derived name="{esc(tn)}" />'


def build_enum_xml(item):
    oid = new_guid()
    values_xml = '\n'.join(
        f'              <value name="{esc(name)}" value="{esc(val)}" />'
        for name, val in item['values']
    )
    xml = f'''      <dataType name="{esc(item['name'])}">
        <baseType>
          <enum>
            <values>
{values_xml}
            </values>
            <baseType>
              <{item['base_type'].upper()} />
            </baseType>
          </enum>
        </baseType>
        <addData>
          <data name="http://www.3s-software.com/plcopenxml/objectid" handleUnknown="discard">
            <ObjectId>{oid}</ObjectId>
          </data>
        </addData>
      </dataType>'''
    obj = f'            <Object Name="{esc(item["name"])}" ObjectId="{oid}" />'
    return xml, obj


def is_simple_scalar(value: str) -> bool:
    v = value.strip()
    if not v:
        return False
    if re.fullmatch(r'TRUE|FALSE', v, flags=re.IGNORECASE):
        return True
    if re.fullmatch(r'[+-]?\d+', v):
        return True
    if re.fullmatch(r'[+-]?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?', v):
        return True
    if re.fullmatch(r"'[^']*'", v):
        return True
    if re.fullmatch(r'[A-Za-z_][A-Za-z0-9_\.]*', v):
        return True
    if re.fullmatch(r'(?:T|TOD|DT|DATE)#[^\s]+', v, flags=re.IGNORECASE):
        return True
    return False


def split_top_level_csv(text: str):
    parts = []
    buf = []
    depth_round = 0
    depth_square = 0
    in_string = False
    i = 0
    while i < len(text):
        ch = text[i]
        if ch == "'":
            buf.append(ch)
            if in_string:
                if i + 1 < len(text) and text[i + 1] == "'":
                    buf.append(text[i + 1])
                    i += 1
                else:
                    in_string = False
            else:
                in_string = True
        elif in_string:
            buf.append(ch)
        elif ch == '(':
            depth_round += 1
            buf.append(ch)
        elif ch == ')':
            depth_round = max(0, depth_round - 1)
            buf.append(ch)
        elif ch == '[':
            depth_square += 1
            buf.append(ch)
        elif ch == ']':
            depth_square = max(0, depth_square - 1)
            buf.append(ch)
        elif ch == ',' and depth_round == 0 and depth_square == 0:
            part = ''.join(buf).strip()
            if part:
                parts.append(part)
            buf = []
        else:
            buf.append(ch)
        i += 1
    tail = ''.join(buf).strip()
    if tail:
        parts.append(tail)
    return parts


def render_initializer_xml(finit: str):
    v = finit.strip()
    if not v:
        return '', 'none'
    if v.startswith('[') and v.endswith(']'):
        inner = v[1:-1].strip()
        values = [] if not inner else split_top_level_csv(inner)
        value_nodes = []
        for part in values:
            value_nodes.append(
                '                  <value>\n'
                '                    <simpleValue value="' + esc(part.strip()) + '" />\n'
                '                  </value>'
            )
        xml = (
            '\n              <initialValue>'
            '\n                <arrayValue>\n' + '\n'.join(value_nodes) + '\n'
            '                </arrayValue>'
            '\n              </initialValue>'
        )
        return xml, 'array'
    if is_simple_scalar(v) or '(' in v or ')' in v:
        xml = (
            '\n              <initialValue>'
            '\n                <simpleValue value="' + esc(v) + '" />'
            '\n              </initialValue>'
        )
        return xml, 'scalar'
    return '', 'unsupported'


def build_struct_xml(item):
    oid = new_guid()
    vars_xml = []
    with_initializer = 0
    without_initializer = 0
    array_initializer = 0
    unsupported_initializer = 0

    for field in item['fields']:
        if len(field) == 2:
            fname, ftype = field
            finit = None
        else:
            fname, ftype, finit = field

        tref = build_type_ref(ftype)
        init_xml = ''
        if finit is None:
            without_initializer += 1
        else:
            init_xml, kind = render_initializer_xml(finit)
            if kind in ('scalar', 'array'):
                with_initializer += 1
                if kind == 'array':
                    array_initializer += 1
            else:
                without_initializer += 1
                unsupported_initializer += 1

        vars_xml.append(
            '            <variable name="' + esc(fname) + '">\n'
            '              <type>\n'
            '                ' + tref + '\n'
            '              </type>' + init_xml + '\n'
            '            </variable>'
        )

    summary = (
        f"STRUCT {item['name']}: total={len(item['fields'])} "
        f"with_initializer={with_initializer} "
        f"without_initializer={without_initializer} "
        f"array_initializer={array_initializer} "
        f"unsupported_initializer={unsupported_initializer}"
    )

    vars_block = '\n'.join(vars_xml)
    xml = (
        '      <dataType name="' + esc(item['name']) + '">\n'
        '        <baseType>\n'
        '          <struct>\n' + vars_block + '\n'
        '          </struct>\n'
        '        </baseType>\n'
        '        <addData>\n'
        '          <data name="http://www.3s-software.com/plcopenxml/objectid" handleUnknown="discard">\n'
        '            <ObjectId>' + oid + '</ObjectId>\n'
        '          </data>\n'
        '        </addData>\n'
        '      </dataType>'
    )
    obj = '            <Object Name="' + esc(item['name']) + '" ObjectId="' + oid + '" />'
    return xml, obj, summary, with_initializer, array_initializer, unsupported_initializer


def find_matching_folder_end(text: str, folder_start: int) -> int:
    pos = folder_start
    depth = 0
    while True:
        next_open = text.find('<Folder Name="', pos)
        next_close = text.find('</Folder>', pos)
        if next_close < 0:
            raise RuntimeError('Unbalanced Folder tags')
        if next_open != -1 and next_open < next_close:
            depth += 1
            pos = next_open + 1
            continue
        depth -= 1
        pos = next_close + len('</Folder>')
        if depth == 0:
            return pos


def replace_dut_folder(xml: str) -> str:
    marker = '<Folder Name="DUT">'
    start = xml.find(marker)
    if start < 0:
        raise RuntimeError('DUT folder not found in ProjectStructure')
    end = find_matching_folder_end(xml, start)
    new_block = '''<Folder Name="DUT">
          <Folder Name="ENUM">
          </Folder>
          <Folder Name="STRUCT">
          </Folder>
        </Folder>'''
    return xml[:start] + new_block + xml[end:]


def remove_old_dut_datatypes(xml: str):
    m = re.search(r'(<dataTypes>)(.*?)(</dataTypes>)', xml, flags=re.S)
    if not m:
        raise RuntimeError('dataTypes container not found')
    body = m.group(2)
    removed = 0
    def repl(mm):
        nonlocal removed
        name = mm.group(1)
        if name.startswith(TYPE_PREFIXES):
            removed += 1
            return ''
        return mm.group(0)
    body = re.sub(r'<dataType\b[^>]*name="([^"]+)"[^>]*>.*?</dataType>', repl, body, flags=re.S)
    xml = xml[:m.start(2)] + body + xml[m.end(2):]
    return xml, removed


def insert_before_closing(xml: str, closing_tag: str, insert_text: str) -> str:
    idx = xml.rfind(closing_tag)
    if idx < 0:
        raise RuntimeError(f'Closing tag not found: {closing_tag}')
    return xml[:idx] + insert_text + '\n' + xml[idx:]


def insert_into_child_folder(xml: str, parent_folder: str, child_folder: str, append_text: str) -> str:
    parent_marker = f'<Folder Name="{parent_folder}">'
    child_marker = f'<Folder Name="{child_folder}">'
    parent_start = xml.find(parent_marker)
    if parent_start < 0:
        raise RuntimeError(f'Parent folder {parent_folder} not found')
    parent_end = find_matching_folder_end(xml, parent_start)
    child_start = xml.find(child_marker, parent_start, parent_end)
    if child_start < 0:
        raise RuntimeError(f'Child folder {child_folder} not found inside {parent_folder}')
    child_end = find_matching_folder_end(xml, child_start)
    insert_at = xml.rfind('</Folder>', child_start, child_end)
    if insert_at < 0:
        raise RuntimeError(f'Child folder closing tag not found for {child_folder}')
    payload = ('\n' + append_text) if append_text.strip() else ''
    return xml[:insert_at] + payload + '\n' + xml[insert_at:]


def main():
    if not BASE.exists():
        print(f'ERROR: base xml not found: {BASE}')
        sys.exit(1)
    xml = BASE.read_text(encoding='utf-8', errors='replace')
    dut_files = sorted(ROOT.glob('*.dut'))
    if not dut_files:
        LOG.write_text('NO_DUT_FILES_FOUND\n', encoding='utf-8')
        print('NO_DUT_FILES_FOUND')
        sys.exit(1)

    enum_types = []
    struct_types = []
    log = []
    struct_summaries = []
    struct_fields_total = 0
    struct_fields_with_initializer = 0
    initializers_inserted = 0
    array_initializers_inserted = 0
    unsupported_initializers_total = 0

    for f in dut_files:
        text = f.read_text(encoding='utf-8', errors='replace')
        blocks = parse_type_blocks(text)
        if not blocks:
            log.append(f'{f.name}: no TYPE block')
            continue
        for block in blocks:
            item = parse_enum(block)
            if item:
                enum_types.append(item)
                log.append(f"{f.name}: ENUM {item['name']} values={len(item['values'])}")
                continue
            item = parse_struct(block)
            if item:
                struct_types.append(item)
                struct_fields_total += len(item['fields'])
                struct_fields_with_initializer += sum(1 for field in item['fields'] if len(field) >= 3 and field[2] is not None)
                log.append(f"{f.name}: STRUCT {item['name']} fields={len(item['fields'])}")
                continue
            name, _ = split_header_body(block)
            log.append(f"{f.name}: SKIP unsupported TYPE {name or 'UNKNOWN'}")

    xml, removed = remove_old_dut_datatypes(xml)
    xml = replace_dut_folder(xml)

    enum_xml_blocks = []
    enum_objs = []
    for item in enum_types:
        x, o = build_enum_xml(item)
        enum_xml_blocks.append(x)
        enum_objs.append(o)

    struct_xml_blocks = []
    struct_objs = []
    for item in struct_types:
        x, o, summary, inserted_count, array_count, unsupported_count = build_struct_xml(item)
        struct_xml_blocks.append(x)
        struct_objs.append(o)
        struct_summaries.append(summary)
        initializers_inserted += inserted_count
        array_initializers_inserted += array_count
        unsupported_initializers_total += unsupported_count

    all_blocks = enum_xml_blocks + struct_xml_blocks
    xml = insert_before_closing(xml, '</dataTypes>', '\n'.join(all_blocks))
    if enum_objs:
        xml = insert_into_child_folder(xml, 'DUT', 'ENUM', '\n'.join(enum_objs))
    if struct_objs:
        xml = insert_into_child_folder(xml, 'DUT', 'STRUCT', '\n'.join(struct_objs))

    OUT.write_text(xml, encoding='utf-8')
    xml_initial_value_count = xml.count('<initialValue>')
    xml_array_value_count = xml.count('<arrayValue>')

    summary = [
        f'DUT_FILES={len(dut_files)}',
        f'REMOVED_OLD_DUT_DATATYPES={removed}',
        f'ENUM_INSERTED={len(enum_types)}',
        f'STRUCT_INSERTED={len(struct_types)}',
        f'STRUCT_FIELDS_TOTAL={struct_fields_total}',
        f'STRUCT_FIELDS_WITH_INITIALIZER={struct_fields_with_initializer}',
        f'INITIALIZERS_INSERTED={initializers_inserted}',
        f'ARRAY_INITIALIZERS_INSERTED={array_initializers_inserted}',
        f'UNSUPPORTED_INITIALIZERS={unsupported_initializers_total}',
        f'XML_INITIALVALUE_TAGS={xml_initial_value_count}',
        f'XML_ARRAYVALUE_TAGS={xml_array_value_count}',
        ''
    ]
    summary.extend(log)
    summary.append('')
    summary.extend(struct_summaries)
    LOG.write_text('\n'.join(summary), encoding='utf-8')

    print('004 OK')
    print(f'DUT_FILES={len(dut_files)}')
    print(f'REMOVED_OLD_DUT_DATATYPES={removed}')
    print(f'ENUM_INSERTED={len(enum_types)}')
    print(f'STRUCT_INSERTED={len(struct_types)}')
    print(f'STRUCT_FIELDS_TOTAL={struct_fields_total}')
    print(f'STRUCT_FIELDS_WITH_INITIALIZER={struct_fields_with_initializer}')
    print(f'INITIALIZERS_INSERTED={initializers_inserted}')
    print(f'ARRAY_INITIALIZERS_INSERTED={array_initializers_inserted}')
    print(f'UNSUPPORTED_INITIALIZERS={unsupported_initializers_total}')
    print(f'XML_INITIALVALUE_TAGS={xml_initial_value_count}')
    print(f'XML_ARRAYVALUE_TAGS={xml_array_value_count}')


if __name__ == '__main__':
    main()
