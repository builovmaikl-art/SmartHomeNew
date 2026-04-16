from pathlib import Path
import re
import sys
import uuid

PRIMITIVES = {"BOOL","INT","UINT","BYTE","WORD","DWORD","UDINT","REAL","TOD","TIME","DATE","DT","DINT","LREAL","STRING","WSTRING"}
TYPE_PREFIXES = ("E_", "ST_")


def esc(s):
    return str(s).replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')


def oid():
    return str(uuid.uuid4())


def normalize_ws(s: str) -> str:
    return s.replace("\r\n", "\n").replace("\r", "\n")


def find_project_root(start: Path) -> Path:
    cur = start.resolve()
    while True:
        if (cur / 'MAIN.st').exists() or (cur / '.git').exists():
            return cur
        if cur.parent == cur:
            return start.resolve()
        cur = cur.parent


def script_layout(script_file: Path):
    script_dir = script_file.resolve().parent
    project_root = find_project_root(script_dir)
    out_dir = script_dir / 'out'
    logs_dir = script_dir / 'logs'
    out_dir.mkdir(parents=True, exist_ok=True)
    logs_dir.mkdir(parents=True, exist_ok=True)
    base_xml = script_dir / 'Система умного дома.xml'
    xml_003 = out_dir / '003_RESULT.xml'
    xml_004 = out_dir / '004_RESULT.xml'
    log_001 = logs_dir / '001_universal_pou_gvl.log'
    log_004 = logs_dir / '004_import_dut_v11.log'
    return script_dir, project_root, base_xml, xml_003, xml_004, log_001, log_004


def log_write(path: Path, lines):
    path.write_text("\n".join(lines) + "\n", encoding='utf-8')


def ensure_folder(xml, name):
    if f'Folder Name="{name}"' in xml:
        return xml
    return re.sub(r'(</Folder>)(?!.*</Folder>)', rf'\1\n        <Folder Name="{name}">\n        </Folder>', xml, flags=re.S)


def repl_folder(xml, name, entries):
    m = re.search(rf'(<Folder Name="{name}">)(.*?)(</Folder>)', xml, re.S)
    if not m:
        raise RuntimeError(f'{name} folder not found')
    body = ''.join([f'\n          <Object Name="{esc(n)}" ObjectId="{i}" />' for n, i in entries])
    return xml[:m.start()] + m.group(1) + body + '\n        ' + m.group(3) + xml[m.end():]


# ---------------- POU/GVL ----------------
def detect_pou(raw_name):
    if raw_name == 'MAIN':
        return 'PLC_PRG', 'program', 'prg'
    if raw_name.startswith('FB_'):
        return raw_name, 'functionBlock', 'pous'
    if raw_name.startswith('F_'):
        return raw_name, 'function', 'pous'
    if raw_name.startswith('PRG_'):
        return raw_name, 'program', 'prg'
    return raw_name, 'functionBlock', 'pous'


def strip_inline_comments(line):
    line = re.sub(r'\(\*.*?\*\)', '', line)
    if '//' in line:
        line = line.split('//', 1)[0]
    return line.strip()


def extract_sections(st_text):
    section_specs = [
        ('VAR_INPUT', 'inputVars'),
        ('VAR_OUTPUT', 'outputVars'),
        ('VAR_IN_OUT', 'inOutVars'),
        ('VAR', 'localVars'),
    ]
    sections = []
    remaining = st_text
    for keyword, xml_tag in section_specs:
        pattern = re.compile(rf'(?im)^\s*{re.escape(keyword)}\b')
        while True:
            m = pattern.search(remaining)
            if not m:
                break
            end_m = re.search(r'(?im)^\s*END_VAR\b', remaining[m.end():])
            if not end_m:
                sections.append({'kind': keyword, 'xml_tag': xml_tag, 'body': None, 'error': f'Missing END_VAR for {keyword}'})
                break
            body_start = m.end()
            body_end = m.end() + end_m.start()
            body = remaining[body_start:body_end]
            sections.append({'kind': keyword, 'xml_tag': xml_tag, 'body': body, 'error': None})
            remaining = remaining[:m.start()] + remaining[m.end() + end_m.end():]
    return sections, remaining


