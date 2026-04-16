from pathlib import Path
import re
import uuid

BASE = Path("steps/MASTER_PIPELINE/004_RESULT.xml")
OUT = Path("steps/MASTER_PIPELINE/005_RESULT.xml")
LOG = Path("steps/MASTER_PIPELINE/005_import_prg.log")
ROOT = Path(".")

# генерируем GUID
def new_guid():
    return str(uuid.uuid4())

# экранирование XML
def esc(s: str) -> str:
    return (s.replace("&", "&amp;")
             .replace("<", "&lt;")
             .replace(">", "&gt;")
             .replace('"', "&quot;"))

# ищем PRG файлы
prg_files = sorted(ROOT.glob("PRG_*.st"))

xml = BASE.read_text(encoding="utf-8", errors="replace")

pou_blocks = []
log = []

for f in prg_files:
    text = f.read_text(encoding="utf-8", errors="replace")

    name = f.stem

    # выделяем VAR блок
    var_match = re.search(r"(?is)VAR(.*?)END_VAR", text)
    vars_block = var_match.group(0) if var_match else ""

    # тело программы
    impl = text
    if var_match:
        impl = text[var_match.end():]

    oid = new_guid()

    pou_xml = f"""
      <pou name=\"{esc(name)}\" pouType=\"program\">
        <interface>
          <localVars>
            {esc(vars_block)}
          </localVars>
        </interface>
        <body>
          <ST>
            {esc(impl)}
          </ST>
        </body>
        <addData>
          <data name=\"http://www.3s-software.com/plcopenxml/objectid\" handleUnknown=\"discard\">
            <ObjectId>{oid}</ObjectId>
          </data>
        </addData>
      </pou>
    """

    pou_blocks.append(pou_xml)
    log.append(f"PRG: {name}")

# вставка в XML
xml = xml.replace("</pous>", "\n" + "\n".join(pou_blocks) + "\n</pous>")

OUT.write_text(xml, encoding="utf-8")
LOG.write_text("\n".join(log), encoding="utf-8")

print("005 OK")
print(f"PRG_FILES={len(prg_files)}")
