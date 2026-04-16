# EXPORT STRUCTURE NOTES

## Goal
Identify stable patterns in CODESYS export file to allow safe reintegration of modified project.

---

## What to extract (to be filled after inspection)

### 1. Object structure
- how POU is represented
- separation of declaration / implementation
- identifiers (GUID / ID / name)

### 2. Ordering rules
- is order significant?
- parent-child hierarchy

### 3. Section patterns
Typical expected blocks:
- PROGRAM
- FUNCTION_BLOCK
- GVL
- DUT

### 4. Encoding / format
- XML / proprietary / mixed
- line endings
- escaping rules

### 5. Cross references
- how variables link to GVL
- how FB instances are referenced

---

## Hypotheses (to validate)

- export is deterministic → safe to patch partially
- objects can be replaced independently
- identifiers must remain unchanged

---

## Risks

- broken IDs → import failure
- wrong ordering → silent corruption
- missing metadata → runtime errors

---

## Strategy draft

1. isolate single POU in export
2. replace only body
3. import and validate
4. scale gradually
