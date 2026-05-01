# FINAL CODE-FIRST AUDIT — 2026-05-01

> Scope: фактический аудит по коду, а не по существующей документации.
>
> Проверялись текущие `.st` / `.gvl` файлы репозитория через фактическое чтение кода: `MAIN`, safety/recovery, command layer, domains, output projections, IO, trace/debug/adapt/input layers.
>
> Важно: компилятор CODESYS в этом проходе не запускался. Отчёт фиксирует статическую целостность, потоки данных, compile-risk по символам и архитектурные разрывы по коду.

---

## 1. Executive Summary

Система архитектурно сильно продвинута: есть `INPUT`, `SAFETY`, `RECOVERY`, `SCENARIO`, `COMMAND`, `DOMAIN`, `OUTPUT_PROJECTION`, `TRACE`, `EXPLAINABILITY`, `DEBUG_VIEW`, `ADAPT`.

Но текущий код НЕ находится в состоянии “полностью закрытого production pipeline”. Найдены критические разрывы:

1. **Compile-blocker:** `PRG_User_Adapt_Control` использует `REASON_SAFETY`, которого нет в `E_System_Reason_Code`.
2. **Command Arbitration regression:** текущий `PRG_Command_Arbitration` покрывает только `FIRE` и частично `NORMAL`; отсутствуют фактические ветки `GAS`, `WATER_LEAK`, `GLOBAL_STOP`, `EVACUATION`, пользовательские access-запросы и safety-команды вентиляции/воды/газа.
3. **IO Write regression:** текущий `PRG_IO_Write` пишет только `GVL_IO.DO_Zone_Valves`; большая часть физических выходов из projection-слоёв не доходит до `GVL_IO`.
4. **Command reset incomplete:** `PRG_Command_Arbitration` не сбрасывает часть полей `GVL_COMMAND_SHADOW`, значит возможны stale-команды.
5. **Behavior/Input split incomplete:** создан `GVL_INPUT`, но `PRG_Scenario_Engine` и diagnostics продолжают читать `GVL_STATE` напрямую.
6. **Adaptive feedback weak:** feedback использует фиксированный baseline `L_PrevHum := 70.0`, не фактическое предыдущее значение по зоне.
7. **Explainability partial:** объяснения есть, но не покрывают реальные причины всех команд и отказов.

---

## 2. MAIN Pipeline Audit

Текущий порядок вызовов:

```text
PRG_Time_Service
PRG_IO_Read
PRG_Input_Processing
PRG_User_Adapt_Control
PRG_Behavior_Adapt_Profile
PRG_Safety
PRG_Safety_Shutdown
PRG_Safety_Recovery
...
PRG_Scenario_Engine
PRG_Command_Arbitration
PRG_Command_Verifier
PRG_Security
PRG_Heating
PRG_Ventilation
PRG_Lighting
PRG_Water
PRG_Access
PRG_Explainability
PRG_Debug_View
PRG_IO_Write
```

### Хорошо

- `Input_Processing` стоит после `IO_Read`.
- `User_Adapt_Control` стоит до `Behavior_Adapt_Profile`, значит профиль может примениться в том же цикле.
- `Scenario` стоит до `Command_Arbitration`.
- Домены стоят после command layer.
- `Explainability` и `Debug_View` стоят после доменов и до IO-write.

### Риск

`PRG_System_Diagnostics` стоит до `PRG_Scenario_Engine`, но adaptive feedback внутри diagnostics читает `GVL_INTENT_BEHAVIOR`. Это значит, что feedback работает по intent предыдущего цикла, а не текущего.

Статус: не compile-blocker, но важно для поведения адаптации.

---

## 3. Compile-Level Symbol Audit

### 3.1 Critical: `REASON_SAFETY` is missing

Файл: `PRG_User_Adapt_Control.st`

Используется:

```pascal
fbTrace(
    iLayer := TRACE_USER,
    iSource := SRC_USER,
    iReason := REASON_SAFETY,
    ...
);
```

Но `GVL_EXPLAINABILITY.gvl` содержит enum `E_System_Reason_Code` без `REASON_SAFETY`.

Фактический enum содержит:

```text
REASON_NONE
REASON_FIRE
REASON_GAS
REASON_WATER_LEAK
REASON_GLOBAL_STOP
REASON_EVACUATION
REASON_RECOVERY_ACTIVE
REASON_USER_REQUEST
REASON_COMMAND_CLAMP
REASON_DOMAIN_PROJECTION
REASON_SCENARIO_*
```

### Severity

```text
CRITICAL / COMPILE-BLOCKER
```

### Required fix

