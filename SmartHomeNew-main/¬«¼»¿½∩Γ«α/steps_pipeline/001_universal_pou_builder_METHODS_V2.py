from pathlib import Path
import re
import sys
import uuid
from typing import List, Tuple, Dict, Optional

SCRIPT_DIR = Path(__file__).resolve().parent
INPUT_XML = Path('Система умного дома.xml')
OUTPUT_XML = SCRIPT_DIR / '002_BASE.xml'
LOG_FILE = SCRIPT_DIR / '001_universal_methods_v2.log'
ROOT_DIR = Path.cwd()
ST_PATTERNS = ['FB_*.st', 'F_*.st', 'PRG_*.st']
MAIN_FILE = 'MAIN.st'
METHOD_MODIFIERS = ('PUBLIC', 'PRIVATE', 'PROTECTED', 'INTERNAL', 'FINAL', 'ABSTRACT', 'OVERRIDE', 'STATIC')


def log(msg: str) -> None:
    print(msg)
    with LOG_FILE.open('a', encoding='utf-8') as f:
        f.write(msg + '\n')


def xml_escape(text: str) -> str:
    return (text.replace('&', '&amp;')
                .replace('<', '&lt;')
                .replace('>', '&gt;')
                .replace('"', '&quot;'))


def make_object_id() -> str:
    return str(uuid.uuid4())


def strip_inline_comments(line: str) -> str:
    line = re.sub(r'\(\*.*?\*\)', '', line)
    if '//' in line:
        line = line.split('//', 1)[0]
    return line.strip()


def detect_pou(raw_name: str) -> Tuple[str, str, str]:
    if raw_name == 'MAIN':
        return 'PLC_PRG', 'program', 'prg'
    if raw_name.startswith('FB_'):
        return raw_name, 'functionBlock', 'pous'
    if raw_name.startswith('F_'):
        return raw_name, 'function', 'pous'
    if raw_name.startswith('PRG_'):
        return raw_name, 'program', 'prg'
    return raw_name, 'functionBlock', 'pous'


def extract_sections(st_text: str):
    section_specs = [
        ('VAR_INPUT', 'inputVars', False),
        ('VAR_OUTPUT', 'outputVars', False),
        ('VAR_IN_OUT', 'inOutVars', False),
        ('VAR CONSTANT', 'localVars', True),
        ('VAR', 'localVars', False),
    ]
    sections = []
    remaining = st_text

    for keyword, xml_tag, is_constant in section_specs:
        pattern = re.compile(rf'(?im)^\s*{re.escape(keyword)}\b')
        while True:
            m = pattern.search(remaining)
            if not m:
                break
            end_m = re.search(r'(?im)^\s*END_VAR\b', remaining[m.end():])
            if not end_m:
                sections.append({
                    'kind': keyword,
                    'xml_tag': xml_tag,
                    'is_constant': is_constant,
                    'body': None,
                    'error': f'Missing END_VAR for {keyword}'
                })
                break
            body_start = m.end()
            body_end = m.end() + end_m.start()
            body = remaining[body_start:body_end]
            sections.append({
                'kind': keyword,
                'xml_tag': xml_tag,
                'is_constant': is_constant,
                'body': body,
                'error': None
            })
            remaining = remaining[:m.start()] + remaining[m.end() + end_m.end():]
    return sections, remaining


def parse_var_block(body: str, is_constant: bool = False) -> Tuple[List[Dict[str, object]], List[str]]:
    variables: List[Dict[str, object]] = []
    bad_lines: List[str] = []

    for raw_line in body.splitlines():
        cleaned = strip_inline_comments(raw_line)
        if not cleaned:
            continue
        if ':' not in cleaned:
            bad_lines.append(raw_line.rstrip())
            continue

        name_part, type_part = cleaned.split(':', 1)
        name = name_part.strip()
        type_expr = type_part.strip().rstrip(';').strip()
        init_value = None
        if ':=' in type_expr:
            type_name, init_value = type_expr.split(':=', 1)
            type_name = type_name.strip()
            init_value = init_value.strip()
        else:
            type_name = type_expr

        if not name or not type_name:
            bad_lines.append(raw_line.rstrip())
            continue

        variables.append({
            'name': name,
            'type_name': type_name,
            'is_constant': is_constant,
            'init_value': init_value,
        })
    return variables, bad_lines


