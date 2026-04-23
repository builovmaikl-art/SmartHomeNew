# Security / Access Boundary Check

Дата фиксации: 2026-04-23

## Назначение
Этот документ выполняет этап `SA-A4` из `51_SECURITY_ACCESS_AUDIT_PLAN.md`:
**boundary check** между `PRG_Security.st`, `FB_Security_System_Manager.st` и `FB_Access_Control.st`.

Цель:
- определить, является ли подтвержденный mismatch локальным interface defect;
- проверить, не указывает ли он на более широкую boundary problem между security и access responsibilities;
- отделить local fix direction от broader redesign.

## Основание
Документ опирается на:
- `52_SECURITY_ACCESS_LIVE_CALLSITE_AUDIT.md`
- `53_SECURITY_ACCESS_BLOCK_INTERFACE_AUDIT.md`
- `54_SECURITY_ACCESS_CALLSITE_VS_INTERFACE_COMPARISON.md`
- текущее состояние `PRG_Security.st`
- текущее состояние `FB_Security_System_Manager.st`
- текущее состояние `FB_Access_Control.st`

## Главный вывод
На текущем live root подтвержденный mismatch выглядит в первую очередь как **локальный call-site contract drift в `PRG_Security.st`**, а не как полный architectural collapse boundary между security и access слоями.

Иначе говоря:
- boundary между `FB_Security_System_Manager` и `FB_Access_Control` в целом читается и остается различимой;
- но `PRG_Security` сейчас передает в access block не весь system context, который уже требует evolved contract `FB_Access_Control`.

То есть проблема реальна и load-bearing, но по текущим данным это скорее:
- **local integration defect**,
а не доказанный symptom of deep role confusion between the two blocks.

## Как сейчас выглядит boundary

### SBC-01. `FB_Security_System_Manager` отвечает за охранную систему
По contract и внутренней логике блок отвечает за:
- arm/disarm flow;
- PIN/RFID/2FA authorization;
- arming delay / entry delay / alarm logic;
- siren/alarm/security status;
- 2FA send/code generation.

Вывод:
- это domain block охранной логики, а не access actuator block.

### SBC-02. `FB_Access_Control` отвечает за управление доступом и исполнительными командами доступа
По contract и внутренней логике блок отвечает за:
- gate/wicket/lock open/close pulse control;
- access authorization via PIN/RFID;
- auto-lock on arm transition;
- gating by `VI_IsActivePLC` and `VI_System_Mode`.

Вывод:
- это domain block access-control/action layer, а не охранная сигнализация как таковая.

### SBC-03. `PRG_Security` выступает как orchestration boundary между этими блоками
`PRG_Security.st`:
- сначала вызывает `fbSecurityManager(...)`;
- затем вызывает `fbAccessControl(...)`;
- передает security armed state вниз в access block;
- публикует access results в `GVL_INTENT_USER`.

Вывод:
- orchestration-level разбиение на security manager и access block в целом существует и читается.

## Что именно выглядит локально корректным

### SBC-04. Responsibility split между блоками в целом согласован
`FB_Security_System_Manager` не дублирует pulse-control logic ворот/замков.

`FB_Access_Control` не дублирует arming/alarm/2FA state machine охранной подсистемы.

Вывод:
- major responsibility overlap не подтвержден.

### SBC-05. Data-flow между слоями в целом логичен
Сейчас уже видно нормальный data-flow:
- security manager формирует armed/alarm/security state;
- access control использует `VI_Armed` как один из gating inputs;
- access outputs уходят в `GVL_INTENT_USER`, а дальше уже в command-layer execution path.

Вывод:
- общая high-level архитектурная линия security -> access -> intents читается и не выглядит случайной.

## Где именно проявляется boundary drift

### SBC-06. `FB_Access_Control` evolved до system-aware contract
Block contract требует:
- `VI_System_Mode`

И использует его как behavioral gate для `MODE_SAFE_STOP`.

Вывод:
- access block больше не является purely security-state-driven helper;
- он уже зависит от wider system context.

### SBC-07. `PRG_Security` по-прежнему передает только security-context subset
В текущем call-site передаются:
- `VI_Armed`
- HMI/config access requests
- PIN/RFID
- credential stores
- security config

Но не передается:
- `VI_System_Mode`

Вывод:
- `PRG_Security` orchestrates access block как будто ему достаточно security-context subset,
- тогда как actual access block contract уже требует broader system-context input.

## Интерпретация проблемы

### Boundary diagnosis
Текущий mismatch лучше всего описывается как:
- **boundary drift caused by contract evolution of `FB_Access_Control` not fully propagated to `PRG_Security`**.

Это не выглядит как доказательство того, что:
- security manager должен был поглотить access logic,
- или access block не должен зависеть от system mode вообще.

По текущему состоянию это скорее значит:
- orchestration layer `PRG_Security` не догнал фактическую эволюцию access block contract.

## Что пока НЕ подтверждено как broader boundary problem

### SBC-NO-01. Full responsibility confusion between security and access
Не подтверждено.

### SBC-NO-02. Need for immediate security/access redesign
Не подтверждено.

### SBC-NO-03. Incorrect presence of `VI_System_Mode` in `FB_Access_Control`
Тоже не подтверждено.

Наоборот, по текущему коду `VI_System_Mode` реально используется и выглядит осмысленным behavioral gate.

## Практический вывод для следующего шага
На текущем этапе рабочая интерпретация такова:
- **primary problem is local interface fix at the call-site/orchestration boundary**.

То есть следующим шагом логично рассматривать:
- локальную коррекцию `PRG_Security.st`,
где в `fbAccessControl(...)` будет передан корректный source для `VI_System_Mode`.

Только если при этом всплывут дополнительные расхождения, нужно будет поднимать вопрос о broader boundary cleanup.

## Что еще НЕ решает этот документ
Этот документ еще не выбирает:
- какой именно source подавать в `VI_System_Mode`;
- является ли лучшим кандидатом `GVL_STATE.G_System_Mode`;
- нужен ли adapter-style comment cleanup вокруг `PRG_Security` после fix.

Он только фиксирует:
- mismatch скорее локальный, чем архитектурно тотальный.

## Следующий рекомендуемый документ
- `56_SECURITY_ACCESS_FIX_DIRECTION_DECISION.md`

Его задача:
- выполнить этап `SA-A5`;
- принять решение, что именно является правильным remediation direction: local call-site fix или более широкий boundary cleanup.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения