# 08 - HP1 + HP2 Compile Result

Date: 2026-04-28

Purpose: зафиксировать результат компиляции после сверки фактического состояния HP-1 / HP-2 в `PRG_Heating.st`.

---

## Scope

Проверяемая область:

```text
PRG_Heating.st
HP-1 priority bias integration
HP-2 guest preheat priority boost integration (already present in code)
```

---

## Compile result

User-reported CODESYS compile result:

```text
COMPILE: OK
ERRORS: 0
```

---

## Meaning

Это подтверждает:

```text
1. текущий код компилируется;
2. HP-1 / HP-2 фрагменты синтаксически валидны;
3. FB_Heating_Decision_Context call signature не нарушена;
4. базовая интеграция не ломает сборку проекта.
```

---

## Important limitation

Компиляция НЕ подтверждает поведение.

Необходимо отдельно проверить:

```text
1. zero bias path equals previous behavior;
2. positive priority bias increases mapped manifold priority;
3. negative priority bias does not lower priority below safe bound;
4. guest preheat boost affects priority only through configured path;
5. safety still dominates;
6. coordinator block still dominates;
7. G_Zone_Target_Adjustment[] remains unused.
```

---

## Current status

```text
HP1_HP2_CODE_REALITY_CHECK: COMPLETE
COMPILE_STATUS: PASSED
NEXT: BEHAVIOR AUDIT WITHOUT TEST HARNESS
```

---

## Next document after behavior check

After manual/online behavior checks, create:

```text
09_HP1_HP2_BEHAVIOR_AUDIT_RESULT.md
```
