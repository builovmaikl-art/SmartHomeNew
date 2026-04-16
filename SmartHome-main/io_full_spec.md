# Full IO specification

## Scope
- Full extraction of declared physical IO from the hardware declaration block in `result.txt`.
- Intended for redundancy / overengineering review, not for final cabinet purchasing without a hardware BOM.
- `AI_Boiler_Flame_Status` is listed under **DI** for physical analysis because it is declared as `BOOL` and described as a discrete flame-confirmation signal.
- Owner-reviewed corrections to this raw extraction are tracked separately in `io_reviewed_target_spec.md`.

## DI specification
- Total channels: **111**

| Signal | Channels | Type | Purpose |
|---|---:|---|---|
| `DI_Security_Open` | 15 | `BOOL` | Дискретные входы: Герконы (нормально-замкнутые контакты, TRUE = Открыто) |
| `DI_Security_Glass` | 15 | `BOOL` | Дискретные входы: Датчики разбития стекла (активный уровень - TRUE) |
| `DI_Security_2F_Group` | 1 | `BOOL` | Дискретный вход: Групповой шлейф безопасности 2-го этажа (общий сигнал) |
| `DI_Flood_Sensors` | 12 | `BOOL` | Дискретные входы: Датчики протечки воды (активный уровень - TRUE) |
| `DI_Manifold_End_Switches` | 5 | `BOOL` | Дискретные входы: Концевые выключатели клапанов коллекторов |
| `AI_Boiler_Flame_Status` | 2 | `BOOL` | Дискретные входы: Датчик ионизации (подтверждение наличия пламени) |
| `DI_Boiler_Error` | 2 | `BOOL` | Дискретные входы: Сигнал общей ошибки/аварии котла |
| `DI_Smoke_Sensors` | 6 | `BOOL` | Дискретные входы: Оптические датчики дыма (пожарный шлейф) |
| `DI_Lighting_Switches` | 16 | `BOOL` | Дискретные входы: Физические кнопки/выключатели (импульсные) |
| `DI_Socket_Switches` | 16 | `BOOL` | Дискретные входы: Кнопки управления групповыми розетками по помещениям |
| `DI_Motion_Sensors` | 16 | `BOOL` | Дискретные входы: Датчики присутствия (PIR-сенсоры) |
| `DI_Power_OK` | 1 | `BOOL` | Дискретный вход: Контроль наличия напряжения на вводе (реле контроля фаз) |
| `DI_Partner_Pulse` | 1 | `BOOL` | Дискретный вход: Пульс от второго ПЛК |
| `DI_Partner_Active` | 1 | `BOOL` | Дискретный вход: Статус активности второго ПЛК |
| `DI_Module_1_Heartbeat` | 1 | `BOOL` | Сигнал жизни от модуля 1 |
| `DI_Module_2_Heartbeat` | 1 | `BOOL` | Сигнал жизни от модуля 2 |

## DO specification
- Total channels: **56**

| Signal | Channels | Type | Purpose |
|---|---:|---|---|
| `DO_Manifold_Pumps` | 5 | `BOOL` | Дискретные выходы: Циркуляционные насосы коллекторных узлов (220В) |
| `DO_Boiler_Enable` | 2 | `BOOL` | Дискретные выходы: Сигнал разрешения работы горелки (сухой контакт) |
| `DO_Zone_Valves` | 16 | `BOOL` | Дискретные выходы: Термоэлектрические приводы контуров (220В) |
| `DO_DHW_Heating_Pump` | 1 | `BOOL` | Дискретный выход: Насос загрузки бойлера (первичный контур от котла) |
| `DO_DHW_Circ_Pump` | 1 | `BOOL` | Дискретный выход: Насос рециркуляции ГВС (кольцо потребителей) |
| `DO_Sockets` | 16 | `BOOL` | Дискретные выходы: Управление групповыми розетками по помещениям (реле) |
| `DO_Gas_Valve_Close` | 1 | `BOOL` | Дискретный выход: Импульс на закрытие электромагнитного газового клапана |
| `DO_Water_Valve_35_Close` | 1 | `BOOL` | Дискретный выход: Закрыть вводной шаровый кран воды №1 (с электроприводом) |
| `DO_Water_Valve_36_Close` | 1 | `BOOL` | Дискретный выход: Закрыть вводной шаровый кран воды №2 (с электроприводом) |
| `DO_Gas_Siren` | 1 | `BOOL` | Дискретный выход: Звуковое оповещение при опасной концентрации газа |
| `DO_Fire_Siren` | 1 | `BOOL` | Дискретный выход: Звуковое оповещение при обнаружении задымления |
| `DO_Security_Siren` | 1 | `BOOL` | Дискретный выход: Сирена охранной сигнализации |
| `DO_Pump_Main_Enable` | 1 | `BOOL` | Дискретный выход: Разрешение работы главного циркуляционного насоса системы |
| `DO_Gate_Open` | 1 | `BOOL` | Дискретный выход: Команда на открытие въездных ворот (импульс) |
| `DO_Wicket_Open` | 1 | `BOOL` | Дискретный выход: Команда на разблокировку электрозамка калитки |
| `DO_Lock_1_Open` | 1 | `BOOL` | Дискретный выход: Разблокировать основной электромеханический замок дома |
| `DO_Lock_1_Close` | 1 | `BOOL` | Дискретный выход: Заблокировать основной электромеханический замок дома |
| `DO_Lock_2_Open` | 1 | `BOOL` | Дискретный выход: Разблокировать дополнительный замок (черный ход) |
| `DO_Lock_2_Close` | 1 | `BOOL` | Дискретный выход: Заблокировать дополнительный замок (черный ход) |
| `DO_Heartbeat_Pulse` | 1 | `BOOL` | Дискретный выход: Собственный пульс |
| `DO_Active_Status` | 1 | `BOOL` | Дискретный выход: Собственный статус активности |

## AI specification
- Total channels: **92**

| Signal | Channels | Type | Purpose |
|---|---:|---|---|
| `AI_Manifold_Currents` | 5 | `INT` | Аналоговые входы: Обратная связь по току потребления насосов (диагностика) |
| `AI_Manifold_Pressures` | 5 | `INT` | Аналоговые входы: Давление теплоносителя в коллекторах (0-10 бар) |
| `AI_Manifold_Temps_Supply` | 5 | `ST_Owen_Analog_Value` | Аналоговые входы: Температура подачи (структура со статусом) |
| `AI_Manifold_Temps_Return` | 5 | `INT` | Аналоговые входы: Температура обратной линии (в 10-х долях градуса) |
| `AI_Supply_Temps` | 2 | `ST_Owen_Analog_Value` | Аналоговые входы: Температура приточного воздуха после калорифера |
| `AI_Boiler_Modulation` | 2 | `INT` | Аналоговые входы: Текущий уровень модуляции мощности котла (%) |
| `AI_Methane_LEL` | 2 | `ST_Owen_Analog_Value` | Аналоговые входы: Уровень метана CH4 (0-100% LEL) |
| `AI_CO_PPM` | 8 | `REAL` | Аналоговые входы: Уровень угарного газа CO (PPM) |
| `AI_Temp_Outdoor` | 1 | `ST_Owen_Analog_Value` | Аналоговый вход: Наружная температура воздуха (уличный датчик) |
| `AI_Floor_Temps` | 16 | `REAL` | Аналоговые входы: Температура стяжки пола по зонам (датчики в гильзах) |
| `AI_Room_Temps` | 16 | `REAL` | Аналоговые входы: Температура воздуха в помещениях (настенные датчики) |
| `AI_Room_Hum` | 5 | `REAL` | Аналоговые входы: Влажность в 5 мокрых зонах (%) |
| `AI_Room_CO2` | 16 | `REAL` | Аналоговые входы: Уровень CO2 в помещениях (ppm) |
| `AI_DHW_Temp` | 1 | `REAL` | Аналоговый вход: Температура воды в бойлере косвенного нагрева |
| `AI_DHW_Pressure` | 1 | `REAL` | Аналоговый вход: Давление в контуре ГВС (контроль подпитки и утечек) |
| `AI_Water_Valve_35_Current` | 1 | `REAL` | Аналоговый вход: Ток потребления электропривода крана №1 (контроль заклинивания) |
| `AI_Water_Valve_36_Current` | 1 | `REAL` | Аналоговый вход: Ток потребления электропривода крана №2 (контроль заклинивания) |