Добавить `REASON_SAFETY` в `E_System_Reason_Code` или заменить в `PRG_User_Adapt_Control` на существующий код, например `REASON_RECOVERY_ACTIVE` / `REASON_COMMAND_CLAMP` / `REASON_USER_REQUEST` с текстом отказа.

---

## 4. Command Arbitration Audit

Файл: `PRG_Command_Arbitration.st`

### Фактическое состояние

Текущий код:

- сбрасывает часть `GVL_COMMAND_SHADOW`;
- обрабатывает только:
  - `FIRE`
  - `NORMAL` с `I_Request_Ventilation_Boost`
- recovery clamp ставит Heating block и Vent stop.

### Critical gaps

#### 4.1 GAS не обрабатывается

Ожидаемо:

```text
GAS → Heating block / gas valve close / boiler stop / vent strategy
```

Фактически ветки `GAS` нет.

#### 4.2 WATER_LEAK не обрабатывается

Ожидаемо:

```text
WATER_LEAK → G_Water_Block + G_Close_Valve_35/36
```

Фактически ветки нет.

#### 4.3 GLOBAL_STOP не обрабатывается

Ожидаемо:

```text
GLOBAL_STOP → block Heating/Vent/Water and possibly other safe stops
```

Фактически ветки нет.

#### 4.4 EVACUATION не обрабатывается

Ожидаемо:

```text
EVACUATION → locks/gate/wicket open
```

Фактически ветки нет.

#### 4.5 User access intent не проходит

`GVL_INTENT_USER` содержит:

```text
I_Gate_Open_Request
I_Wicket_Open_Request
I_Lock_1_Open_Request
I_Lock_1_Close_Request
I_Lock_2_Open_Request
I_Lock_2_Close_Request
```

Но `PRG_Command_Arbitration` сейчас не переносит их в `GVL_COMMAND_SHADOW`.

#### 4.6 Safety ventilation commands не проходят

`GVL_COMMAND_SHADOW` содержит:

```text
G_Supply_100_Req
G_Supply_80_Req
G_Vent_PV3_Boost
G_Exhaust_100_Req
G_Vent_Stop
G_Vent_Block
```

Но arbitration сейчас не выставляет safety boost/stop кроме `G_Vent_Stop` в FIRE/recovery.

#### 4.7 Incomplete reset

В `GVL_COMMAND_SHADOW` есть поля:

```text
G_Gas_Valve_Close
G_Boiler_Stop
G_Supply_100_Req
G_Supply_80_Req
G_Vent_PV3_Boost
G_Exhaust_100_Req
G_Heating_DHW_Block
G_Heating_Gas_Safety_Stop
```

Текущий reset в `PRG_Command_Arbitration` их не сбрасывает.

### Severity

```text
CRITICAL / BEHAVIOR-BREAKING
```

### Required fix

Переписать `PRG_Command_Arbitration.st` целиком, восстановив полный CASE:

```text
FIRE
GAS
WATER_LEAK
GLOBAL_STOP
EVACUATION
NORMAL
```

и полный reset всех полей `GVL_COMMAND_SHADOW`.

---

## 5. IO Write Audit

Файл: `PRG_IO_Write.st`

### Фактическое состояние

Сейчас `PRG_IO_Write`:

- вычисляет `L_Heating_Forced_Off`, `L_Vent_Forced_Off`, `L_Water_Forced_Off`;
- пишет только:

```pascal
GVL_IO.DO_Zone_Valves[L_i]
```

### Critical gap

`GVL_IO.gvl` содержит много физических выходов:

```text
DO_Manifold_Pumps
AO_Manifold_Valves
DO_DHW_Heating_Pump
DO_DHW_Circ_Pump
DO_Backup_Circulation_Pump
DO_Electric_Heater_Enable
AO_Supply_Fans
AO_Exhaust_Fans
DO_Water_Valve_35_Close
DO_Water_Valve_36_Close
DO_Water_Zone_Enable
DO_Gate_Open
DO_Wicket_Open
DO_Lock_1_Open/Close
DO_Lock_2_Open/Close
DO_Gas_Valve_Close
sirens
lighting/sockets/blinds
```

но текущий `PRG_IO_Write` их не пишет.

### Projection layers exist

Фактически существуют:

```text
GVL_HEATING_OUTPUT
GVL_VENT_OUTPUT
GVL_WATER_OUTPUT
GVL_ACCESS_OUTPUT
```

Но они не полностью потребляются `PRG_IO_Write`.

### Severity

```text
CRITICAL / OUTPUT-BREAKING
```

### Required fix

