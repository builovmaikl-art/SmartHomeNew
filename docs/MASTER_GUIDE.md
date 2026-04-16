# MASTER GUIDE — SmartHomeNew

## Core Architecture

Subsystems → FB_System_Health → FB_State_Manager → Policy → Subsystems

System is centralized and mode-driven.
Diagnostics is part of the core.

## Principles
- Safety > Comfort
- Fail-safe mandatory
- No direct fault handling in subsystems
- Only System Mode drives behavior

## Layers

### FB_System_Health
- Aggregates faults
- Root cause (type + source)
- Latch + reset

### FB_State_Manager
- Determines System Mode
- Uses ONLY health inputs

### Policy Layer
- Executes behavior based on mode
- No direct diagnostics usage

## Modes
- NORMAL
- DEGRADED
- FREEZE_PROTECTION
- SAFE_STOP


## ENGINEERING PROCESS RULES
- Work via steps/** packages
- Do not produce intermediate explanations
- Apply changes silently, verify, then report
- Always validate in repo, not assumptions
- No partial completion


## POST TASK REQUIREMENTS
After each completed task:
- short summary of changes
- verification result (from repo/logs)
- next possible steps (2–3 options)
- recommended next step


## STRICT EXECUTION ORDER
1. Обсуждаем.
2. Подтверждаем решение.
3. Я молча готовлю правки.
4. Сохраняю правки в `steps/YYYY-MM-DD_*`.
5. По команде собираю единый пакет.
6. Даю код для терминала: обновить / применить / синхронизировать с `main`.
7. Ты присылаешь лог терминала.
8. Я проверяю результат по фактическим файлам репо.
9. Только если всё корректно встало — идём дальше.

## ENFORCEMENT RULES
- Не закрывать вход лишним диалогом.
- Не считать правки внесёнными, пока пакет не применён и лог не проверен.
- Не описывать результат как факт до проверки по репо.
- После каждого завершённого задания давать:
  - краткое описание, что сделано
  - статус проверки
  - 2–3 варианта следующих шагов
  - рекомендуемый следующий шаг