## AO specification
- Total channels: **15**

| Signal | Channels | Type | Purpose |
|---|---:|---|---|
| `AO_Manifold_Valves` | 5 | `UINT` | Аналоговые выходы: Приводы клапанов (0-10В, 0-1000 ед. для Modbus) |
| `AO_Supply_Fans` | 3 | `UINT` | Аналоговые выходы: Скорость приточных вентиляторов (0-10В) |
| `AO_Exhaust_Fans` | 5 | `UINT` | Аналоговые выходы: Скорость вытяжных вентиляторов (0-10В) |
| `AO_Boiler_Setpoint` | 2 | `UINT` | Аналоговые выходы: Задание температуры теплоносителя (0-10В) |

## Potentially redundant or optimization candidates

The items below are **review candidates**, not automatic removals:

1. **Full-room CO2 instrumentation (`AI_Room_CO2`, 16 channels)**
   - High diagnostic value, but often excessive for residential projects if demand-controlled ventilation can be based on fewer representative zones.
   - Good candidate for reduction to priority rooms (bedrooms, living room, office, gym).

2. **Full-room air temperature + full-room floor temperature (`AI_Room_Temps` + `AI_Floor_Temps`, 16 + 16 channels)**
   - Technically justified for high-quality floor-heating control, but expensive in aggregate.
   - Candidate for trimming floor probes in low-priority rooms if thermal comfort strategy allows it.

3. **Security per-point + grouped second-floor loop (`DI_Security_Open`, `DI_Security_Glass`, plus `DI_Security_2F_Group`)**
   - The grouped second-floor loop may partially duplicate individual perimeter information.
   - Candidate for removal if all required alarm logic is already covered by point-level sensors.

4. **Per-room socket switching (`DI_Socket_Switches` + `DO_Sockets`, 16 + 16 channels)**
   - After migration to grouped room sockets this is already reduced, but still remains one of the largest discrete-channel consumers.
   - Candidate for further consolidation if some rooms do not need controlled socket groups.

5. **Valve current diagnostics (`AI_Water_Valve_35_Current`, `AI_Water_Valve_36_Current`)**
   - Useful for predictive maintenance, but can be considered premium diagnostics rather than mandatory automation signals.

6. **Boiler status triplet (`AI_Boiler_Modulation`, `AI_Boiler_Flame_Status`, `DI_Boiler_Error`)**
   - Good for deep diagnostics, but some boiler integrations expose overlapping meaning between flame, modulation and fault state.
   - Candidate for protocol-level consolidation if the boiler bus already provides these states.

7. **Module heartbeat DI only for two modules (`DI_Module_1_Heartbeat`, `DI_Module_2_Heartbeat`)**
   - Not redundant; instead it is incomplete relative to the declared overall IO scope and should be expanded if many remote modules remain in the design.

## Recommendation for next review step
- Tag each signal as `mandatory`, `comfort`, `diagnostic`, or `premium-diagnostic` and perform a second-pass value engineering review.
- The strongest reduction potential is typically in CO2, floor probes, valve diagnostics, and any grouped/summary security channels duplicating point sensors.
