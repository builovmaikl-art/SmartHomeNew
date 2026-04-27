# 05 — Wave 5.1 Mode System Architecture

Дата: 2026-04-26
Wave: 5.1
Scope: behavior mode layer

---

## Контекст

Wave 5.0 ввёл System Coordinator как global constraint layer.

Wave 5.1 добавляет отдельный Behavior Mode layer, но не заменяет существующие safety/system modes.

---

## Важное разграничение

В системе уже есть:

```text
E_System_Operating_Mode
```

Этот режим отвечает за safety/system-operating состояние:

```text
NORMAL / DEGRADED / SAFE_STOP / FREEZE_PROTECTION
```

Также есть:

```text
E_SCENARIO_TYPE
```

Сценарии отвечают за пользовательские/автоматические сценарные профили.

---

## Новый слой

Wave 5.1 вводит не замену этим слоям, а отдельный layer:

```text
Behavior Mode
```

Он отвечает за режим поведения дома:

```text
HOME
AWAY
NIGHT
MAINTENANCE
```

---

## Ownership model

```text
PRG_Safety owns safety-stop
PRG_System owns E_System_Operating_Mode
Scenario manager owns E_SCENARIO_TYPE / Current_Scenario
Mode layer owns Behavior Mode
Coordinator consumes Behavior Mode and converts it into constraints
```

---

## Цель

Сделать поведение системы более явно управляемым:

```text
- HOME: normal comfort behavior
- AWAY: reduced comfort / restricted user overrides
- NIGHT: reduced lighting / quiet behavior
- MAINTENANCE: block automation where needed, allow service operations
```

---

## Proposed files

```text
E_Behavior_Mode.type
GVL_MODE.gvl
FB_Mode_Manager.st
PRG_Mode_Manager.st
```

---

## Phase 1 — observe-only

Создать mode layer, но не подключать его к подсистемам напрямую.

```text
Mode Manager publishes:
- current behavior mode
- mode change timestamp
- mode status code
```

Coordinator later consumes this as input.

---

## Priority relation

```text
Safety/System mode > Behavior mode > Scenario
```

Meaning:

```text
SAFE_STOP всегда важнее NIGHT/AWAY/HOME
```

---

## Integration with Coordinator

Wave 5.1 Phase 2:

```text
GVL_MODE.G_Current_Behavior_Mode -> PRG_System_Coordinator -> GVL_SYSTEM_COORDINATION block flags
```

Example:

```text
AWAY -> block selected overrides
NIGHT -> block/reduce lighting overrides
MAINTENANCE -> block automation constraints
```

---

## Non-goals

```text
- не менять PRG_Safety
- не менять E_System_Operating_Mode
- не переписывать Scenario Manager
- не подключать mode directly into PRG_Heating/Lighting/Ventilation on first step
```

---

## Acceptance criteria

```text
- mode layer exists
- no subsystem behavior changes in Phase 1
- coordinator can consume mode in Phase 2
- no duplicate ownership with system safety mode
```

---

## Status

```text
ARCHITECTURE DEFINED
```