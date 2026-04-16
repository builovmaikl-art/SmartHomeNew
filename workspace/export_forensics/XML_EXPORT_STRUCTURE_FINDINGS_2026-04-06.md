# XML EXPORT STRUCTURE FINDINGS
**Date:** 2026-04-06
**Source:** `Система умного дома.xml`

---

## 1. Main conclusion

The XML export is a much better integration target than the raw `*.export` file.

Reason:
- readable PLCopen XML structure
- deterministic object boundaries
- explicit `pou`, `dataType`, `globalVars`, `ProjectStructure`
- object identifiers visible and stable

---

## 2. Confirmed structural layers

### 2.1 Code layer
Real code objects are stored in:
- `<dataType ...>` for DUT/ENUM/STRUCT
- `<pou name="..." pouType="...">` for PROGRAM / FB / FUNCTION
- `<globalVars name="...">` for GVL

### 2.2 Body layer
ST implementation is stored inside:
- `<body><ST><xhtml> ... </xhtml></ST></body>`

### 2.3 Interface layer
Declarations are stored inside:
- `<interface> ... </interface>`

### 2.4 Tree / project structure layer
The project hierarchy is stored separately inside:
- `<ProjectStructure>`
- `<Object Name="..." ObjectId="..." />`

---

## 3. Critical rule

A POU name appears in at least two places:
1. real code object: `<pou name="FB_X" ...>`
2. project tree entry: `<Object Name="FB_X" ObjectId="..." />`

These are NOT duplicates.

Safe editing target:
- implementation body
- sometimes interface (carefully)

Unsafe editing target:
- object tree
- object IDs / GUIDs
- hierarchy links

---

## 4. Safe patch strategy

### Safe first-wave edits
- replace only `<body><ST><xhtml>...</xhtml></ST></body>` for existing objects
- preserve object name
- preserve `ObjectId`
- preserve `ProjectStructure`

### Cautious second-wave edits
- update `<interface>` if declaration really changed
- only when matching current repo object requires new vars / IO

### Forbidden at this stage
- create large new object trees automatically
- rewrite `ProjectStructure`
- regenerate XML from scratch

---

## 5. Recommended migration path

1. choose one pilot POU already present in XML
2. extract its XML block
3. compare repo ST vs XML `<xhtml>` body
4. patch implementation only
5. import into CODESYS and validate
6. only then scale to more POUs

---

## 6. Best pilot candidates

Good first candidates:
- `FB_Astro_Timer`
- `FB_DHW_Manager`
- `FB_Lighting_Blinds_Manager`

Selection criteria:
- present in XML
- easy to find by name
- limited cross-dependencies
- already familiar from repo work

---

## 7. Working hypothesis

The XML variant makes export reintegration feasible through surgical patching.

Target model:
- XML file remains the authoritative container
- repo ST remains the authoritative logic source
- reintegration tool patches only the code-bearing XML nodes

---

## 8. Next step

Prepare a pilot extractor/patch plan for one selected POU.
