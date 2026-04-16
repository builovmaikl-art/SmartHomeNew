# 004 struct initializer analysis

## Confirmed issue

`004_import_dut_v6.py` drops everything after `:=` in STRUCT fields.

Current logic:
- parse `name : type := value;`
- store only `name`, `type`
- lose initializer/default value

## Important constraint

ENUM parsing must stay untouched.

## Scope

- fix only STRUCT field parsing/building
- preserve support for fields without initializer
- preserve support for ENUM without initializer
- do not rewrite unrelated 004 logic

## Target behavior

Input:
- `A : INT;`
- `B : BOOL := TRUE;`
- `C : ARRAY [1..3] OF INT := [1,2,3];`

Internal parse result for STRUCT field:
- name
- type
- initializer (optional)

XML generation target:
- keep field type as before
- when initializer exists, emit it into variable/addData/Declaration or equivalent supported node in repair step

## Next repair direction

1. change `parse_struct_fields()` to return `(name, type, initializer)`
2. keep `initializer=None` when missing
3. update `build_struct_xml()` to consume optional initializer
4. add verification log with counts:
   - struct fields total
   - struct fields with initializer
   - struct fields without initializer

## Non-goals

- do not change enum parser
- do not change DUT folder rebuild logic
- do not change remove_old_dut_datatypes logic
