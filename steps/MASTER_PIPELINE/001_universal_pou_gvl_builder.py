# Combined universal builder v4
# POU part uses structured generation with interface sections
# GVL part uses strict step3-style generation
from pathlib import Path
import re
import uuid

SCRIPT_DIR = Path(__file__).resolve().parent
INPUT_XML = Path('Система умного дома.xml')
OUTPUT_XML = SCRIPT_DIR / '003_RESULT.xml'
LOG_FILE = SCRIPT_DIR / '001_universal_pou_gvl.log'
ROOT = Path.cwd()

PRIMITIVES = {"BOOL","INT","UINT","BYTE","WORD","DWORD","UDINT","REAL","TOD","TIME","DATE","DT","DINT","LREAL","STRING","WSTRING"}


def log(s: str):
    print(s)
    with LOG_FILE.open('a', encoding='utf-8') as f:
        f.write(s + '\n')


def esc(s):
    return str(s).replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')


def oid():
    return str(uuid.uuid4())


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


# ---------------- POU ----------------
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


def build_type_xml(type_name):
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
        lines.append(f'                {build_type_xml(type_name)}')
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


# ---------------- GVL ----------------
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
    gvl = (
        '<data name="http://www.3s-software.com/plcopenxml/globalvars" handleUnknown="implementation">'
        f'{outer}'
        '</data>'
    )
    obj = (name, object_id)
    return gvl, obj


def main():
    if LOG_FILE.exists():
        LOG_FILE.unlink()
    xml = INPUT_XML.read_text(encoding='utf-8', errors='ignore')
    log('START')

    # build POU registry
    st_files = list(ROOT.glob('FB_*.st')) + list(ROOT.glob('F_*.st')) + list(ROOT.glob('PRG_*.st'))
    main_file = ROOT / 'MAIN.st'
    if main_file.exists():
        st_files.append(main_file)

    pou_blocks = []
    pous_tree = []
    prg_tree = []
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

    # build GVL registry
    gvl_blocks = []
    gvl_tree = []
    for f in list(ROOT.glob('GVL*.gvl')):
        sections, qualified = parse_gvl_file(f.read_text(encoding='utf-8', errors='ignore'))
        entry = build_gvl_entry(f.stem, sections, qualified)
        if entry == (None, None):
            continue
        g, obj = entry
        gvl_blocks.append(g)
        gvl_tree.append(obj)

    # replace POU zones
    xml = re.sub(r'<pous>.*?</pous>', '<pous>\n' + '\n'.join(pou_blocks) + '\n</pous>', xml, flags=re.S)
    xml = ensure_folder(xml, 'PRG')
    xml = ensure_folder(xml, 'GVL')
    xml = repl_folder(xml, 'POUs', pous_tree)
    xml = repl_folder(xml, 'PRG', prg_tree)

    # replace GVL zones
    globalvars_pattern = re.compile(
        r'(<addData>\s*)(<data name="http://www\.3s-software\.com/plcopenxml/globalvars" handleUnknown="implementation">.*?</data>\s*)+(?=<data name="http://www\.3s-software\.com/plcopenxml/projectstructure")',
        re.DOTALL
    )
    xml, n_gvl = globalvars_pattern.subn(lambda m: m.group(1) + '\n' + '\n'.join(gvl_blocks) + '\n', xml)
    if n_gvl != 1:
        raise RuntimeError(f'GVL block replace failed: {n_gvl}')
    xml = repl_folder(xml, 'GVL', gvl_tree)

    OUTPUT_XML.write_text(xml, encoding='utf-8')
    log(f'POU_BLOCKS={len(pou_blocks)}')
    log(f'PRG_OBJECTS={len(prg_tree)}')
    log(f'GVL_BLOCKS={len(gvl_blocks)}')
    log(f'POU_WARNINGS={pou_warn}')
    log('DONE')


if __name__ == '__main__':
    main()