def parse_var_block(body):
    variables = []
    bad_lines = []
    for raw_line in body.splitlines():
        cleaned = strip_inline_comments(raw_line)
        if not cleaned:
            continue
        if ':' not in cleaned:
            bad_lines.append(raw_line.rstrip())
            continue
        name_part, type_part = cleaned.split(':', 1)
        name = name_part.strip()
        type_name = type_part.strip().rstrip(';').strip()
        if not name or not type_name:
            bad_lines.append(raw_line.rstrip())
            continue
        variables.append((name, type_name))
    return variables, bad_lines


def build_simple_type_xml(type_name):
    t = type_name.strip()
    upper = t.upper()
    simple_map = {
        'BOOL': '<BOOL />', 'BYTE': '<BYTE />', 'WORD': '<WORD />', 'DWORD': '<DWORD />', 'LWORD': '<LWORD />',
        'SINT': '<SINT />', 'INT': '<INT />', 'DINT': '<DINT />', 'LINT': '<LINT />',
        'USINT': '<USINT />', 'UINT': '<UINT />', 'UDINT': '<UDINT />', 'ULINT': '<ULINT />',
        'REAL': '<REAL />', 'LREAL': '<LREAL />', 'TIME': '<TIME />', 'DATE': '<DATE />',
        'TIME_OF_DAY': '<TIME_OF_DAY />', 'TOD': '<TOD />', 'DATE_AND_TIME': '<DATE_AND_TIME />', 'DT': '<DT />',
        'STRING': '<STRING />', 'WSTRING': '<WSTRING />',
    }
    if upper in simple_map:
        return simple_map[upper]
    return f'<derived name="{esc(t)}" />'


def build_vars_xml(tag_name, variables):
    if not variables:
        return ''
    lines = [f'          <{tag_name}>']
    for name, type_name in variables:
        lines.append(f'            <variable name="{esc(name)}">')
        lines.append('              <type>')
        lines.append(f'                {build_simple_type_xml(type_name)}')
        lines.append('              </type>')
        lines.append('            </variable>')
    lines.append(f'          </{tag_name}>')
    return '\n'.join(lines)


def cleanup_code_text(xml_name, pou_type, code_text):
    if pou_type == 'functionBlock':
        code_text = re.sub(rf'(?im)^\s*FUNCTION_BLOCK\s+{re.escape(xml_name)}\b.*$', '', code_text)
        code_text = re.sub(r'(?im)^\s*END_FUNCTION_BLOCK\b.*$', '', code_text)
    elif pou_type == 'function':
        code_text = re.sub(rf'(?im)^\s*FUNCTION\s+{re.escape(xml_name)}\b.*$', '', code_text)
        code_text = re.sub(r'(?im)^\s*END_FUNCTION\b.*$', '', code_text)
    elif pou_type == 'program':
        raw_name = 'MAIN' if xml_name == 'PLC_PRG' else xml_name
        code_text = re.sub(rf'(?im)^\s*PROGRAM\s+{re.escape(raw_name)}\b.*$', '', code_text)
        code_text = re.sub(r'(?im)^\s*END_PROGRAM\b.*$', '', code_text)
    return '\n'.join(line for line in code_text.splitlines()).strip()


def build_pou_xml(xml_name, pou_type, interface_parts, code_text, object_id):
    interface_xml = '\n'.join(part for part in interface_parts if part)
    escaped_code = esc(code_text)
    return (
        f'      <pou name="{esc(xml_name)}" pouType="{pou_type}">\n'
        f'        <interface>\n{interface_xml}\n        </interface>\n'
        f'        <body>\n'
        f'          <ST>\n'
        f'            <xhtml xmlns="http://www.w3.org/1999/xhtml">{escaped_code}</xhtml>\n'
        f'          </ST>\n'
        f'        </body>\n'
        f'        <addData>\n'
        f'          <data name="http://www.3s-software.com/plcopenxml/objectid" handleUnknown="discard">\n'
        f'            <ObjectId>{object_id}</ObjectId>\n'
        f'          </data>\n'
        f'        </addData>\n'
        f'      </pou>'
    )


def parse_decl(line):
    if ':' not in line or ';' not in line:
        return None
    doc = None
    if '//' in line:
        line, doc = line.split('//', 1)
        doc = doc.strip()
    line = line.strip().rstrip(';')
    name, rest = line.split(':', 1)
    depth_sq = depth_par = 0
    in_str = False
    val_pos = -1
    i = 0
    while i < len(rest) - 1:
        ch = rest[i]
        if ch == "'" and (i == 0 or rest[i-1] != "\\"):
            in_str = not in_str
        elif not in_str:
            if ch == '[':
                depth_sq += 1
            elif ch == ']':
                depth_sq -= 1
            elif ch == '(':
                depth_par += 1
            elif ch == ')':
                depth_par -= 1
            elif rest[i:i+2] == ':=' and depth_sq == 0 and depth_par == 0:
                val_pos = i
                break
        i += 1
    if val_pos >= 0:
        typ = rest[:val_pos].strip()
        val = rest[val_pos+2:].strip()
    else:
        typ = rest.strip()
        val = None
    return name.strip(), typ, val, doc


def parse_type(t):
    t = t.strip()
    if t.upper() in PRIMITIVES:
        return f'<{t.upper()} />'
    m = re.match(r'STRING\s*\((\d+)\)$', t, re.I)
    if m:
        return f'<string length="{m.group(1)}" />'
    m = re.match(r'ARRAY\s*\[(.+?)\.\.(.+?)\]\s+OF\s+(.+)$', t, re.I)
    if m:
        low, high, base = m.groups()
        return f'<array><dimension lower="{esc(low)}" upper="{esc(high)}" /><baseType>{parse_type(base.strip())}</baseType></array>'
    return f'<derived name="{esc(t)}" />'


def split_array_items(val):
    inner = val[1:-1].strip()
    if not inner:
        return []
    items = []
    buf = ''
    depth_sq = depth_par = 0
    in_str = False
    for i, ch in enumerate(inner):
        if ch == "'" and (i == 0 or inner[i-1] != "\\"):
            in_str = not in_str
        elif not in_str:
            if ch == '[':
                depth_sq += 1
            elif ch == ']':
                depth_sq -= 1
            elif ch == '(':
                depth_par += 1
            elif ch == ')':
                depth_par -= 1
            elif ch == ',' and depth_sq == 0 and depth_par == 0:
                items.append(buf.strip())
                buf = ''
                continue
        buf += ch
    if buf.strip():
        items.append(buf.strip())
    return items


def build_var(name, typ, val, doc):
    t = parse_type(typ)
    init = ''
    if val:
        if val.startswith('[') and val.endswith(']'):
            items = split_array_items(val)
            vals = ''.join(f'<value><simpleValue value="{esc(i)}" /></value>' for i in items)
            init = f'<initialValue><arrayValue>{vals}</arrayValue></initialValue>'
        else:
            init = f'<initialValue><simpleValue value="{esc(val)}" /></initialValue>'
    d = f'<documentation>{esc(doc)}</documentation>' if doc else ''
    return f'<variable name="{esc(name)}"><type>{t}</type>{init}{d}</variable>'


def parse_gvl_file(txt):
    qualified = 'qualified_only' in txt.lower()
    sections = []
    cur = None
    for raw in txt.splitlines():
        l = raw.strip()
        if not l or l.startswith('{'):
            continue
        if l.upper().startswith('VAR_GLOBAL'):
            up = l.upper()
            mode = 'plain'
            if 'CONSTANT' in up:
                mode = 'constant'
            elif 'RETAIN' in up:
                mode = 'retain'
            cur = {'mode': mode, 'vars': []}
            sections.append(cur)
            continue
        if l.upper().startswith('END_VAR'):
            cur = None
            continue
        if cur is not None:
            v = parse_decl(l)
            if v:
                cur['vars'].append(v)
    return sections, qualified


def mode_attrs(mode):
    attrs = ''
    if mode == 'constant':
        attrs += ' constant="true"'
    if mode == 'retain':
        attrs += ' retain="true"'
    return attrs


