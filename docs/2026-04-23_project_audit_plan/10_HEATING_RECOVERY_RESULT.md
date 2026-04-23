# Heating Recovery Result

Дата фиксации: 2026-04-23

## Что было сделано
В живом корне репозитория восстановлен полный непрерывный `PRG_Heating.st`.

Основа восстановления:
- `snapshots/2026-04-22/PRG_Heating.st`

Внесенная минимальная recovery-адаптация:
- источник `VI_Preheat_Request` в вызове `fbHeatingManager(...)` переведен на current-live owner-слой:
  - было в recovery source: `GVL_HEATING_REQUEST.G_Preheat_Request`
  - стало в live root: `GVL_STATE.G_Preheat_Request`

Сохранено без отката:
- текущий call order в `MAIN.st`;
- текущие интерфейсы `FB_Heating_System_Manager.st` и `FB_DHW_Manager.st`;
- intent-based reset path для `fbDHWManager(...)` через `GVL_INTENT_USER.I_Reset_Errors`.

## Что подтверждено по состоянию репозитория

### RR-001. Корневой `PRG_Heating.st` больше не содержит placeholder-вставок
В live root отсутствуют сокращенные вставки вида:
- `omitted for brevity`
- `rest unchanged`

Вывод:
- корневой heating wrapper снова представлен как полноценный непрерывный source-файл.

### RR-002. Recovery выполнен без перестройки `MAIN.st`
`PRG_Heating()` остался на прежнем месте верхнего call order.

### RR-003. Recovery не изменял интерфейсы heating/DHW FB
Сигнатуры:
- `FB_Heating_System_Manager.st`
- `FB_DHW_Manager.st`

не менялись в рамках данного этапа.

### RR-004. Recovery не откатил DHW reset path в legacy command layer
В `PRG_Heating.st` сохранен intent-based reset:
- `VI_Reset_Errors := GVL_INTENT_USER.I_Reset_Errors`

### RR-005. Recovery выполнил минимальную owner-layer adaptation
Для `VI_Preheat_Request` не был выполнен rollback в `GVL_HEATING_REQUEST` как в основной owner-слой.

## Что НЕ утверждается после recovery

### NR-001
Не утверждается, что heating cluster теперь полностью архитектурно очищен.

### NR-002
Не утверждается runtime-успех без отдельной compile/run проверки.

### NR-003
Не утверждается, что ownership вокруг heating request layer окончательно идеален — утверждается только, что recovery выполнен без явного скрытого отката назад.

## Следующие темы после recovery
Следующим этапом должны идти уже post-recovery документы:
- ownership audit heating wrapper,
- cleanup публикаций в global layers,
- при необходимости отдельный functional cleanup heating/DHW cluster.

## Следующий рекомендуемый документ
- `11_HEATING_POST_RECOVERY_OWNERSHIP_AUDIT.md`

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения