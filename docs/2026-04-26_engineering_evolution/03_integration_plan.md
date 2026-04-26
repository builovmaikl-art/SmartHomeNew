# 03 — System Coordinator Integration Plan

Дата: 2026-04-26
Wave: 5.0

---

## Цель

Безопасно внедрить Coordinator слой **без влияния на текущую работу системы** (Phase 1), затем поэтапно подключить его флаги к подсистемам (Phase 2).

---

## Общие принципы

```text
- не трогаем PRG_IO_Read (protected core)
- не изменяем PRG_Safety (owner safety-stop)
- не ломаем PRG_Heating / Ventilation / Lighting
- сначала публикуем → наблюдаем → затем подключаем
```

---

## Phase 1 — Observe-only (без влияния)

### Шаги

1. Создать GVL_SYSTEM_COORDINATION
2. Реализовать FB_System_Coordinator
3. Создать PRG_System_Coordinator
4. Вставить в execution order
5. НИЧЕГО не подключать к доменным PRG

---

## Execution order (обновлённый)

```text
PRG_IO_Read
PRG_Test_Injection          // if enabled
PRG_Safety
PRG_System_Coordinator      // NEW (observe-only)
PRG_Command_Arbitration
PRG_Heating
PRG_Ventilation
PRG_Lighting
PRG_System_Test_Harness     // if enabled
PRG_IO_Write
```

---

## Подключение PRG_System_Coordinator

Минимальная интеграция:

```text
- добавить программу в task
- убедиться, что выполняется после PRG_Safety
- убедиться, что выполняется до доменных PRG
```

---

## Валидация Phase 1

Проверяем:

```text
✔ система компилируется
✔ поведение системы не изменилось
✔ GVL_SYSTEM_COORDINATION обновляется
✔ trace фиксирует коды координации
✔ test harness не показывает регрессий
```

---

## Наблюдаемые сигналы

```text
G_System_Degraded
G_Block_Heating
G_Block_Ventilation
G_Block_Lighting_Override
G_Block_Sockets_Override
G_Coordination_Code
```

---

## Phase 2 — Controlled Hook-up (поэтапно)

Подключаем ТОЛЬКО через constraints, без изменения ownership.

### Шаг 2.1 — Heating

В PRG_Heating (после manager, до финального enable):

```st
IF GVL_SYSTEM_COORDINATION.G_Block_Heating THEN
    // принудительно запрещаем включение контуров
    // (на уровне enable/allow, не переписывая алгоритм)
END_IF;
```

---

### Шаг 2.2 — Ventilation

```st
IF GVL_SYSTEM_COORDINATION.G_Block_Ventilation THEN
    // ограничение режимов вентиляции (кроме safety-driven)
END_IF;
```

---

### Шаг 2.3 — Lighting overrides

```st
IF GVL_SYSTEM_COORDINATION.G_Block_Lighting_Override THEN
    // запрет пользовательских override
END_IF;
```

---

### Шаг 2.4 — Sockets overrides

```st
IF GVL_SYSTEM_COORDINATION.G_Block_Sockets_Override THEN
    // запрет override розеток
END_IF;
```

---

## Правило подключения

```text
Coordinator НЕ пишет в actuator state
Coordinator только влияет на allow/enable слой
```

---

## Rollback стратегия

```text
Phase 1:
- удалить PRG_System_Coordinator из task

Phase 2:
- отключить использование GVL_SYSTEM_COORDINATION в доменных PRG
```

---

## Acceptance критерии

Phase 1:

```text
✔ нет изменения поведения
✔ все флаги корректны
✔ нет новых ошибок/предупреждений
```

Phase 2:

```text
✔ ограничения применяются предсказуемо
✔ safety поведение не нарушено
✔ test scenarios проходят
```

---

## Статус

```text
INTEGRATION PLAN READY
```