Переписать `PRG_IO_Write` целиком:

- Heating:
  - zone valves
  - manifold pumps
  - manifold analog valves
  - DHW pumps
  - backup circulation
  - electric heater
- Ventilation:
  - supply/exhaust fans
  - vent enable/stop clamp
- Water:
  - valve 35/36 close
  - zone enable
- Access:
  - locks/gate/wicket
- Gas/Safety:
  - gas valve close
  - sirens if applicable
- Lighting/Sockets/Blinds:
  - either preserve current domain output path or explicitly document not in this write layer.

---

## 6. Safety / Recovery Audit

### 6.1 `PRG_Safety`

Strengths:

- Resets `GVL_INTENT_SAFETY` every cycle.
- Uses `FB_Water_Leakage_Manager` and `FB_Gas_Smoke_Manager`.
- Projects smoke/gas/leak/freeze into safety intent.

Risks:

- Some safety state still comes from `GVL_STATE.G_Safety_*_Latched`, while new `GVL_INPUT` exists but is not used.
- Safety intent includes evacuation, gas close, water close, boiler stop, vent requirements, but `PRG_Command_Arbitration` currently does not consume most of these downstream.

### 6.2 `PRG_Safety_Shutdown`

Strengths:

- Clear priority: `FIRE > GAS > WATER > GLOBAL_STOP > NORMAL`.

Risk:

- `EVACUATION` exists in earlier command design but shutdown does not select `EVACUATION`; evacuation intent is set in `PRG_Safety`, but not translated into `G_Safety_Mode := EVACUATION`.

### 6.3 `PRG_Safety_Recovery`

Strengths:

- Has phases: `IDLE`, `STABILIZING`, `WAIT_MANUAL_CONFIRM`, `RECOVERING`.
- Manual confirm uses `GVL_INTENT_USER.I_Reset_Errors`.

Risks:

- `G_Recovery_Requested` must be set somewhere else; this pass did not verify a reliable producer.
- Recovery active only clamps heating and vent in arbitration; water/access recovery behavior is not fully represented.

---

## 7. Domain Audit

### 7.1 Heating

Strengths:

- `PRG_Heating` no longer directly writes most actuators to `GVL_STATE`.
- Uses local buffers and `FB_Heating_Output_Projection`.
- Reads command-aware gates:
  - `G_Heating_Emergency_Stop`
  - `G_Heating_Gas_Safety_Stop`
  - `G_Heating_DHW_Block`
  - `G_Heating_Block`

Critical upstream issue:

- Current `PRG_Command_Arbitration` does not fully set `G_Heating_Gas_Safety_Stop`, `G_Heating_DHW_Block`, `G_Boiler_Stop`.

Critical downstream issue:

- Current `PRG_IO_Write` only writes zone valves, not manifold pumps, manifold valves, DHW pumps, backup pump, electric heater.

### 7.2 Ventilation

Strengths:

- `PRG_Ventilation` reads command layer:
  - `G_Vent_PV3_Boost`
  - `G_Supply_100_Req`
  - `G_Exhaust_100_Req`
  - `G_Supply_80_Req`
  - `G_Vent_Stop`
- Uses `FB_Vent_Output_Projection`.

Critical upstream issue:

- Command arbitration does not currently set most of those fields.

Critical downstream issue:

- IO write does not currently write `GVL_VENT_OUTPUT.AO_Supply_Fans` / `AO_Exhaust_Fans` to `GVL_IO`.

### 7.3 Water

Strengths:

- `PRG_Water` reads command layer for valve 35/36 close.
- Uses `FB_Water_Output_Projection`.

Critical upstream issue:

- Command arbitration does not currently implement `WATER_LEAK` branch, so close valve commands may not be issued during leak mode.

Critical downstream issue:

- IO write does not currently map `GVL_WATER_OUTPUT` to `GVL_IO`.

### 7.4 Access

Strengths:

- `PRG_Access` is clean projection from `GVL_COMMAND_SHADOW`.

Critical upstream issue:

- Command arbitration currently does not pass user access requests and does not implement evacuation unlock branch.

Critical downstream issue:

- IO write does not currently map `GVL_ACCESS_OUTPUT` to `GVL_IO`.

---

## 8. Scenario / Behavior / Adapt Audit

### 8.1 Scenario Engine

Strengths:

- Multi-scenario intent exists.
- VentBoost is zone-aware.
- Uses global and zone weights plus confidence.
- Writes trace.

Risks:

