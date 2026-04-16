# PRELIMINARY EXPORT ANALYSIS

Source file:
SystemSmartHome.export

---

## Observations (initial)

- File detected in repository root
- Likely large structured export (CODESYS project export)
- Requires local/manual inspection due to size/format constraints

---

## Expected structure (based on CODESYS export patterns)

Typical elements inside export:

1. Project tree
2. POU objects:
   - PROGRAM
   - FUNCTION_BLOCK
   - FUNCTION
3. GVL blocks
4. DUT (types)
5. Task configuration
6. Device configuration

---

## Critical zones for modification

Only safe to modify:
- ST implementation bodies
- variable declarations (carefully)

Unsafe / sensitive:
- object IDs
- GUIDs
- hierarchy links
- device tree

---

## Reintegration strategy (draft)

Step 1:
- extract single FB from export

Step 2:
- compare with repo version

Step 3:
- replace ONLY implementation section

Step 4:
- import into CODESYS

Step 5:
- validate

---

## Next action

Manual inspection required:

Open file locally and identify:
- exact delimiter format
- POU boundaries
- declaration vs implementation split

