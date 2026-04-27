# 06 — HP-1 Priority Bias Changeset Plan

Дата: 2026-04-27
Назначение: минимальный controlled changeset для первого реального применения Heating Policy через priority bias

---

## Режим

```text
Direct Repository Modification Mode
```

Этот документ сопровождает code changeset в `PRG_Heating.st`.

---

## Scope

Только HP-1:

```text
Use GVL_HEATING_POLICY.G_Zone_Priority_Bias[] as additive bias for manifold priority.
```

---

## Файл изменения

```text
PRG_Heating.st
```

Другие runtime-файлы не должны изменяться в этом changeset.

---

## Запрещено в этом changeset

```text
не менять MAIN.st
не менять PRG_IO_Read.st
не менять PRG_Safety.st
не менять FB_Heating_Decision_Context signature
не применять G_Zone_Target_Adjustment[]
не управлять pumps/valves напрямую из policy
не менять Coordinator role
```

---

## Реализация

В `PRG_Heating.st` добавить локальный массив:

```text
L_Manifold_Adjusted_Priority : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF INT;
```

Перед вызовом `fbDecision(...)` сформировать adjusted priority:

```text
base manifold priority + summed zone priority bias mapped by manifold_id
```

Правила:

```text
bias is additive, not replacement
priority lower bound is 1
zone policy maps to manifold through GVL_CONFIG.G_HMI_FloorHeating_Configs[].manifold_id
only heating circuits 1..C_MAX_HEATING_CIRCUITS are used for mapping
```

Затем передать в `fbDecision`:

```text
VI_Manifold_Priority := L_Manifold_Adjusted_Priority
```

---

## Expected behavior

```text
zero bias -> same behavior as before
positive bias -> raises mapped manifold priority
negative bias -> lowers mapped manifold priority, but not below 1
Coordinator block remains stronger than policy
Safety remains stronger than policy
```

---

## Verification checklist

После изменения обязательно проверить:

```text
1. PRG_Heating.st не обрезан.
2. Нет placeholder text.
3. END_VAR / END_IF / END_FOR баланс сохранён.
4. fbDecision signature не изменена.
5. MAIN.st не изменён.
6. PRG_IO_Read.st не изменён.
7. PRG_Safety.st не изменён.
8. G_Zone_Target_Adjustment[] не используется.
9. Coordinator override остаётся после base heating orchestration.
10. Runtime/build smoke требуется отдельно при доступной среде.
```

---

## Rollback

Rollback минимальный:

```text
1. вернуть VI_Manifold_Priority := GVL_CONFIG.G_Manifold_Priority
2. удалить L_Manifold_Adjusted_Priority
3. удалить local adjusted-priority calculation block
```

---

## Статус

```text
HP-1 PRIORITY BIAS CHANGESET PLAN RECORDED
CODE CHANGE MAY BE APPLIED TO PRG_HEATING.ST ONLY
```