- `L_BestVentZone` is calculated but not published to `GVL_INTENT_BEHAVIOR` or `GVL_DEBUG_VIEW` directly.
- `I_Selected_Scenario_Code` and `I_Reason_Code` are not updated in current `PRG_Scenario_Engine`; only `I_Reason_Text` is updated.
- `PRG_Scenario_Engine` reads `GVL_STATE.G_Preheat_Request` and `GVL_STATE.G_Room_Hum` directly instead of `GVL_INPUT`.

### 8.2 Behavior Intent GVL

Strengths:

- Rich intent contract exists: request flags, scores, reason text, selected scenario fields.

Risk:

- Some fields are now stale/not actively maintained:
  - `I_Selected_Scenario_Code`
  - `I_Reason_Code`
  - `I_Behavior_Priority`
  - `I_Request_Preheat`
  - `I_Request_Energy_Save_Mode`
  - `I_Request_Away_Mode`

### 8.3 Adaptive feedback

Strengths:

- Global stats exist.
- Zone-level VentBoost adapt exists.
- Confidence learning exists.
- Decay exists.
- Profiles exist.

Risks:

- `PRG_System_Diagnostics` uses `L_PrevHum : REAL := 70.0` as static baseline; it does not store actual previous humidity per zone.
- `Diagnostics` runs before `Scenario_Engine`, so it reacts to previous-cycle intent.
- `FB_Behavior_Adapt` only applies zone adaptation for VentBoost; global stats for other scenarios are recorded, but weight updates for global scenario weights were removed in final decay rewrite.

---

## 9. Trace / Debug / Explainability Audit

### 9.1 Trace

Strengths:

- Ring buffer exists.
- `TRACE_USER` now exists.
- `FB_Trace_Write` can log user/scenario/command/io events.

Risks:

- Trace currently logs coarse events only.
- There is no structured actor/user id, only access level in `iValueReal` for profile change.

### 9.2 Debug View

Strengths:

- Aggregates safety, recovery, behavior, command, explainability, adaptation, trace last event.
- Exposes `D_Adapt_Profile` and `D_Adapt_Profile_Text`.

Risks:

- Debug view shows highest `Zone_Weight`, not necessarily current best VentBoost decision zone. If confidence/humidity changes, main debug zone may not match actual scenario max score.

### 9.3 Explainability

Strengths:

- Global reason and domain texts exist.

Risks:

- Texts are generic and do not distinguish exact origin:
  - safety vs recovery vs behavior vs user.
- Does not expose rejected user actions except via trace.

---

## 10. Input Layer Audit

Strengths:

- `GVL_INPUT` exists.
- `PRG_Input_Processing` projects `GVL_STATE` into normalized read-model.
- No side effects outside `GVL_INPUT`.

Risks:

- High-level logic still reads `GVL_STATE` directly in several places.
- `GVL_INPUT` is currently a mirror/read-model, not yet the authoritative source for scenario/safety/adapt layers.

---

## 11. Top Critical Fix Order

### P0 — Must fix before claiming clean build

1. Add or replace missing `REASON_SAFETY`.
2. Restore full `PRG_Command_Arbitration` logic and complete reset.
3. Restore full `PRG_IO_Write` mapping from output GVLs to physical `GVL_IO`.

### P1 — Must fix before commissioning

4. Move/adjust adaptive feedback so it is based on current cycle or explicitly documents previous-cycle learning.
5. Replace fixed `L_PrevHum := 70.0` with per-zone previous humidity memory.
6. Route `PRG_Scenario_Engine` to `GVL_INPUT` instead of `GVL_STATE` where possible.
7. Publish best VentBoost zone into intent/debug.

### P2 — Engineering quality

8. Add structured user/source id to trace for HMI profile changes.
9. Extend explainability to exact reason chain.
10. Add a build/compile verification step after each wide rewrite.

---

## 12. Bottom-Up / Top-Down Verdict

### Bottom-up

Physical output layer is currently the weakest point. Domains produce output projections, but `PRG_IO_Write` does not consume most of them.

### Top-down

`MAIN` sequence is structurally good, but command arbitration is currently too narrow to enforce the intended safety/behavior/user policy.

### Left-to-right / right-to-left

- Left-to-right (`Sensors → Input → Safety/Scenario → Command → Domain → IO`): broken at `Command` and `IO`.
- Right-to-left (`IO output → Domain output → Command → Intent/Safety`): many physical outputs have no current write path from their projection GVLs.

---

## 13. Final Status

```text
Architecture concept: strong
Current code integrity: not production-clean
Compile risk: present
Runtime behavior risk: high in command/io paths
Recommended next action: repair P0 items before any further feature work
```

This report is intentionally code-first and does not rely on previous audit documents.