def build_section_globalvars_xml(name, mode, vars_):
    vars_xml = ''.join(build_var(*v) for v in vars_)
    return f'<globalVars name="{esc(name)}"{mode_attrs(mode)}>{vars_xml}</globalVars>'


def build_gvl_entry(name, sections, qualified):
    object_id = oid()
    non_empty = [s for s in sections if s['vars']]
    if not non_empty:
        return None, None
    attr_block = ''
    if qualified:
        attr_block = (
            '<data name="http://www.3s-software.com/plcopenxml/attributes" handleUnknown="implementation">'
            '<Attributes><Attribute Name="qualified_only" Value="" /></Attributes>'
            '</data>'
        )
    if len(non_empty) == 1:
        sec = non_empty[0]
        outer = build_section_globalvars_xml(name, sec['mode'], sec['vars'])
        outer = outer.replace(
            '</globalVars>',
            '<addData>'
            f'{attr_block}'
            '<data name="http://www.3s-software.com/plcopenxml/objectid" handleUnknown="discard">'
            f'<ObjectId>{object_id}</ObjectId>'
            '</data>'
            '</addData>'
            '</globalVars>'
        )
    else:
        mixed_inner = ''.join(build_section_globalvars_xml(name, sec['mode'], sec['vars']) for sec in non_empty)
        outer = build_section_globalvars_xml(name, 'plain', non_empty[0]['vars'])
        outer = outer.replace(
            '</globalVars>',
            '<addData>'
            f'{attr_block}'
            '<data name="http://www.3s-software.com/plcopenxml/objectid" handleUnknown="discard">'
            f'<ObjectId>{object_id}</ObjectId>'
            '</data>'
            '<data name="http://www.3s-software.com/plcopenxml/mixedattrsvarlist" handleUnknown="implementation">'
            f'<MixedAttrsVarList>{mixed_inner}</MixedAttrsVarList>'
            '</data>'
            '</addData>'
            '</globalVars>'
        )
    gvl = ('<data name="http://www.3s-software.com/plcopenxml/globalvars" handleUnknown="implementation">' f'{outer}' '</data>')
    return gvl, (name, object_id)


def build_003(project_root: Path, base_xml: Path, out_xml: Path, log_file: Path):
    if not base_xml.exists():
        raise FileNotFoundError(f'Base XML not found: {base_xml}')
    xml = base_xml.read_text(encoding='utf-8', errors='ignore')
    logs = ['START']
    st_files = list(project_root.glob('FB_*.st')) + list(project_root.glob('F_*.st')) + list(project_root.glob('PRG_*.st'))
    main_file = project_root / 'MAIN.st'
    if main_file.exists():
        st_files.append(main_file)
    pou_blocks, pous_tree, prg_tree = [], [], []
    pou_warn = 0
    for f in st_files:
        raw_name = f.stem
        xml_name, pou_type, target = detect_pou(raw_name)
        object_id = oid()
        st_text = f.read_text(encoding='utf-8', errors='ignore')
        sections, code_without_vars = extract_sections(st_text)
        interface_parts = []
        local_warns = []
        for section in sections:
            if section['error']:
                local_warns.append(section['error'])
                continue
            variables, bad_lines = parse_var_block(section['body'])
            if bad_lines:
                local_warns.append(f'{section["kind"]}: unparsed lines={len(bad_lines)}')
            block_xml = build_vars_xml(section['xml_tag'], variables)
            if block_xml:
                interface_parts.append(block_xml)
        if local_warns:
            pou_warn += 1
        cleaned_code = cleanup_code_text(xml_name, pou_type, code_without_vars)
        pou_blocks.append(build_pou_xml(xml_name, pou_type, interface_parts, cleaned_code, object_id))
        if target == 'pous':
            pous_tree.append((xml_name, object_id))
        else:
            prg_tree.append((xml_name, object_id))
    gvl_blocks, gvl_tree = [], []
    for f in list(project_root.glob('GVL*.gvl')):
        sections, qualified = parse_gvl_file(f.read_text(encoding='utf-8', errors='ignore'))
        entry = build_gvl_entry(f.stem, sections, qualified)
        if entry == (None, None):
            continue
        g, obj = entry
        gvl_blocks.append(g)
        gvl_tree.append(obj)
    xml = re.sub(r'<pous>.*?</pous>', '<pous>\n' + '\n'.join(pou_blocks) + '\n</pous>', xml, flags=re.S)
    xml = ensure_folder(xml, 'PRG')
    xml = ensure_folder(xml, 'GVL')
    xml = repl_folder(xml, 'POUs', pous_tree)
    xml = repl_folder(xml, 'PRG', prg_tree)
    globalvars_pattern = re.compile(r'(<addData>\s*)(<data name="http://www\.3s-software\.com/plcopenxml/globalvars" handleUnknown="implementation">.*?</data>\s*)+(?=<data name="http://www\.3s-software\.com/plcopenxml/projectstructure")', re.DOTALL)
    xml, n_gvl = globalvars_pattern.subn(lambda m: m.group(1) + '\n' + '\n'.join(gvl_blocks) + '\n', xml)
    if n_gvl != 1:
        raise RuntimeError(f'GVL block replace failed: {n_gvl}')
    xml = repl_folder(xml, 'GVL', gvl_tree)
    out_xml.write_text(xml, encoding='utf-8')
    logs.extend([
        f'POU_BLOCKS={len(pou_blocks)}',
        f'PRG_OBJECTS={len(prg_tree)}',
        f'GVL_BLOCKS={len(gvl_blocks)}',
        f'POU_WARNINGS={pou_warn}',
        'DONE',
    ])
    log_write(log_file, logs)


