# Ventilation Manager Contract Audit

Дата фиксации: 2026-04-23

## Назначение
Этот документ выполняет этап `V-A2` из `62_VENTILATION_AUDIT_PLAN.md`:
**manager contract audit** для `FB_Ventilation_System_Manager.st`.

Цель:
- зафиксировать фактический контракт manager-блока;
- понять, где реально сосредоточена сложная ventilation logic;
- определить, является ли manager узким исполнительным блоком или более широким policy/decision center.

## Проверенный объект
- `FB_Ventilation_System_Manager.st`

## Главный вывод этапа V-A2
`FB_Ventilation_System_Manager.st` в текущем live root является не просто узким actuator helper, а **реальным центром вентиляционной decision/policy logic**.

Внутри него сосредоточены сразу несколько уровней ответственности:
- system-policy gating по `VI_System_Mode`;
- active/standby gating;
- IO fault handling;
- scenario-based base behavior;
- heater PID control;
- wet-zone exhaust behavior;
- rule-action overrides;
- final degraded clamp и статусная публикация.

Вывод:
- ventilation manager уже сам по себе несет заметный ownership/logic слой;
- wrapper действительно тонкий, а основная сложность кластера сосредоточена внутри manager.

## Формальный контракт блока

### VAR_INPUT
Подтвержденный набор входов:
- `VI_System_Time_MS : UDINT`
- `VI_IsActivePLC : BOOL`
- `VI_Outdoor_Temp : REAL`
- `VI_Current_Scenario : E_SCENARIO_TYPE`
- `VI_System_Mode : E_System_Operating_Mode`
- `VI_Config : ST_Ventilation_Global_Config`
- `VI_Fire_Alarm : BOOL`
- `VI_Gas_Alarm : BOOL`
- `VI_PV3_Boost_Req : BOOL`
- `VI_Supply_100_Req : BOOL`
- `VI_Exhaust_100_Req : BOOL`
- `VI_Supply_80_Req : BOOL`
- `VI_Vent_Stop : BOOL`
- `VI_IO_Modules_Online : ARRAY[1..GVL_CONSTANTS.C_MAX_MODULES] OF BOOL`

### VAR_IN_OUT
Подтвержденный набор `VAR_IN_OUT` параметров:
- `VI_Supply_Temps`
- `VI_Room_Temps`
- `VI_Room_Humidities`
- `VI_Room_CO2`
- `VI_Wet_Zone_Active`
- `VI_Rule_Actions`

### VAR_OUTPUT
Подтвержденный набор выходов:
- `VO_Supply_Fans`
- `VO_Exhaust_Fans`
- `VO_Heater_Power`
- `VO_Status_Msg`

## Семантическая структура контракта

### VMC-01. System-policy context входит прямо в manager
Блок требует:
- `VI_IsActivePLC`
- `VI_Current_Scenario`
- `VI_System_Mode`
- `VI_IO_Modules_Online`

Вывод:
- contract сразу system-aware;
- manager не ограничивается только локальными вентиляционными параметрами.

### VMC-02. Environmental and domain inputs входят прямо в manager
Блок принимает:
- supply temps,
- room temps,
- humidities,
- CO2,
- wet-zone activity.

Вывод:
- manager замыкает на себе основную domain telemetry surface вентиляции.

### VMC-03. Command/policy requests тоже входят прямо в manager
Блок принимает operational requests:
- `VI_PV3_Boost_Req`
- `VI_Supply_100_Req`
- `VI_Exhaust_100_Req`
- `VI_Supply_80_Req`
- `VI_Vent_Stop`

Вывод:
- manager является конечным consumer layer для ventilation-related command requests.

### VMC-04. Config dependency довольно широкая
Через `VI_Config : ST_Ventilation_Global_Config` блок использует:
- scenario settings,
- pulse/limit style parameters,
- degraded exhaust limit,
- wet-zone mapping.

Вывод:
- manager уже глубоко завязан на ventilation global config contract.

## Внутренние behavioral centers

### VMC-05. Policy layer по `VI_System_Mode` находится внутри manager
Внутри блока есть явный policy layer:
- `L_Policy_Normal`
- `L_Policy_Safe_Stop`
- `L_Policy_Degraded`
- `L_Policy_Freeze_Protection`

