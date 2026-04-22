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

## Verification Modes Integration

The engineering process supports three modes:

### Full Verification Mode
- terminal execution
- git diff
- logs
→ only source of engineering-confirmed runtime truth

### Analytical Verification Mode
- repository inspection
- architecture validation
→ supports reasoning, not execution

### Direct Repository Modification Mode
- assistant performs direct repository updates
- verification is performed against resulting repository state (GitHub)

Rules:
- repository state after successful modification is considered real
- no execution/log confirmation is implied
- must be explicitly identified as non-terminal verification

Usage constraints:
- allowed for documentation, workflow, metadata
- allowed for structural refactors with explicit approval
- not default for safety-critical runtime logic


## POST TASK REQUIREMENTS
After each completed task:
- short summary of changes
- verification result (mode must be specified)
- next possible steps (2–3 options)
- recommended next step


## STRICT EXECUTION ORDER (UPDATED)

### Standard flow (Full Verification Mode)
1. Обсуждаем
2. Подтверждаем
3. Подготовка
4. steps/*
5. пакет
6. терминал
7. лог
8. проверка
9. дальше

### Direct Repository Mode flow
1. Обсуждаем
2. Подтверждаем
3. Прямое изменение репозитория
4. Проверка по состоянию файлов (GitHub)
5. Явное указание режима
6. дальше


## ENFORCEMENT RULES
- Не закрывать вход лишним диалогом
- Не путать режимы верификации
- Не описывать runtime результат без Full Verification Mode
- После каждого завершённого задания давать:
  - краткое описание
  - режим проверки
  - варианты следующих шагов
  - рекомендацию
