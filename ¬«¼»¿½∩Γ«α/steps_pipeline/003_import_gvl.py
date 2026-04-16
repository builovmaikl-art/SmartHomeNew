from pathlib import Path
import re
import uuid

BASE = Path("steps/MASTER_PIPELINE/002_RESULT.xml")
OUT  = Path("steps/MASTER_PIPELINE/003_RESULT.xml")
LOG  = Path("steps/MASTER_PIPELINE/003_import_gvl.log")
ROOT = Path(".")

PRIMITIVES = {"BOOL","INT","UINT","BYTE","WORD","DWORD","UDINT","REAL","TOD"}

def guid():
    return str(uuid.uuid4())

def esc(s):
    return str(s).replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace('"',"&quot;")

def parse_decl(line):
    if ":" not in line or ";" not in line:
        return None
    doc = None
    if "//" in line:
        line, doc = line.split("//", 1)
        doc = doc.strip()
    line = line.strip().rstrip(";")
    name, rest = line.split(":", 1)

    depth_sq = depth_par = 0
    in_str = False
    val_pos = -1
    i = 0
    while i < len(rest) - 1:
        ch = rest[i]
        if ch == "'" and (i == 0 or rest[i-1] != "\\"):
            in_str = not in_str
        elif not in_str:
            if ch == "[":
                depth_sq += 1
            elif ch == "]":
                depth_sq -= 1
            elif ch == "(":
                depth_par += 1
            elif ch == ")":
                depth_par -= 1
            elif rest[i:i+2] == ":=" and depth_sq == 0 and depth_par == 0:
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
        return f"<{t.upper()} />"

    m = re.match(r"STRING\s*\((\d+)\)$", t, re.I)
    if m:
        return f'<string length="{m.group(1)}" />'

    m = re.match(r"ARRAY\s*\[(.+?)\.\.(.+?)\]\s+OF\s+(.+)$", t, re.I)
    if m:
        low, high, base = m.groups()
        return f"""
<array>
  <dimension lower="{esc(low)}" upper="{esc(high)}" />
  <baseType>
    {parse_type(base.strip())}
  </baseType>
</array>"""

    return f'<derived name="{esc(t)}" />'

def split_array_items(val):
    inner = val[1:-1].strip()
    if not inner:
        return []
    items = []
    buf = ""
    depth_sq = depth_par = 0
    in_str = False
    for i, ch in enumerate(inner):
        if ch == "'" and (i == 0 or inner[i-1] != "\\"):
            in_str = not in_str
        elif not in_str:
            if ch == "[":
                depth_sq += 1
            elif ch == "]":
                depth_sq -= 1
            elif ch == "(":
                depth_par += 1
            elif ch == ")":
                depth_par -= 1
            elif ch == "," and depth_sq == 0 and depth_par == 0:
                items.append(buf.strip())
                buf = ""
                continue
        buf += ch
    if buf.strip():
        items.append(buf.strip())
    return items

def build_var(name, typ, val, doc):
    t = parse_type(typ)
    init = ""
    if val:
        if val.startswith("[") and val.endswith("]"):
            items = split_array_items(val)
            vals = "".join(f'<value><simpleValue value="{esc(i)}" /></value>' for i in items)
            init = f"<initialValue><arrayValue>{vals}</arrayValue></initialValue>"
        else:
            init = f'<initialValue><simpleValue value="{esc(val)}" /></initialValue>'
    d = f"<documentation>{esc(doc)}</documentation>" if doc else ""
    return f'<variable name="{esc(name)}"><type>{t}</type>{init}{d}</variable>'

def parse_file(txt):
    qualified = "qualified_only" in txt.lower()
    sections = []
    cur = None

    for raw in txt.splitlines():
        l = raw.strip()
        if not l or l.startswith("{"):
            continue

        if l.upper().startswith("VAR_GLOBAL"):
            up = l.upper()
            mode = "plain"
            if "CONSTANT" in up:
                mode = "constant"
            elif "RETAIN" in up:
                mode = "retain"
            cur = {"mode": mode, "vars": []}
            sections.append(cur)
            continue

        if l.upper().startswith("END_VAR"):
            cur = None
            continue

        if cur is not None:
            v = parse_decl(l)
            if v:
                cur["vars"].append(v)

    return sections, qualified

def mode_attrs(mode):
    attrs = ""
    if mode == "constant":
        attrs += ' constant="true"'
    if mode == "retain":
        attrs += ' retain="true"'
    return attrs

def build_section_globalvars_xml(name, mode, vars_):
    vars_xml = "".join(build_var(*v) for v in vars_)
    return f'<globalVars name="{esc(name)}"{mode_attrs(mode)}>{vars_xml}</globalVars>'

def build_gvl_entry(name, sections, qualified):
    oid = guid()

    non_empty = [s for s in sections if s["vars"]]
    if not non_empty:
        return None, None

    attr_block = ""
    if qualified:
        attr_block = (
            '<data name="http://www.3s-software.com/plcopenxml/attributes" handleUnknown="implementation">'
            '<Attributes><Attribute Name="qualified_only" Value="" /></Attributes>'
            '</data>'
        )

    if len(non_empty) == 1:
        sec = non_empty[0]
        outer = build_section_globalvars_xml(name, sec["mode"], sec["vars"])
        outer = outer.replace(
            "</globalVars>",
            '<addData>'
            f'{attr_block}'
            '<data name="http://www.3s-software.com/plcopenxml/objectid" handleUnknown="discard">'
            f'<ObjectId>{oid}</ObjectId>'
            '</data>'
            '</addData>'
            '</globalVars>'
        )
    else:
        mixed_inner = "".join(build_section_globalvars_xml(name, sec["mode"], sec["vars"]) for sec in non_empty)
        outer = build_section_globalvars_xml(name, "plain", non_empty[0]["vars"])
        outer = outer.replace(
            "</globalVars>",
            '<addData>'
            f'{attr_block}'
            '<data name="http://www.3s-software.com/plcopenxml/objectid" handleUnknown="discard">'
            f'<ObjectId>{oid}</ObjectId>'
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
    obj = f'<Object Name="{esc(name)}" ObjectId="{oid}" />'
    return gvl, obj

xml = BASE.read_text(encoding="utf-8", errors="replace")

blocks = []
objs = []
log = []

for f in sorted(ROOT.glob("GVL*.gvl")):
    txt = f.read_text(encoding="utf-8", errors="replace")
    sections, qualified = parse_file(txt)
    name = f.stem

    entry = build_gvl_entry(name, sections, qualified)
    if entry == (None, None):
        continue

    g, o = entry
    blocks.append(g)
    objs.append(o)

    modes = ",".join(s["mode"] for s in sections if s["vars"])
    log.append(f"{f.name}->{name} modes={modes}")

globalvars_pattern = re.compile(
    r'(<addData>\s*)(<data name="http://www\.3s-software\.com/plcopenxml/globalvars" handleUnknown="implementation">.*?</data>\s*)+(?=<data name="http://www\.3s-software\.com/plcopenxml/projectstructure")',
    re.DOTALL
)
xml, n_gvl = globalvars_pattern.subn(lambda m: m.group(1) + "\n" + "\n".join(blocks) + "\n", xml)

folder_pattern = re.compile(
    r'(<Folder Name="GVL">\s*)(.*?)(\s*</Folder>)',
    re.DOTALL
)
xml, n_folder = folder_pattern.subn(lambda m: m.group(1) + "\n" + "\n".join(objs) + "\n" + m.group(3), xml)

if n_gvl != 1:
    raise SystemExit(f"GVL block replace failed: {n_gvl}")
if n_folder != 1:
    raise SystemExit(f"GVL folder replace failed: {n_folder}")

OUT.write_text(xml, encoding="utf-8")
LOG.write_text("\n".join(log), encoding="utf-8")

print("003 OK")
print(f"REPLACED_GLOBALVARS={n_gvl}")
print(f"REPLACED_GVL_FOLDER={n_folder}")
print(f"GENERATED_BLOCKS={len(blocks)}")
print(f"GENERATED_OBJECTS={len(objs)}")
