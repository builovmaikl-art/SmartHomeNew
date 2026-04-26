# 84 — Post-audit Technical Debt Register

Дата фиксации: 2026-04-24
Последняя синхронизация: 2026-04-24
Режим: historical debt register + closure status

## Контекст

Этот документ начинался как реестр технического долга после восстановления IO / Diagnostics / Heating.

После выполнения последующих waves он больше не является списком открытых блокеров. Он фиксирует:

```text
- какие риски были выявлены;
- чем они были закрыты;
- что осталось только как правило сопровождения или future architecture topic.
```

---

## P0 — Protected core file policy для `PRG_IO_Read.st`

### Исходный риск

`PRG_IO_Read.st` несколько раз повреждался частичными update/merge-операциями:

```text
- терялись блоки чтения IO;
- появлялись заглушки вида `...`;
- runtime-связи заменялись сокращёнными шаблонами;
- после восстановления возникали ошибки из-за несверенных сигнатур FB.
```

### Выполненное закрытие

```text
- выполнено full-file восстановление `PRG_IO_Read.st`;
- удалены partial/omitted artifacts;
- закреплено правило: protected core не править сокращёнными шаблонами;
- дальнейшие injection/test hooks вынесены в отдельный `PRG_Test_Injection`, без правки IO core.
```

### Статус

```text
CLOSED AS POLICY
```

Правило сопровождения остаётся постоянным.

---

## P1 — `PRG_Safety.st`: cleanup Cluster 2

### Исходный риск

`PRG_Safety.st` смешивал:

```text
- core safety producer logic;
- operator/test/recover workflow;
- test timeout workflow;
- intent projection.
```

### Выполненное закрытие

```text
- создан `FB_Safety_Workflow_Manager`;
- operator/test/recover workflow вынесен из core safety body;
- `PRG_Safety.st` оставлен владельцем final safety intent projection;
- добавлен `FB_Ownership_Watchdog` как runtime контроль ownership-нарушений.
```

### Статус

```text
CLOSED
```

---

## P1 — Energy Management / Heating allocation extraction candidate

### Исходный риск

Развитие energy-management внутри `PRG_Heating.st` могло привести к смешению:

```text
- heating orchestration;
- energy arbitration;
- thermal load estimation;
- degradation policy.
```

### Выполненное закрытие в текущем audit scope

```text
- создан `FB_Heating_Decision_Context`;
- ограничения вынесены в decision-context;
- введены Allowed / Enabled состояния контуров;
- добавлены thermal weights;
- реализован priority-aware thermal allocation;
- `PRG_Heating` применяет constraints после base heating manager.
```

### Статус

```text
CLOSED FOR CURRENT AUDIT
```

Полный отдельный `FB_Heating_Energy_Manager` не требуется в текущем цикле. Возможен только как future architecture wave.

---

## P1 — Calibration mapping registry

### Исходный риск

Sensor pipeline был неоднороден:

```text
- часть через calibration;
- часть напрямую;
- часть через analog FB;
- часть без формального mapping-документа.
```

### Выполненное закрытие

```text
- создан calibration mapping registry;
- Supply temps переведены на calibration;
- Room humidity / CO2 переведены на calibration;
- Manifold supply / return temps переведены на calibration;
- Methane / CO переведены на calibration;
- DHW оставлен direct из-за отсутствия calibration-record path в текущем scope.
```

### Статус

```text
CLOSED
```

---

## P2 — Diagnostics severity/code model

### Исходный риск

Диагностика была выражена преимущественно через BOOL-флаги и строки.

### Выполненное закрытие

```text
- создан `ST_Diagnostic_Event`;
- добавлен `GVL_STATUS.G_Diagnostics_Events[1..50]`;
- добавлен `FB_Diagnostics_Event_Manager`;
- lifecycle событий построен по `Code + Source`;
- IO и Heating публикуют события через lifecycle manager;
- создан test harness для проверки duplicates / bounds.
```

### Статус

```text
CLOSED
```

---

## P2 — Safety bootstrap ownership review

### Исходный риск

`PRG_IO_Read.st` содержал bootstrap/reset присвоения safety-related полей, что нарушало producer ownership.

### Выполненное закрытие

```text
- удалены сбросы `G_Safety_Gas_Alarm`, `G_Safety_Leak_Alarm`, `G_Safety_Smoke_Alarm` из `PRG_IO_Read`;
- удалены сбросы `Backup_Pump_Fault` / `Electric_Heater_Fault` из `PRG_IO_Read`;
- ownership возвращён safety/heating producer layers;
- runtime контроль возможного нарушения реализован через `FB_Ownership_Watchdog` и `GVL_TEST.G_Ownership_Violation`.
```

### Статус

```text
CLOSED
```

---

## Финальный статус реестра

```text
NO OPEN BLOCKING DEBT IN THIS AUDIT SCOPE
```

Оставшиеся пункты являются не долгами текущего аудита, а future architecture candidates:

```text
- central arbitration layer;
- broader ventilation manager decomposition;
- optional lighting override redesign;
- hardware commissioning / compile validation.
```

---

## Правило дальнейших изменений

Любые новые работы после этого документа должны оформляться как отдельные planned waves, а не как продолжение recovery/audit режима.
