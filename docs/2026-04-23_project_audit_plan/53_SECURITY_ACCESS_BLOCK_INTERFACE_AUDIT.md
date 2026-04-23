# Security / Access Block Interface Audit

Дата фиксации: 2026-04-23

## Назначение
Этот документ выполняет этап `SA-A2` из `51_SECURITY_ACCESS_AUDIT_PLAN.md`:
**block interface audit** для `FB_Access_Control.st`.

Цель:
- зафиксировать фактический формальный интерфейс блока;
- отделить block contract от call-site `PRG_Security.st`;
- подготовить чистую базу для следующего comparison step.

## Проверенный объект
- `FB_Access_Control.st`

## Главный вывод этапа SA-A2
`FB_Access_Control.st` имеет более богатый и более строгий интерфейс, чем можно было бы ожидать только по смыслу названия блока.

По формальному contract у блока есть:
- **10 обычных входов до access-requests/auth/config section**,
- **6 access request входов**,
- **2 credential inputs**,
- **1 config input**,
- **2 `VAR_IN_OUT` параметра**,
- **6 выходов**.

Уже на уровне формального интерфейса видно потенциально чувствительное место:
- `VI_System_Mode` является обязательным `VAR_INPUT` параметром блока.

Это не означает mismatch автоматически, но делает следующий comparison step особенно важным.

## Формальный интерфейс `FB_Access_Control`

### VAR_INPUT
Подтвержденный набор входов:
- `VI_System_Time_MS : UDINT`
- `VI_IsActivePLC : BOOL`
- `VI_Armed : BOOL`
- `VI_System_Mode : E_System_Operating_Mode`
- `VI_Gate_Open_Req : BOOL`
- `VI_Wicket_Open_Req : BOOL`
- `VI_Lock_1_Open_Req : BOOL`
- `VI_Lock_1_Close_Req : BOOL`
- `VI_Lock_2_Open_Req : BOOL`
- `VI_Lock_2_Close_Req : BOOL`
- `VI_PIN_Code : STRING(4)`
- `VI_RFID_Tag : STRING(20)`
- `VI_Config : ST_Security_Global_Config`

### VAR_IN_OUT
Подтвержденный набор `VAR_IN_OUT` параметров:
- `VI_Access_Codes : ARRAY[1..GVL_CONSTANTS.C_MAX_ACCESS_CODES] OF DWORD`
- `VI_RFID_Tags : ARRAY[1..GVL_CONSTANTS.C_MAX_ACCESS_CODES] OF STRING(20)`

### VAR_OUTPUT
Подтвержденный набор выходов:
- `VO_Gate_Open : BOOL`
- `VO_Wicket_Open : BOOL`
- `VO_Lock_1_Open : BOOL`
- `VO_Lock_1_Close : BOOL`
- `VO_Lock_2_Open : BOOL`
- `VO_Lock_2_Close : BOOL`

## Семантическая структура интерфейса

### SBI-01. System context inputs
Блок требует системный контекст:
- `VI_System_Time_MS`
- `VI_IsActivePLC`
- `VI_Armed`
- `VI_System_Mode`

Вывод:
- блок не является узким pure-access helper;
- он зависит от более широкого system/security context.

### SBI-02. Access request inputs
Основная request-surface блока:
- gate / wicket / lock open/close requests.

Вывод:
- block contract ориентирован на discrete access-control actions, а не на общий command aggregation.

### SBI-03. Authorization inputs
Блок принимает:
- `VI_PIN_Code`
- `VI_RFID_Tag`

и использует отдельный `FB_AccessCode_Manager` для проверки.

Вывод:
- authorization встроена в сам access block contract.

### SBI-04. Security configuration dependency
Блок требует:
- `VI_Config : ST_Security_Global_Config`

и использует из него pulse durations.

Вывод:
- access block жестко завязан на security global config contract.

### SBI-05. Mutable credential stores via `VAR_IN_OUT`
Блок принимает по `VAR_IN_OUT`:
- `VI_Access_Codes`
- `VI_RFID_Tags`

Вывод:
- contract здесь не просто input-only;
- блок формально имеет доступ к mutable credential stores через `VAR_IN_OUT` boundary.

## Внутренние behavioral markers, важные для следующего comparison step

### SBI-06. `VI_System_Mode` реально используется внутри блока
Внутри `FB_Access_Control.st` подтверждено:
- при `VI_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP` блок принудительно гасит ряд выходов и делает `RETURN`.

Вывод:
- `VI_System_Mode` не является декоративным параметром;
- это значимый behavioral dependency.

### SBI-07. `VI_IsActivePLC` тоже является behavioral gate
Если `NOT VI_IsActivePLC`, блок делает `RETURN`.

Вывод:
- access block contract включает explicit active/standby execution gate.

### SBI-08. `VI_Armed` участвует и в authorization logic, и в auto-lock logic
Внутри блока:
- `VI_Armed` влияет на auto-lock request;
- `VI_Armed` участвует в условиях gate/wicket/lock opening.

Вывод:
- security-state dependency блока является реальной, а не формальной.

## Что этот этап еще НЕ утверждает
Этот документ не утверждает:
- что текущий call-site `PRG_Security.st` соответствует этому интерфейсу;
- что mismatch уже точно есть;
- что block contract правильный архитектурно.

Он утверждает только:
- какой формальный интерфейс реально объявлен в `FB_Access_Control.st`;
- какие параметры являются behavioral, а не декоративными.

## Практический эффект этапа SA-A2
Теперь следующая проверка может сравнить:
- точный live call-site из `PRG_Security.st`
с
- точным формальным интерфейсом `FB_Access_Control.st`

и уже без догадок определить:
- есть ли mismatch,
- где именно он находится,
- насколько он локален или архитектурно симптоматичен.

## Следующий рекомендуемый документ
- `54_SECURITY_ACCESS_CALLSITE_VS_INTERFACE_COMPARISON.md`

Его задача:
- выполнить этап `SA-A3`;
- построить точную mismatch matrix между call-site и block interface.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения