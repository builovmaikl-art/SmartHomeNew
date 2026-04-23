# Security / Access Call-Site vs Interface Comparison

Дата фиксации: 2026-04-23

## Назначение
Этот документ выполняет этап `SA-A3` из `51_SECURITY_ACCESS_AUDIT_PLAN.md`:
**сравнение live call-site `fbAccessControl(...)` с формальным интерфейсом `FB_Access_Control.st`**.

Цель:
- сравнить фактический вызов в `PRG_Security.st` с declared contract блока;
- подтвердить или опровергнуть interface mismatch;
- разложить mismatch по типу и тяжести.

## Основание
Документ опирается на:
- `52_SECURITY_ACCESS_LIVE_CALLSITE_AUDIT.md`
- `53_SECURITY_ACCESS_BLOCK_INTERFACE_AUDIT.md`
- текущее состояние `PRG_Security.st`
- текущее состояние `FB_Access_Control.st`

## Главный вывод
По текущему live root между `PRG_Security.st` и `FB_Access_Control.st` действительно есть **подтвержденный interface mismatch**.

Он не выглядит тотальным — большая часть call-site соответствует интерфейсу.

Но mismatch есть как минимум в одном load-bearing месте:
- в live call-site отсутствует обязательный параметр `VI_System_Mode`, который реально используется внутри `FB_Access_Control.st` как behavioral gate.

Это означает:
- проблема не декоративная;
- это не просто stylistic drift;
- это реальный contract mismatch-кандидат compile/behavioral уровня.

## Comparison matrix

### Совпадающие параметры VAR_INPUT
Следующие параметры присутствуют и в call-site, и в declared interface:
- `VI_System_Time_MS`
- `VI_IsActivePLC`
- `VI_Armed`
- `VI_Gate_Open_Req`
- `VI_Wicket_Open_Req`
- `VI_Lock_1_Open_Req`
- `VI_Lock_1_Close_Req`
- `VI_Lock_2_Open_Req`
- `VI_Lock_2_Close_Req`
- `VI_PIN_Code`
- `VI_RFID_Tag`
- `VI_Config`

Вывод:
- основная access request / auth / config surface между call-site и block interface в целом согласована.

### Совпадающие параметры `VAR_IN_OUT`
Следующие параметры присутствуют и в call-site, и в declared interface:
- `VI_Access_Codes`
- `VI_RFID_Tags`

Вывод:
- credential-store boundary также совпадает по именам и общей роли.

### Совпадающие `VAR_OUTPUT`
Следующие параметры совпадают полностью:
- `VO_Gate_Open`
- `VO_Wicket_Open`
- `VO_Lock_1_Open`
- `VO_Lock_1_Close`
- `VO_Lock_2_Open`
- `VO_Lock_2_Close`

Вывод:
- output-side contract на текущем этапе выглядит полностью согласованным.

## Подтвержденный mismatch

### SAI-CMP-01. Missing required input: `VI_System_Mode`
В declared interface `FB_Access_Control.st` есть обязательный вход:
- `VI_System_Mode : E_System_Operating_Mode`

В текущем live call-site `fbAccessControl(...)` в `PRG_Security.st` этот параметр **не передается**.

Это и есть подтвержденный mismatch.

## Почему этот mismatch load-bearing

### SAI-CMP-02. `VI_System_Mode` реально используется внутри блока
Внутри `FB_Access_Control.st` подтверждено, что:
- при `VI_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP` блок принудительно сбрасывает ряд выходов и делает `RETURN`.

Вывод:
- `VI_System_Mode` не является необязательным metadata-input;
- это behavioral gate, влияющий на runtime contract блока.

### SAI-CMP-03. Call-site currently supplies security state, but not full system mode
В current call-site передается:
- `VI_Armed := GVL_ALARM.G_Security_Armed`

Но не передается:
- `VI_System_Mode := ...`

Вывод:
- boundary between security and access currently передает только security state,
- но не передает весь system context, который требует сам block contract.

## Классификация mismatch

### Тип mismatch
- **missing required parameter**

### Тяжесть
- **high / load-bearing**

### Почему не medium
Потому что отсутствующий параметр:
- declared formally,
- используется внутри блока,
- влияет на safe-stop gating поведения.

## Что НЕ подтверждено как mismatch на этом этапе

### SAI-CMP-NO-01. Output-side mismatch
Не подтверждено.

### SAI-CMP-NO-02. Name mismatch по access requests/auth fields
Не подтверждено.

### SAI-CMP-NO-03. Credential-store boundary mismatch
На уровне имен и общей contract-role не подтверждено.

## Практическая интерпретация
На текущем этапе ситуация выглядит так:
- интерфейс блока уже evolved до system-aware contract;
- live call-site в `PRG_Security.st` остался на более узкой security-only передаче контекста;
- mismatch therefore выглядит как **boundary drift between call-site and evolved block contract**.

Это важное уточнение:
- проблема выглядит не как полный слом access contract,
- а как локальный, но существенный разъезд между call-site и block evolution.

## Что пока НЕ решает этот документ
Этот документ еще не отвечает окончательно:
- какой именно fix direction правильный;
- должен ли `PRG_Security` передавать `GVL_STATE.G_System_Mode` или другой эквивалентный source;
- нужно ли править call-site только локально или пересматривать broader security/access boundary.

## Промежуточное решение для следующего шага
На текущем этапе можно считать подтвержденным:
- **primary current mismatch = missing `VI_System_Mode` in live call-site**.

Следующий шаг должен уже проверить, является ли это:
- локальным interface fix,
или
- симптомом более широкой boundary problem между `PRG_Security`, `FB_Access_Control` и `FB_Security_System_Manager`.

## Следующий рекомендуемый документ
- `55_SECURITY_ACCESS_BOUNDARY_CHECK.md`

Его задача:
- выполнить этап `SA-A4`;
- проверить, является ли mismatch локальным или указывает на более широкую boundary problem security vs access layers.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения