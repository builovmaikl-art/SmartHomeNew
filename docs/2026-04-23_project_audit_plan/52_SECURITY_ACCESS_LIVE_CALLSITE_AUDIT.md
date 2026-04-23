# Security / Access Live Call-Site Audit

Дата фиксации: 2026-04-23

## Назначение
Этот документ выполняет этап `SA-A1` из `51_SECURITY_ACCESS_AUDIT_PLAN.md`:
**live call-site audit** для `fbAccessControl(...)` в `PRG_Security.st`.

Цель:
- зафиксировать точный текущий вызов `fbAccessControl(...)` по live root;
- отделить фактический call-site от любых предположений о правильном интерфейсе блока;
- подготовить чистую базу для следующего сравнения с `FB_Access_Control.st`.

## Проверенный объект
- `PRG_Security.st`

## Главный вывод этапа SA-A1
В текущем live root `fbAccessControl(...)` вызывается из `PRG_Security.st` как отдельный access-layer block после `fbSecurityManager(...)`.

Call-site уже показывает достаточно конкретную boundary-модель:
- security state (`VI_Armed`) приходит сверху из security manager outputs;
- user identity inputs (`PIN`, `RFID`) приходят из `GVL_INTENT_USER`;
- access open/close requests на вход подаются из `GVL_CONFIG.G_HMI_*`;
- результаты access-control публикуются обратно в `GVL_INTENT_USER`.

Это уже само по себе полезно, потому что boundary выглядит не как legacy command path, а как intent/config-centered access interface.

## Точный текущий вызов `fbAccessControl(...)`

### Входы (VI_*)
Подтвержденный набор входов:
- `VI_System_Time_MS := GVL_STATUS.G_System_Time_MS`
- `VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC`
- `VI_Armed := GVL_ALARM.G_Security_Armed`
- `VI_Gate_Open_Req := GVL_CONFIG.G_HMI_Gate_Open_Req`
- `VI_Wicket_Open_Req := GVL_CONFIG.G_HMI_Wicket_Open_Req`
- `VI_Lock_1_Open_Req := GVL_CONFIG.G_HMI_Lock_1_Open_Req`
- `VI_Lock_1_Close_Req := GVL_CONFIG.G_HMI_Lock_1_Close_Req`
- `VI_Lock_2_Open_Req := GVL_CONFIG.G_HMI_Lock_2_Open_Req`
- `VI_Lock_2_Close_Req := GVL_CONFIG.G_HMI_Lock_2_Close_Req`
- `VI_PIN_Code := GVL_INTENT_USER.I_PIN_Code`
- `VI_RFID_Tag := GVL_INTENT_USER.I_RFID_Tag`
- `VI_Access_Codes := GVL_Retain.G_Access_Codes`
- `VI_RFID_Tags := GVL_Retain.G_RFID_Tags`
- `VI_Config := GVL_CONFIG.G_Security_Config`

### Выходы (VO_*)
Подтвержденный набор выходов:
- `VO_Gate_Open => GVL_INTENT_USER.I_Gate_Open_Request`
- `VO_Wicket_Open => GVL_INTENT_USER.I_Wicket_Open_Request`
- `VO_Lock_1_Open => GVL_INTENT_USER.I_Lock_1_Open_Request`
- `VO_Lock_1_Close => GVL_INTENT_USER.I_Lock_1_Close_Request`
- `VO_Lock_2_Open => GVL_INTENT_USER.I_Lock_2_Open_Request`
- `VO_Lock_2_Close => GVL_INTENT_USER.I_Lock_2_Close_Request`

## Структура call-site boundary

### SAC-01. Security-to-access dependency
`fbAccessControl(...)` получает:
- `VI_Armed := GVL_ALARM.G_Security_Armed`

Вывод:
- access control зависит от security state,
- но не получает весь security manager contract целиком.

### SAC-02. Requests входного уровня идут из HMI/config surface
Open/close requests подаются через:
- `GVL_CONFIG.G_HMI_*`

Вывод:
- на текущем call-site access request surface выглядит config/HMI-centered,
- а не command-layer centered.

### SAC-03. Identity credentials идут через intent layer
Identity inputs подаются через:
- `GVL_INTENT_USER.I_PIN_Code`
- `GVL_INTENT_USER.I_RFID_Tag`

Вывод:
- security/access boundary уже partially aligned with intent-centered model.

### SAC-04. Access results публикуются в intent layer
Outputs `fbAccessControl(...)` направлены в:
- `GVL_INTENT_USER.I_Gate_Open_Request`
- `GVL_INTENT_USER.I_Wicket_Open_Request`
- `GVL_INTENT_USER.I_Lock_*`

Вывод:
- current call-site уже завязан на downstream intent publication,
- а не на legacy `GVL_COMMAND` access fields.

## Что еще НЕ утверждается этим этапом
Этот документ не утверждает:
- что call-site корректен относительно реального интерфейса `FB_Access_Control.st`;
- что `GVL_CONFIG.G_HMI_*` — окончательно правильный source для access requests;
- что boundary уже идеальна архитектурно.

Он утверждает только:
- какой вызов реально присутствует в live root на момент фиксации.

## Практический эффект этапа SA-A1
Теперь следующая проверка может сравнивать:
- не «впечатление о вызове»,
- а точный список текущих параметров call-site
с
- фактическим формальным интерфейсом `FB_Access_Control.st`.

Это создает нормальную baseline для подтверждения или опровержения interface mismatch.

## Следующий рекомендуемый документ
- `53_SECURITY_ACCESS_BLOCK_INTERFACE_AUDIT.md`

Его задача:
- выполнить этап `SA-A2`;
- снять фактический интерфейс `FB_Access_Control.st` и подготовить comparison matrix.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения