# 85 — PRG_IO_Read Protected Core Policy

Дата фиксации: 2026-04-24
Режим: Direct Repository Modification Mode
Scope: documentation / workflow only
Runtime-код: не изменялся

## Назначение

`PRG_IO_Read.st` является protected core file.

Он не должен рассматриваться как обычный удобный файл для локальной правки, потому что является producer-ядром цепочки:

```text
GVL_IO -> PRG_IO_Read -> GVL_STATE -> Diagnostics / Safety / Heating / DHW / Ventilation / HMI
```

Ошибки в этом файле не всегда проявляются как ошибки компиляции. Частичная потеря чтения IO может оставить проект компилируемым, но сделать runtime-данные недостоверными.

---

## Причина введения правила

Во время восстановления были зафиксированы следующие классы риска:

1. partial full-file overwrite;
2. сокращённые шаблоны вместо реального кода;
3. появление заглушек вида `...`;
4. потеря live mapping-блоков;
5. несверенные сигнатуры FB;
6. опасные неявные преобразования типов;
7. восстановление только части producer-chain.

Этот документ вводит обязательную процедуру перед любыми будущими изменениями `PRG_IO_Read.st`.

---

## Запрещено

### 1. Запрещены сокращённые full-file replacement

Нельзя использовать форматы:

```text
// same code omitted
// остальной код без изменений
...
```

В `PRG_IO_Read.st` такие шаблоны считаются runtime-breaking defect, даже если файл компилируется.

### 2. Запрещено править без чтения реальных FB contracts

Если изменение касается FB-вызовов, перед вставкой обязателен просмотр реального `FUNCTION_BLOCK`:

```text
VAR_INPUT
VAR_OUTPUT
VAR_IN_OUT
```

Запрещено использовать предполагаемые имена входов/выходов.

### 3. Запрещено считать declaration подключением

Наличие поля в `GVL_STATE` или `GVL_IO` не означает, что цепочка подключена.

Подключение считается существующим только если есть runtime producer assignment:

```text
GVL_IO.<source> -> PRG_IO_Read -> GVL_STATE.<target>
```

---

## Разрешённые режимы изменения

### Режим A — minimal diff

Допустим, если изменение локальное и не затрагивает остальную структуру файла.

Обязательно:

1. прочитать текущий `PRG_IO_Read.st`;
2. изменить только целевой блок;
3. перечитать файл после изменения;
4. подтвердить наличие старых соседних блоков;
5. проверить, что не исчезли unrelated producer assignments.

### Режим B — full restore / full merge

Допустим, если файл повреждён или нужно восстановить несколько блоков.

Обязательно:

1. выбрать verified source baseline;
2. перенести весь baseline без сокращений;
3. отдельно встроить новые блоки;
4. перечитать итоговый файл;
5. сравнить покрытие producer-chain;
6. проверить отсутствие placeholders.

### Режим C — runtime-affecting refactor

Если изменение влияет на безопасность, диагностику, heating/DHW, feedback или аварийные цепочки, Direct Repository Modification Mode недостаточен для финального engineering-confirmation.

Нужно планировать Full Verification Mode:

```text
steps/* -> terminal execution -> git diff -> compile/log verification
```

---

## Mandatory pre-change checklist

Перед любым изменением `PRG_IO_Read.st`:

```text
[ ] прочитан текущий PRG_IO_Read.st
[ ] определён один конкретный target problem
[ ] проверено, какие GVL_IO поля являются source
[ ] проверено, какие GVL_STATE поля являются target
[ ] если используется FB — прочитана реальная сигнатура FB
[ ] проверено, что изменение не конфликтует с MASTER_GUIDE / WORKFLOW
[ ] выбран режим: minimal diff / full merge / Full Verification
```

---

## Mandatory post-change checklist

После любого изменения `PRG_IO_Read.st`:

```text
[ ] файл перечитан из репозитория
[ ] нет placeholder-заглушек
[ ] нет `...` в runtime-коде
[ ] нет фраз `same code omitted` / `остальной код без изменений`
[ ] сохранены debounce blocks
[ ] сохранены security/flood/smoke mappings
[ ] сохранены analog/climate mappings
[ ] сохранены boiler/DHW/water feedback mappings
[ ] сохранены diagnostics updates
[ ] если были compiler errors/warnings — они сверены с актуальным логом
```

---

## Producer-chain coverage checklist

Минимальное ожидаемое покрытие `PRG_IO_Read.st`:

```text
watchdog                 -> GVL_STATUS.G_IO_Modules_Online
switches/motion           -> GVL_STATE.G_Physical_Switches / G_Motion_Sensors
security open/glass       -> GVL_STATE.G_Door_Sensors / G_Window_Sensors
flood/smoke               -> GVL_STATE.G_Water_Sensors / G_Smoke_Sensors
outdoor temp              -> GVL_STATE.G_Outdoor_Temp
supply temps              -> GVL_STATE.G_Supply_Temps
room temp/humidity/CO2    -> GVL_STATE.G_Room_Temps / G_Room_Hum / G_Room_CO2
floor temps               -> GVL_STATE.G_Floor_Temps
manifold pressure/current -> GVL_STATE.G_Manifold_Pressures / G_Manifold_Currents
manifold supply/return    -> GVL_STATE.G_Manifold_T_Supply / G_Manifold_T_Return
manifold end switches     -> GVL_STATE.G_Manifold_End_Switches
methane/CO                -> GVL_STATE.G_Methane_Sensors / G_CO_Sensors
boiler                    -> GVL_STATE.G_Boiler_Flame / G_Boiler_Error / G_Boiler_OT_Online
DHW                       -> GVL_STATE.G_DHW_Temp / G_DHW_Pressure
water zone feedback       -> GVL_STATE.G_Water_Zone_Open_FB / G_Water_Zone_Close_FB
```

Если любой пункт отсутствует, это должно быть явно объяснено в audit result.

---

## Relation to repository principles

Это правило соответствует:

- `AGENTS.md`: работать только от текущего observable repository state;
- `docs/MASTER_GUIDE.md`: не смешивать verification modes и не заявлять runtime-confirmation без Full Verification;
- `docs/WORKFLOW.md`: direct modification требует проверки по состоянию репозитория;
- `docs/IO_MAPPING_CONCEPT.md`: логика должна работать через logical/mapping/physical split, а не через случайные физические каналы.

---

## Статус

P0 debt formalized.

Следующий пункт по порядку:

```text
86_SAFETY_CLUSTER_2_CLEANUP_PLAN.md
```
