# 07 — HP-2 Config-Driven Guest Preheat Plan

Дата: 2026-04-27
Назначение: безопасное подключение guest preheat как config-driven priority boost без изменения actuator ownership

---

## Режим

```text
Direct Repository Modification Mode
```

---

## Причина

Guest preheat не должен быть hardcoded в `PRG_Heating.st`.

Правильная модель:

```text
config -> policy/priority influence -> decision context -> domain outputs
```

Не допускается модель:

```text
hardcoded boost in code -> direct actuator control
```

---

## Scope HP-2

Добавить config-driven guest preheat influence:

```text
GVL_HEATING_POLICY.G_Zone_Guest_Preheat_Request[]
+
GVL_HEATING_POLICY_CONFIG.G_Guest_Preheat_Priority_Boost
->
L_Manifold_Adjusted_Priority[]
```

---

## Runtime files in scope

```text
GVL_HEATING_POLICY_CONFIG.gvl
PRG_Heating.st
```

---

## Почему отдельный GVL, а не большой GVL_CONFIG

На этапе внедрения лучше минимизировать риск правки большого общего config-файла.

Поэтому HP-2 использует отдельный маленький namespace:

```text
GVL_HEATING_POLICY_CONFIG
```

Это сохраняет config-driven подход и снижает риск случайно повредить большой `GVL_CONFIG.gvl`.

---

## Запрещено

```text
не менять MAIN.st
не менять PRG_IO_Read.st
не менять PRG_Safety.st
не менять FB_Heating_Decision_Context signature
не использовать G_Zone_Target_Adjustment[]
не управлять pumps/valves напрямую из policy/preheat
не добавлять таймеры в HP-2
```

---

## Правила реализации

В `GVL_HEATING_POLICY_CONFIG.gvl` добавить:

```text
G_Guest_Preheat_Enabled : BOOL := TRUE
G_Guest_Preheat_Priority_Boost : INT := 2
G_Guest_Preheat_Max_Duration_MS : UDINT := 7200000
```

`G_Guest_Preheat_Max_Duration_MS` добавляется как future-safe config, но в HP-2 не используется.

В `PRG_Heating.st` guest preheat должен применяться только внутри HP-1 priority calculation block:

```text
base priority + policy bias + guest preheat boost
```

---

## Expected behavior

```text
guest preheat disabled -> no effect
guest preheat enabled and request TRUE -> mapped manifold priority boosted
coordinator block still overrides heating
safety/gas/degraded priority remains higher than preheat
target temperature is not changed by HP-2
```

---

## Verification checklist

После изменения обязательно проверить:

```text
1. PRG_Heating.st полный и не содержит placeholder.
2. GVL_HEATING_POLICY_CONFIG.gvl существует и полный.
3. MAIN.st не изменён.
4. PRG_IO_Read.st не изменён.
5. PRG_Safety.st не изменён.
6. G_Zone_Target_Adjustment[] не используется в PRG_Heating.st.
7. FB_Heating_Decision_Context signature не изменена.
8. Coordinator override остаётся после base heating orchestration.
9. Нет прямого управления pumps/valves из guest preheat.
```

---

## Статус

```text
HP-2 CONFIG-DRIVEN GUEST PREHEAT PLAN RECORDED
CODE CHANGE ALLOWED ONLY IN GVL_HEATING_POLICY_CONFIG.gvl AND PRG_Heating.st
```