def build_type_xml(type_name: str) -> str:
    t = type_name.strip()
    simple_map = {
        'BOOL': '<BOOL />', 'BYTE': '<BYTE />', 'WORD': '<WORD />', 'DWORD': '<DWORD />', 'LWORD': '<LWORD />',
        'SINT': '<SINT />', 'INT': '<INT />', 'DINT': '<DINT />', 'LINT': '<LINT />',
        'USINT': '<USINT />', 'UINT': '<UINT />', 'UDINT': '<UDINT />', 'ULINT': '<ULINT />',
        'REAL': '<REAL />', 'LREAL': '<LREAL />', 'TIME': '<TIME />', 'DATE': '<DATE />',
        'TIME_OF_DAY': '<TIME_OF_DAY />', 'TOD': '<TOD />', 'DATE_AND_TIME': '<DATE_AND_TIME />', 'DT': '<DT />',
        'STRING': '<string />', 'WSTRING': '<wstring />',
    }
    upper = t.upper()
    if upper in simple_map:
        return simple_map[upper]
    return f'<derived name="{xml_escape(t)}" />'


def build_var_xml(variable: Dict[str, object], indent: str) -> List[str]:
    name = str(variable['name'])
    type_name = str(variable['type_name'])
    init_value = variable.get('init_value')
    lines = [f'{indent}<variable name="{xml_escape(name)}">']
    lines.append(f'{indent}  <type>')
    lines.append(f'{indent}    {build_type_xml(type_name)}')
    lines.append(f'{indent}  </type>')
    if init_value is not None and str(init_value).strip() != '':
        lines.append(f'{indent}  <initialValue>')
        lines.append(f'{indent}    <simpleValue value="{xml_escape(str(init_value))}" />')
        lines.append(f'{indent}  </initialValue>')
    lines.append(f'{indent}</variable>')
    return lines


def build_vars_xml(tag_name: str, variables: List[Dict[str, object]], is_constant_block: bool = False, indent: str = '          ') -> str:
    if not variables:
        return ''
    const_attr = ' constant="true"' if is_constant_block else ''
    lines = [f'{indent}<{tag_name}{const_attr}>']
    for variable in variables:
        lines.extend(build_var_xml(variable, indent + '  '))
    lines.append(f'{indent}</{tag_name}>')
    return '\n'.join(lines)


def cleanup_code_text(xml_name: str, pou_type: str, code_text: str) -> str:
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


def parse_method_header(line: str) -> Optional[Tuple[str, str]]:
    stripped = line.strip()
    if not stripped.upper().startswith('METHOD '):
        return None
    rest = stripped[len('METHOD '):].strip()
    tokens = rest.split()
    while tokens and tokens[0].upper() in METHOD_MODIFIERS:
        tokens.pop(0)
    if not tokens:
        return None
    rest = ' '.join(tokens)
    m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)(?:\s*:\s*(.+?))?\s*$', rest)
    if not m:
        return None
    return m.group(1).strip(), (m.group(2) or '').strip()


def extract_methods(st_text: str):
    methods = []
    lines = st_text.splitlines()
    out_lines = []
    i = 0

    while i < len(lines):
        header = parse_method_header(lines[i])
        if header is None:
            out_lines.append(lines[i])
            i += 1
            continue

        method_name, return_type = header
        i += 1
        method_lines = []
        while i < len(lines) and not re.match(r'^\s*END_METHOD\b', lines[i]):
            method_lines.append(lines[i])
            i += 1

        if i < len(lines) and re.match(r'^\s*END_METHOD\b', lines[i]):
            i += 1

        method_raw = '\n'.join(method_lines)
        sections, code_without_vars = extract_sections(method_raw)
        interface_parts: List[str] = []
        local_warns: List[str] = []
        total_method_vars = 0

        for section in sections:
            if section['error']:
                local_warns.append(section['error'])
                continue
            variables, bad_lines = parse_var_block(section['body'], bool(section.get('is_constant', False)))
            total_method_vars += len(variables)
            if bad_lines:
                local_warns.append(f'{section["kind"]}: unparsed lines={len(bad_lines)}')
            block_xml = build_vars_xml(section['xml_tag'], variables, bool(section.get('is_constant', False)))
            if block_xml:
                interface_parts.append(block_xml)

        method_code = '\n'.join(line for line in code_without_vars.splitlines()).strip()
        methods.append({
            'name': method_name,
            'return_type': return_type,
            'interface_parts': interface_parts,
            'code_text': method_code,
            'object_id': make_object_id(),
            'warns': local_warns,
            'var_count': total_method_vars,
        })

    remaining = '\n'.join(out_lines)
    return methods, remaining


def build_return_type_xml(return_type: str) -> str:
    if not return_type:
        return ''
    return (
        '                <returnType>\n'
        f'                  {build_type_xml(return_type)}\n'
        '                </returnType>\n'
    )


def build_method_xml(method_name: str, return_type: str, interface_parts: List[str], code_text: str, object_id: str) -> str:
    escaped_code = xml_escape(code_text)
    lines = [
        '          <data name="http://www.3s-software.com/plcopenxml/method" handleUnknown="implementation">',
        f'            <Method name="{xml_escape(method_name)}" ObjectId="{object_id}">',
        '              <interface>',
    ]
    return_xml = build_return_type_xml(return_type)
    if return_xml:
        lines.append(return_xml.rstrip('\n'))
    for part in interface_parts:
        if part:
            lines.append(part)
    lines.extend([
        '              </interface>',
        '              <body>',
        '                <ST>',
        f'                  <xhtml xmlns="http://www.w3.org/1999/xhtml">{escaped_code}</xhtml>',
        '                </ST>',
        '              </body>',
        '              <addData />',
        '            </Method>',
        '          </data>',
    ])
    return '\n'.join(lines)


def build_pou_xml(xml_name: str, pou_type: str, interface_parts: List[str], code_text: str, method_blocks: List[str], object_id: str) -> str:
    interface_xml = '\n'.join(part for part in interface_parts if part)
    escaped_code = xml_escape(code_text)
    methods_xml = '\n'.join(method_blocks) + ('\n' if method_blocks else '')
    return (
        f'      <pou name="{xml_escape(xml_name)}" pouType="{pou_type}">\n'
        f'        <interface>\n{interface_xml}\n        </interface>\n'
        f'        <body>\n'
        f'          <ST>\n'
        f'            <xhtml xmlns="http://www.w3.org/1999/xhtml">{escaped_code}</xhtml>\n'
        f'          </ST>\n'
        f'        </body>\n'
        f'        <addData>\n'
        f'{methods_xml}'
        f'          <data name="http://www.3s-software.com/plcopenxml/objectid" handleUnknown="discard">\n'
        f'            <ObjectId>{object_id}</ObjectId>\n'
        f'          </data>\n'
        f'        </addData>\n'
        f'      </pou>'
    )


def find_pous_window(xml_text: str) -> Optional[Tuple[int, int, List[str]]]:
    pous_match = re.search(r'<pous>(?P<body>.*?)</pous>', xml_text, flags=re.DOTALL)
    if not pous_match:
        return None
    body = pous_match.group('body')
    body_start = pous_match.start('body')
    controlled = []
    pattern = re.compile(r'<pou\b[^>]*name="(?P<name>[^"]+)"[^>]*>.*?</pou>', flags=re.DOTALL | re.IGNORECASE)
    for m in pattern.finditer(body):
        name = m.group('name')
        if name.startswith('FB_') or name.startswith('F_') or name.startswith('PRG_') or name in {'PLC_PRG', 'PRG_Main'}:
            controlled.append((body_start + m.start(), body_start + m.end(), name))
    if not controlled:
        return None
    return controlled[0][0], controlled[-1][1], [x[2] for x in controlled]


def replace_pous_window(xml_text: str, pou_blocks: List[str]) -> str:
    window = find_pous_window(xml_text)
    insertion = '\n'.join(pou_blocks)
    if window is None:
        m = re.search(r'</pous>', xml_text)
        if not m:
            raise RuntimeError('Could not find </pous> for fallback insertion')
        return xml_text[:m.start()] + '\n' + insertion + '\n    ' + xml_text[m.start():]
    start, end, _ = window
    return xml_text[:start] + insertion + xml_text[end:]


def ensure_folder(xml_text: str, folder_name: str, after_folder: Optional[str] = None) -> str:
    if re.search(rf'<Folder Name="{re.escape(folder_name)}">', xml_text):
        return xml_text
    project_re = re.compile(r'(<ProjectStructure>)(.*?)(</ProjectStructure>)', re.DOTALL)
    m = project_re.search(xml_text)
    if not m:
        raise RuntimeError('ProjectStructure not found')
    middle = m.group(2)
    folder_block = f'\n        <Folder Name="{folder_name}">\n        </Folder>'
    if after_folder:
        anchor = re.search(rf'(<Folder Name="{re.escape(after_folder)}">.*?</Folder>)', middle, re.DOTALL)
        if anchor:
            insert_pos = anchor.end()
            middle = middle[:insert_pos] + folder_block + middle[insert_pos:]
            return xml_text[:m.start()] + m.group(1) + middle + m.group(3) + xml_text[m.end():]
    middle = middle + folder_block
    return xml_text[:m.start()] + m.group(1) + middle + m.group(3) + xml_text[m.end():]


def render_tree_object(entry: Dict[str, object]) -> str:
    xml_name = str(entry['xml_name'])
    object_id = str(entry['object_id'])
    methods = entry.get('methods', []) or []
    if not methods:
        return f'\n          <Object Name="{xml_escape(xml_name)}" ObjectId="{object_id}" />'

    lines = [f'\n          <Object Name="{xml_escape(xml_name)}" ObjectId="{object_id}">']
    for method in methods:
        method_name = xml_escape(str(method['name']))
        method_id = str(method['object_id'])
        lines.append(f'\n            <Object Name="{method_name}" ObjectId="{method_id}" />')
    lines.append('\n          </Object>')
    return ''.join(lines)


def replace_folder_entries(xml_text: str, folder_name: str, predicate, entries: List[Dict[str, object]]):
    folder_re = re.compile(rf'(<Folder Name="{re.escape(folder_name)}">)(.*?)(</Folder>)', re.DOTALL)
    m = folder_re.search(xml_text)
    if not m:
        raise RuntimeError(f'{folder_name} folder not found in ProjectStructure')
    body = m.group(2)
    entry_pattern = re.compile(r'\n?\s*<Object Name="(?P<name>[^"]+)"[^>]*?(?:/>|>.*?</Object>)', re.DOTALL)
    spans = []
    old_names = []
    for em in entry_pattern.finditer(body):
        name = em.group('name')
        if predicate(name):
            spans.append((em.start(), em.end()))
            old_names.append(name)
    new_entries = ''.join(render_tree_object(entry) for entry in entries)
    if spans:
        new_body = body[:spans[0][0]] + new_entries + body[spans[-1][1]:]
    else:
        new_body = body.rstrip() + new_entries + '\n        '
    return xml_text[:m.start()] + m.group(1) + new_body + m.group(3) + xml_text[m.end():], old_names


def main() -> int:
    if LOG_FILE.exists():
        LOG_FILE.unlink()
    if not INPUT_XML.exists():
        print('ERROR: source XML not found')
        return 1

    xml_text = INPUT_XML.read_text(encoding='utf-8', errors='ignore')
    log('=== STEP 001 UNIVERSAL METHODS V2 START ===')
    log(f'INPUT_XML={INPUT_XML}')
    log(f'INPUT_SIZE={len(xml_text)}')

    st_files = []
    for pattern in ST_PATTERNS:
        st_files.extend(sorted(ROOT_DIR.glob(pattern)))
    main_path = ROOT_DIR / MAIN_FILE
    if main_path.exists():
        st_files.append(main_path)

    if not st_files:
        print('ERROR: no POU source files found')
        return 1

    log(f'SOURCE_FILES={len(st_files)}')
    log(f'MAIN_SOURCE_EXISTS={main_path.exists()}')

    pou_entries: List[Dict[str, object]] = []
    total_vars = 0
    total_methods = 0
    warn_count = 0

    for st_file in st_files:
        raw_name = st_file.stem
        xml_name, pou_type, tree_target = detect_pou(raw_name)
        object_id = make_object_id()
        st_text = st_file.read_text(encoding='utf-8', errors='ignore')
        methods, text_without_methods = extract_methods(st_text)
        sections, code_without_vars = extract_sections(text_without_methods)
        interface_parts: List[str] = []
        local_warns: List[str] = []
        method_blocks: List[str] = []
        var_count = 0

        for section in sections:
            if section['error']:
                local_warns.append(section['error'])
                continue
            variables, bad_lines = parse_var_block(section['body'], bool(section.get('is_constant', False)))
            var_count += len(variables)
            total_vars += len(variables)
            if bad_lines:
                local_warns.append(f'{section["kind"]}: unparsed lines={len(bad_lines)}')
            block_xml = build_vars_xml(section['xml_tag'], variables, bool(section.get('is_constant', False)))
            if block_xml:
                interface_parts.append(block_xml)

        method_infos = []
        for method in methods:
            total_methods += 1
            if method['warns']:
                local_warns.append(f'METHOD {method["name"]}: ' + ' | '.join(method['warns']))
            method_blocks.append(build_method_xml(
                str(method['name']),
                str(method['return_type']),
                list(method['interface_parts']),
                str(method['code_text']),
                str(method['object_id'])
            ))
            method_infos.append({
                'name': method['name'],
                'object_id': method['object_id'],
            })

        cleaned_code = cleanup_code_text(xml_name, pou_type, code_without_vars)
        pou_xml = build_pou_xml(xml_name, pou_type, interface_parts, cleaned_code, method_blocks, object_id)
        pou_entries.append({
            'raw_name': raw_name,
            'xml_name': xml_name,
            'pou_type': pou_type,
            'tree_target': tree_target,
            'object_id': object_id,
            'pou_xml': pou_xml,
            'methods': method_infos,
        })

        if local_warns:
            warn_count += 1
            log(f'POU={raw_name} XML_NAME={xml_name} TYPE={pou_type} TREE={tree_target} VARS={var_count} METHODS={len(methods)} OBJECT_ID={object_id} WARN={" | ".join(local_warns)}')
        else:
            log(f'POU={raw_name} XML_NAME={xml_name} TYPE={pou_type} TREE={tree_target} VARS={var_count} METHODS={len(methods)} OBJECT_ID={object_id} OK')

    pou_blocks = [entry['pou_xml'] for entry in pou_entries]
    pous_entries = [entry for entry in pou_entries if entry['tree_target'] == 'pous']
    prg_entries = [entry for entry in pou_entries if entry['tree_target'] == 'prg']

    old_pous_window = find_pous_window(xml_text)
    log(f'OLD_POU_WINDOW_FOUND={old_pous_window is not None}')
    if old_pous_window:
        log(f'OLD_POU_WINDOW_NAMES={"|".join(old_pous_window[2])}')

    xml_text = replace_pous_window(xml_text, pou_blocks)
    xml_text = ensure_folder(xml_text, 'PRG', after_folder='POUs')
    xml_text, old_pous_tree = replace_folder_entries(xml_text, 'POUs', lambda n: n.startswith('FB_') or n.startswith('F_'), pous_entries)
    xml_text, old_prg_tree = replace_folder_entries(xml_text, 'PRG', lambda n: n.startswith('PRG_') or n in {'PLC_PRG', 'PRG_Main'}, prg_entries)
    log(f'OLD_POUS_TREE_NAMES={"|".join(old_pous_tree)}')
    log(f'OLD_PRG_TREE_NAMES={"|".join(old_prg_tree)}')

    OUTPUT_XML.write_text(xml_text, encoding='utf-8')
    verify_text = OUTPUT_XML.read_text(encoding='utf-8', errors='ignore')
    log(f'POU_TOTAL={len(pou_entries)}')
    log(f'POUS_FOLDER_COUNT={len(pous_entries)}')
    log(f'PRG_FOLDER_COUNT={len(prg_entries)}')
    log(f'TOTAL_VARS_PARSED={total_vars}')
    log(f'TOTAL_METHODS_PARSED={total_methods}')
    log(f'POU_WITH_WARNINGS={warn_count}')
    log(f'OUTPUT_XML={OUTPUT_XML}')
    log(f'OUTPUT_SIZE={len(verify_text)}')
    log(f'POU_COUNT_IN_OUTPUT={len(re.findall(r"<pou name=\"", verify_text))}')
    log(f'METHOD_COUNT_IN_OUTPUT={len(re.findall(r"<Method name=\"", verify_text))}')
    log(f'OBJECTID_COUNT_IN_OUTPUT={len(re.findall(r"<ObjectId>", verify_text))}')
    log('=== STEP 001 UNIVERSAL METHODS V2 DONE ===')
    return 0


if __name__ == '__main__':
    sys.exit(main())
