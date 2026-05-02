# Simulation Layer Audit (2026-05-02)

## Найденные проблемы

1. Прямая запись в GVL_STATE и GVL_STATUS
- Нарушает архитектуру (обход safety/command layers)
- Может оставлять "залипшие" аварии
- Невозможно корректно откатить состояние

2. Нарушение принципа single source of truth
- Simulation подменяет реальные данные
- Нет явного разделения test vs production

3. Необратимые изменения
- Давление обнулялось без восстановления
- Статусы аварий могли остаться навсегда

## Исправления

1. Введён изолированный слой GVL_SIMULATION.G_Sim_*
- Все fault injection теперь пишутся только туда
- Production state не модифицируется

2. PRG_System_Simulation переписан полностью
- Нет прямых записей в GVL_STATE
- Каждый цикл сбрасывает simulation outputs
- Simulation полностью обратима

3. Добавлена безопасная модель тестирования
- Simulation теперь декларативная (флаги)
- Не ломает pipeline

## Добавлено: сценарии

1. Gas Safety
2. Leak + Pressure
3. Sensor + Predictive
4. Dual PLC
5. Full Stress

- Управление: Start/Stop/Duration
- Авто-останов

## Текущий статус

✔ Simulation безопасен
✔ Есть сценарии
✔ Нет side-effects

## Осталось

- Интеграция в pipeline (Safety/Heating/Arbitration)
