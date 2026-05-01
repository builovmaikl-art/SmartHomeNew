# Документация проекта SmartHomeNew

Эта папка содержит финальную русскоязычную проектную документацию по текущей архитектуре системы.

## Структура

1. `01_Архитектурный_обзор.md` — общая промышленная архитектура системы.
2. `02_Safety_Pipeline.md` — safety pipeline, fail-safe, recovery, shutdown.
3. `03_Data_Model_GVL.md` — модель данных и ownership GVL/PRG.
4. `04_Scenario_Adaptation_Confidence.md` — scenario engine, адаптация, confidence, reputation.
5. `05_HMI_Debug_Dashboard.md` — HMI/debug-view, диагностическая визуализация.
6. `06_FMEA_What_If.md` — сценарии отказов и what-if анализ.
7. `07_Production_Baseline.md` — baseline готовности и правила дальнейших изменений.

## Текущий статус

Система описывается как:

```text
Adaptive Safety Control System with Self-Learning Diagnostics
```

Ключевой runtime pipeline:

```text
IO → INPUT → SCENARIO/SAFETY → COMMAND → DOMAIN OUTPUT → IO
                         ↓
          TRACE / EXPLAINABILITY / DEBUG_VIEW / ADAPT
```

## Правило актуальности

Источником истины является текущий код репозитория. Эта документация фиксирует архитектурное состояние после проведённого рефакторинга и усиления pipeline.
