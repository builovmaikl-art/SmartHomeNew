# 03 — Bottom-Up Contract Verification

Дата: 2026-04-27
Назначение: фиксация контрактной целостности системы и выявленных недостатков перед этапом внедрения

---

## Режим проверки

```text
Direct Repository Modification Mode + Analytical Repository Verification
```

---

## Общий результат

```text
NO CONTRACT BREAKS DETECTED
SYSTEM IS STRUCTURALLY CONSISTENT
```

Контракты между слоями (GVL / FB / PRG) не нарушены.

---

## Найденные недостатки (фиксируются для последующего устранения)

Важно:

```text
Проект находится на этапе доведения до внедрения.
Все найденные проблемы фиксируются, но не исправляются в рамках текущего verification-pass.
```

---

### ISSUE-01 — Некорректная агрегация IO degraded

Файл:

```text
PRG_System_Coordinator.st
```

Текущая логика:

```text
VI_IO_Degraded := NOT GVL_STATUS.G_IO_Modules_Online[1]
```

Проблема:

```text
учитывается только первый IO модуль
```

Риск:

```text
частичная потеря IO не приведёт к system degraded
```

Рекомендация (не применять сейчас):

```text
агрегировать состояние всех IO модулей (ANY offline)
```

Приоритет:

```text
HIGH (для реальной эксплуатации)
```

---

### ISSUE-02 — Hardcoded timeout в Presence

Файл:

```text
PRG_Presence_Manager.st
```

Текущая логика:

```text
900000 ms (15 минут)
```

Проблема:

```text
магическое число в коде
```

Риск:

```text
невозможно адаптировать под реальные условия эксплуатации
```

Рекомендация:

```text
вынести в конфиг или constants
```

Приоритет:

```text
MEDIUM
```

---

### ISSUE-03 — Сложная сигнатура Heating Manager

Файл:

```text
PRG_Heating.st / FB_Heating_System_Manager
```

Проблема:

```text
очень большое количество входных параметров
```

Риск:

```text
высокая вероятность ошибок при модификациях
сложность тестирования
```

Рекомендация:

```text
в будущем рассмотреть декомпозицию или grouping inputs
```

Приоритет:

```text
MEDIUM
```

---

### ISSUE-04 — Частично неиспользуемые выходы workflow FB

Файл:

```text
FB_Safety_Workflow_Manager.st
```

Проблема:

```text
VO_*_Edge и VO_*_Active не используются в PRG_Safety
```

Риск:

```text
непонятно: зарезервировано или лишнее
```

Рекомендация:

```text
проверить downstream использование перед удалением
```

Приоритет:

```text
LOW
```

---

## Что подтверждено как корректное

```text
Coordinator contracts
Presence contracts
Mode contracts
Safety contracts
Heating base orchestration
Policy observe-only model
```

---

## Что категорически не трогать сейчас

```text
PRG_Safety core logic
MAIN execution order
Coordinator role (constraints only)
Heating without policy integration
```

Причина:

```text
система стабильна и готова к следующему этапу
```

---

## Следующие шаги

```text
04_COORDINATOR_DOMAIN_APPLICATION_CHECK.md
05_HEATING_POLICY_INTEGRATION_PLAN.md
```

---

## Статус

```text
BOTTOM-UP CONTRACT VERIFICATION COMPLETED
ISSUES RECORDED FOR FUTURE RESOLUTION
SYSTEM READY FOR CONTROLLED IMPROVEMENTS
```