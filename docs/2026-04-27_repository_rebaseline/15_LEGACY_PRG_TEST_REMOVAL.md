# 15 — Legacy PRG_Test Removal

Дата: 2026-04-27
Назначение: зафиксировать удаление устаревшего тестового PRG

---

## Объект удаления

```text
PRG_Test.st
```

---

## Исходное назначение

PRG_Test использовался как ранний unit-test для отдельных функциональных блоков:

```text
FB_Analog_Validator
FB_Random_Generator
FB_TwoFactor_Auth
```

---

## Причина удаления

```text
интерфейсы FB изменились
PRG_Test больше не компилируется при подключении
не используется в текущей архитектуре
не участвует в сценарной верификации
вводит в заблуждение как "актуальный тест"
```

---

## Замена

Актуальная система тестирования:

```text
PRG_System_Test_Harness
GVL_TEST
PRG_Scenario_Test_Harness
GVL_TEST_PANEL
```

---

## Решение

```text
PRG_Test удалён из репозитория
```

---

## Статус

```text
LEGACY REMOVED
REPOSITORY CLEANED
```