# ---------------- DUT ----------------
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
    simple = {'BOOL','BYTE','WORD','DWORD','LWORD','SINT','USINT','INT','UINT','DINT','UDINT','LINT','ULINT','REAL','LREAL','TIME','LTIME','DATE','LDATE','TIME_OF_DAY','TOD','LTOD','DATE_AND_TIME','DT','LDT','STRING','WSTRING'}
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
    object_id = oid()
    values_xml = '\n'.join(f'              <value name="{esc(name)}" value="{esc(val)}" />' for name, val in item['values'])
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
            <ObjectId>{object_id}</ObjectId>
          </data>
        </addData>
      </dataType>'''
    obj = f'            <Object Name="{esc(item["name"])}" ObjectId="{object_id}" />'
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
    parts, buf = [], []
    depth_round = depth_square = 0
    in_string = False
    i = 0
    while i < len(text):
        ch = text[i]
        if ch == "'":
            buf.append(ch)
            if in_string:
                if i + 1 < len(text) and text[i + 1] == "'":
                    buf.append(text[i + 1]); i += 1
                else:
                    in_string = False
            else:
                in_string = True
        elif in_string:
            buf.append(ch)
        elif ch == '(':
            depth_round += 1; buf.append(ch)
        elif ch == ')':
            depth_round = max(0, depth_round - 1); buf.append(ch)
        elif ch == '[':
            depth_square += 1; buf.append(ch)
        elif ch == ']':
            depth_square = max(0, depth_square - 1); buf.append(ch)
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
            value_nodes.append('                  <value>\n                    <simpleValue value="' + esc(part.strip()) + '" />\n                  </value>')
        xml = '\n              <initialValue>\n                <arrayValue>\n' + '\n'.join(value_nodes) + '\n                </arrayValue>\n              </initialValue>'
        return xml, 'array'
    if is_simple_scalar(v) or '(' in v or ')' in v:
        xml = '\n              <initialValue>\n                <simpleValue value="' + esc(v) + '" />\n              </initialValue>'
        return xml, 'scalar'
    return '', 'unsupported'


def build_struct_xml(item):
    object_id = oid()
    vars_xml = []
    with_initializer = without_initializer = array_initializer = unsupported_initializer = 0
    for fname, ftype, finit in item['fields']:
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
        vars_xml.append('            <variable name="' + esc(fname) + '">\n              <type>\n                ' + tref + '\n              </type>' + init_xml + '\n            </variable>')
    summary = f"STRUCT {item['name']}: total={len(item['fields'])} with_initializer={with_initializer} without_initializer={without_initializer} array_initializer={array_initializer} unsupported_initializer={unsupported_initializer}"
    vars_block = '\n'.join(vars_xml)
    xml = '      <dataType name="' + esc(item['name']) + '">\n        <baseType>\n          <struct>\n' + vars_block + '\n          </struct>\n        </baseType>\n        <addData>\n          <data name="http://www.3s-software.com/plcopenxml/objectid" handleUnknown="discard">\n            <ObjectId>' + object_id + '</ObjectId>\n          </data>\n        </addData>\n      </dataType>'
    obj = '            <Object Name="' + esc(item['name']) + '" ObjectId="' + object_id + '" />'
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


def build_004(project_root: Path, xml_003: Path, out_xml: Path, log_file: Path):
    if not xml_003.exists():
        raise FileNotFoundError(f'003 xml not found: {xml_003}')
    xml = xml_003.read_text(encoding='utf-8', errors='replace')
    dut_files = sorted(project_root.glob('*.dut'))
    if not dut_files:
        raise RuntimeError('NO_DUT_FILES_FOUND')
    enum_types, struct_types, logs, struct_summaries = [], [], [], []
    struct_fields_total = struct_fields_with_initializer = initializers_inserted = array_initializers_inserted = unsupported_initializers_total = 0
    for f in dut_files:
        text = f.read_text(encoding='utf-8', errors='replace')
        blocks = parse_type_blocks(text)
        if not blocks:
            logs.append(f'{f.name}: no TYPE block')
            continue
        for block in blocks:
            item = parse_enum(block)
            if item:
                enum_types.append(item); logs.append(f"{f.name}: ENUM {item['name']} values={len(item['values'])}"); continue
            item = parse_struct(block)
            if item:
                struct_types.append(item)
                struct_fields_total += len(item['fields'])
                struct_fields_with_initializer += sum(1 for field in item['fields'] if len(field) >= 3 and field[2] is not None)
                logs.append(f"{f.name}: STRUCT {item['name']} fields={len(item['fields'])}")
                continue
            name, _ = split_header_body(block)
            logs.append(f"{f.name}: SKIP unsupported TYPE {name or 'UNKNOWN'}")
    xml, removed = remove_old_dut_datatypes(xml)
    xml = replace_dut_folder(xml)
    enum_xml_blocks, enum_objs = [], []
    for item in enum_types:
        x, o = build_enum_xml(item)
        enum_xml_blocks.append(x); enum_objs.append(o)
    struct_xml_blocks, struct_objs = [], []
    for item in struct_types:
        x, o, summary, inserted_count, array_count, unsupported_count = build_struct_xml(item)
        struct_xml_blocks.append(x); struct_objs.append(o); struct_summaries.append(summary)
        initializers_inserted += inserted_count
        array_initializers_inserted += array_count
        unsupported_initializers_total += unsupported_count
    all_blocks = enum_xml_blocks + struct_xml_blocks
    xml = insert_before_closing(xml, '</dataTypes>', '\n'.join(all_blocks))
    if enum_objs:
        xml = insert_into_child_folder(xml, 'DUT', 'ENUM', '\n'.join(enum_objs))
    if struct_objs:
        xml = insert_into_child_folder(xml, 'DUT', 'STRUCT', '\n'.join(struct_objs))
    out_xml.write_text(xml, encoding='utf-8')
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
    summary.extend(logs)
    summary.append('')
    summary.extend(struct_summaries)
    log_write(log_file, summary)


def main():
    script_dir, project_root, base_xml, xml_003, xml_004, log_001, log_004 = script_layout(Path(__file__))
    print(f'SCRIPT_DIR={script_dir}')
    print(f'PROJECT_ROOT={project_root}')
    print(f'BASE_XML={base_xml}')
    print(f'OUT_003={xml_003}')
    print(f'OUT_004={xml_004}')
    print(f'LOG_001={log_001}')
    print(f'LOG_004={log_004}')
    build_003(project_root, base_xml, xml_003, log_001)
    print('STEP_001_OK')
    build_004(project_root, xml_003, xml_004, log_004)
    print('STEP_004_OK')
    print('BUILD_OK')


if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f'BUILD_ERROR: {e}')
        sys.exit(1)
