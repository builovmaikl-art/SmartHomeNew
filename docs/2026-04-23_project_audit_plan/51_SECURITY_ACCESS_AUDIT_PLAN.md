# Security / Access Audit Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ открывает следующий major scope после `50_NEXT_MAJOR_SCOPE_AFTER_COMMAND_LAYER.md`:
**security / access interface audit**.

Цель:
- зафиксировать область нового цикла анализа;
- определить главный риск security/access boundary;
- разложить следующий audit на управляемые этапы;
- не смешивать interface audit с command-layer tail и следующей subsystem wave.

## Почему этот scope выбран следующим
После heating wave и command-layer wave именно security/access boundary остается следующим подтвержденным high-value integration risk.

Это хороший следующий шаг, потому что:
- ранее уже был отмечен вероятный interface mismatch;
- этот узел потенциально compile-sensitive;
- во время command-layer wave security-side bridge-tail уже был частично прояснен, и теперь interface audit можно делать на более чистой основе.

## Область security/access audit

### Основные файлы
- `PRG_Security.st`
- `FB_Access_Control.st`
- `FB_Security_System_Manager.st`

### Связанные точки
- `GVL_INTENT_USER`
- `GVL_CONFIG.G_Security_Config`
- `GVL_Retain.G_Access_Codes`
- `GVL_Retain.G_RFID_Tags`
- access/security related state and status publications

### При необходимости
- дополнительные файлы, если interface mismatch уводит в helper/struct/config contracts.

## Уже известный риск

### SAI-01. Вероятный interface mismatch между `PRG_Security` и `FB_Access_Control`
Ранее уже был отмечен риск, что фактический вызов `fbAccessControl(...)` может расходиться с текущим контрактом `FB_Access_Control.st`.

Это нужно перепроверить по live root заново и уже строго от кода, а не от старых заметок.

## Главные вопросы следующего аудита
Следующий цикл должен ответить на вопросы:
1. соответствует ли текущий вызов `fbAccessControl(...)` реальному интерфейсу блока;
2. есть ли mismatch по именам, типам, направлению параметров или составу контракта;
3. где именно проходит boundary между security logic и access logic;
4. что является локальным interface fix, а что уже тянет на более широкий redesign.

## Порядок аудита

### Этап SA-A1. Live call-site audit
Область:
- `PRG_Security.st`

Задача:
- зафиксировать текущий live вызов `fbAccessControl(...)`;
- выделить весь набор входов/выходов, который реально передается в блок.

Ожидаемый результат:
- точная call-site карта без предположений.

### Этап SA-A2. Block interface audit
Область:
- `FB_Access_Control.st`

Задача:
- зафиксировать текущий формальный интерфейс блока;
- разложить inputs/outputs и реальные типы/направления.

Ожидаемый результат:
- фактическая interface map блока.

### Этап SA-A3. Call-site vs interface comparison
Область:
- `PRG_Security.st`
- `FB_Access_Control.st`

Задача:
- сравнить call-site с interface block contract;
- подтвердить или опровергнуть mismatch;
- если mismatch есть, разложить его по типу:
  - missing parameter,
  - wrong name,
  - wrong direction,
  - wrong type,
  - outdated contract expectation.

Ожидаемый результат:
- подтвержденная mismatch matrix.

### Этап SA-A4. Security manager boundary check
Область:
- `FB_Security_System_Manager.st`
- связка с `PRG_Security.st`

Задача:
- понять, не вызван ли mismatch более широкой boundary problem между security и access responsibilities;
- отделить локальный interface defect от архитектурной роли каждого блока.

Ожидаемый результат:
- boundary interpretation security vs access layers.

### Этап SA-A5. Fix direction decision
Задача:
- на основе SA-A1..SA-A4 принять решение:
  - нужен ли локальный interface fix,
  - нужен ли adapter-style correction на стороне `PRG_Security`,
  - или проблема глубже и тянет на boundary cleanup plan.

Ожидаемый результат:
- remediation direction for security/access scope.

## Что пока НЕ делать
- не менять command-layer дополнительно в рамках этого цикла;
- не уходить сразу в ventilation wave;
- не править `PRG_Security` или `FB_Access_Control` до подтвержденного mismatch;
- не смешивать interface audit с broad security redesign.

## Практический следующий документ
- `52_SECURITY_ACCESS_LIVE_CALLSITE_AUDIT.md`

Его задача:
- открыть этап SA-A1;
- снять точный live вызов `fbAccessControl(...)` из `PRG_Security.st`.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения