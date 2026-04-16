# 004 struct initializer strategy

## Principle

The repair must be generic.
It must not depend on the current number of STRUCT fields in the project.
Field counts may change over time.
Counts are allowed only for diagnostics/logging, not for logic.

## Scope

Keep ENUM handling unchanged.
Fix only STRUCT field parsing and STRUCT field XML generation.

## Internal model for STRUCT field

Each STRUCT field must be parsed as:
- name
- type_expr_raw
- initializer_raw (optional)

Examples:
- `A : INT;`
- `B : BOOL := TRUE;`
- `C : REAL := 0.0;`
- `D : E_Mode := E_Mode.Auto;`
- `E : STRING[20] := 'abc';`

## Parser rule

For STRUCT lines:
- split `name : rest`
- then split `rest` into `type_expr_raw` and optional `initializer_raw` by the first `:=`
- do not drop initializer
- do not affect ENUM parser

## XML generation rule

Always keep type generation logic generic.

If initializer is absent:
- generate the same XML as today

If initializer is present and is scalar/simple:
- add `<initialValue><simpleValue value="..." /></initialValue>` inside the field variable node

Simple/scalar candidates:
- BOOL literals
- integer literals
- real literals
- enum literals
- string literals
- time/date literals when accepted by CODESYS import

If initializer is complex and serializer support is unclear:
- do not silently drop it
- write a warning into repair log
- keep file marked for follow-up

## Non-goals

- no logic tied to current field totals
- no changes to ENUM import
- no changes to folder rebuild logic
- no unrelated DUT pipeline rewrites