И далее:
- safe-stop делает полный stop и `RETURN`;
- freeze protection делает stop и `RETURN`;
- degraded выключает supply/heaters, выставляет subsystem degraded и задает message.

Вывод:
- ключевой policy routing расположен именно в manager, не во wrapper.

### VMC-06. Active/standby gate находится внутри manager
Если `NOT VI_IsActivePLC`, блок:
- гасит outputs,
- выставляет standby message,
- делает `RETURN`.

Вывод:
- execution gating централизован в manager.

### VMC-07. IO-fault handling находится внутри manager
Блок сам проверяет `VI_IO_Modules_Online`.

При fault:
- выставляет `GVL_STATE.G_Ventilation_IO_Fault := TRUE`;
- гасит supply/exhaust/heaters;
- публикует error status;
- делает `RETURN`.

Вывод:
- manager содержит не только control logic, но и fault reaction logic с прямой записью в global state.

### VMC-08. Scenario-based baseline behavior находится внутри manager
По `VI_Current_Scenario` блок выбирает:
- `L_Base_Speed`
- `L_Target_Temp`

Вывод:
- scenario interpretation также централизована в manager.

### VMC-09. Heater PID control живет внутри manager
Для supply lines блок запускает массив `FB_PID_Controller` и пишет в `VO_Heater_Power`.

Вывод:
- thermal control часть вентиляции тоже находится внутри manager.

### VMC-10. Wet-zone exhaust behavior живет внутри manager
Для exhaust side блок использует:
- `VI_Wet_Zone_Active`
- `L_Wet_Zone_Timers`
- `VI_Config.wet_zone_to_exhaust_map`

и формирует boosted/overrun exhaust behavior.

Вывод:
- локальная domain policy вытяжки санузлов сосредоточена именно здесь.

### VMC-11. Rule-action overrides живут внутри manager
Блок проходит `VI_Rule_Actions` и может переопределять скорости притока.

Вывод:
- manager также интегрирован с rule-engine layer.

### VMC-12. Final status publication тоже живет внутри manager
Финальный `VO_Status_Msg` формируется внутри блока на основе policy state.

Вывод:
- manager завершает не только control outputs, но и статусную интерпретацию.

## Первая интерпретация ownership

### VMC-13. Manager является главным owner сложной вентиляционной логики
На текущем уровне уже видно, что именно manager, а не wrapper:
- интерпретирует scenario,
- применяет system mode policy,
- реагирует на IO faults,
- управляет heaters/fans,
- обрабатывает wet-zone behavior,
- формирует status message.

Вывод:
- ventilation cluster по своей основной сложности сосредоточен в `FB_Ventilation_System_Manager.st`.

### VMC-14. Manager уже не выглядит узким reusable primitive
Из-за ширины responsibilities это скорее:
- domain manager / policy engine,
а не:
- маленький helper для управления вентиляторами.

Вывод:
- следующий boundary audit должен особенно внимательно сравнить, не перегружен ли manager responsibilities, которые стоило бы держать выше.

## Что пока НЕ утверждается этим этапом
Этот документ не утверждает:
- что такая концентрация logic внутри manager уже является дефектом;
- что manager обязательно требует decomposition;
- что wrapper/manager boundary уже нарушена.

Он утверждает только:
- manager — это реальный центр сложной вентиляционной логики, а не тонкий исполнительный leaf-block.

## Практический эффект этапа V-A2
После этого шага можно уверенно сказать:
- основная ventilation risk surface находится внутри `FB_Ventilation_System_Manager.st`;
- дальнейший аудит должен смотреть не только на интерфейс, но и на распределение responsibilities между wrapper и manager;
- ventilation wave, вероятно, будет решаться через boundary/ownership analysis manager-centric типа, а не через wrapper cleanup first.

## Следующий рекомендуемый документ
- `65_VENTILATION_WRAPPER_VS_MANAGER_BOUNDARY_AUDIT.md`

Его задача:
- выполнить этап `V-A3`;
- сравнить responsibilities wrapper и manager и решить, где проходит адекватная boundary вентиляционного кластера.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения