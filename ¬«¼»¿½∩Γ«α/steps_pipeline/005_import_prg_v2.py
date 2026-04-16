from pathlib import Path
import importlib.util
import re
import sys
import uuid

BASE = Path("steps/MASTER_PIPELINE/004_RESULT.xml")
OUT = Path("steps/MASTER_PIPELINE/005_RESULT.xml")
LOG = Path("steps/MASTER_PIPELINE/005_import_prg_v2.log")
ROOT = Path(".")
LIB = Path("steps/MASTER_PIPELINE/lib_codegen.py")


def load_codegen():
    spec = importlib.util.spec_from_file_location("lib_codegen", LIB)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


cg = load_codegen()


def new_guid() -> str:
    return str(uuid.uuid4())


def normalize_ws(text: str) -> str:
    return text.replace("\r\n", "\n").replace("\r", "\n")


def strip_comments(line: str) -> str:
    line = re.sub(r'\(\*.*?\*\)', '', line)
    if '//' in line:
        line = line.split('//', 1)[0]
    return line.strip()


def extract_var_blocks(text: str):
    blocks = []
    pattern = re.compile(r'(?is)^\s*(VAR(?:_INPUT|_OUTPUT|_IN_OUT|_TEMP|_STAT)?)\b(.*?)^\s*END_VAR\b', re.M)
    for m in pattern.finditer(text):
        blocks.append((m.group(1).upper(), m.group(2)))
    return blocks


def remove_var_blocks(text: str) -> str:
    return re.sub(r'(?is)^\s*VAR(?:_INPUT|_OUTPUT|_IN_OUT|_TEMP|_STAT)?\b.*?^\s*END_VAR\b\s*', '', text, flags=re.M)


def parse_var_block(body: str):
    vars_out = []
    bad = []
    for raw_line in normalize_ws(body).split('\n'):
        cleaned = strip_comments(raw_line)
        if not cleaned:
            continue
        parsed = cg.parse_variable_line(cleaned)
        if parsed is None:
            bad.append(raw_line.rstrip())
            continue
        vars_out.append(parsed)
    return vars_out, bad


def build_local_vars_xml(vars_list):
    if not vars_list:
        return ''
    lines = ['          <localVars>']
    for var in vars_list:
        lines.append(cg.build_variable_xml(var))
    lines.append('          </localVars>')
    return '\n'.join(lines)


def build_pou_xml(name: str, local_vars_xml: str, body_text: str, oid: str) -> str:
    body_clean = normalize_ws(body_text).strip()
    body_clean = re.sub(rf'(?im)^\s*PROGRAM\s+{re.escape(name)}\b.*$', '', body_clean)
    body_clean = re.sub(r'(?im)^\s*END_PROGRAM\b.*$', '', body_clean)
    body_clean = body_clean.strip()
    escaped_body = cg.esc(body_clean)
    interface_inner = local_vars_xml if local_vars_xml else ''
    return (
        f'      <pou name="{cg.esc(name)}" pouType="program">\n'
        f'        <interface>\n{interface_inner}\n        </interface>\n'
        f'        <body>\n'
        f'          <ST>\n'
        f'            <xhtml xmlns="http://www.w3.org/1999/xhtml">{escaped_body}</xhtml>\n'
        f'          </ST>\n'
        f'        </body>\n'
        f'        <addData>\n'
        f'          <data name="http://www.3s-software.com/plcopenxml/objectid" handleUnknown="discard">\n'
        f'            <ObjectId>{oid}</ObjectId>\n'
        f'          </data>\n'
        f'        </addData>\n'
        f'      </pou>'
    )


def insert_before_closing(xml: str, closing_tag: str, insert_text: str) -> str:
    idx = xml.rfind(closing_tag)
    if idx < 0:
        raise RuntimeError(f'Closing tag not found: {closing_tag}')
    return xml[:idx] + insert_text + '\n' + xml[idx:]


def insert_project_objects(xml: str, object_lines: str) -> str:
    marker = '</ProjectStructure>'
    idx = xml.rfind(marker)
    if idx < 0:
        raise RuntimeError('ProjectStructure not found')
    return xml[:idx] + object_lines + '\n' + xml[idx:]


def main() -> int:
    if not BASE.exists():
        print(f'ERROR: base xml not found: {BASE}')
        return 1
    if not LIB.exists():
        print(f'ERROR: codegen library not found: {LIB}')
        return 1

    xml = BASE.read_text(encoding='utf-8', errors='replace')
    prg_files = sorted(ROOT.glob('PRG_*.st'))
    if not prg_files:
        LOG.write_text('NO_PRG_FILES_FOUND\n', encoding='utf-8')
        print('NO_PRG_FILES_FOUND')
        return 1

    pou_blocks = []
    object_lines = []
    log_lines = []
    total_vars = 0
    total_bad = 0

    for f in prg_files:
        text = f.read_text(encoding='utf-8', errors='replace')
        name = f.stem
        oid = new_guid()

        blocks = extract_var_blocks(text)
        local_vars = []
        for kind, body in blocks:
            if kind == 'VAR':
                parsed, bad = parse_var_block(body)
                local_vars.extend(parsed)
                total_vars += len(parsed)
                total_bad += len(bad)
                if bad:
                    log_lines.append(f'{name}: unparsed VAR lines={len(bad)}')

        body_text = remove_var_blocks(text)
        local_xml = build_local_vars_xml(local_vars)
        pou_blocks.append(build_pou_xml(name, local_xml, body_text, oid))
        object_lines.append(f'        <Object Name="{cg.esc(name)}" ObjectId="{oid}" />')
        log_lines.append(f'{name}: localVars={len(local_vars)}')

    xml = insert_before_closing(xml, '</pous>', '\n'.join(pou_blocks))
    xml = insert_project_objects(xml, '\n'.join(object_lines))

    OUT.write_text(xml, encoding='utf-8')
    LOG.write_text(
        '\n'.join([
            '005 OK',
            f'PRG_FILES={len(prg_files)}',
            f'TOTAL_LOCAL_VARS={total_vars}',
            f'TOTAL_BAD_VAR_LINES={total_bad}',
            *log_lines,
        ]) + '\n',
        encoding='utf-8'
    )
    print('005 OK')
    print(f'PRG_FILES={len(prg_files)}')
    print(f'TOTAL_LOCAL_VARS={total_vars}')
    print(f'TOTAL_BAD_VAR_LINES={total_bad}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
