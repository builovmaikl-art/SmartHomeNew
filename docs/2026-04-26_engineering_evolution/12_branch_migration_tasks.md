# 12 — Branch Migration Tasks

Дата: 2026-04-26
Назначение: перенос текущего engineering-evolution состояния в новую чистую ветку

---

## Причина

Текущая ветка содержит большой объём последовательных изменений:

- System Coordinator
- Mode System
- Presence layer
- Multi-zone presence
- Heating Policy observe layer
- документация engineering evolution

Перед дальнейшим подключением heating policy к decision layer нужно стабилизировать состояние в новой ветке.

---

## Статус текущей работы

### Завершено

- Coordinator создан и подключён через `MAIN.st`
- Coordinator уже ограничивает Heating / Ventilation / Lighting / Sockets через существующие allow/override слои
- Behavior Mode создан и подключён к Coordinator
- Presence layer создан и подключён к Mode
- Multi-zone presence создан
- Heating Policy observe layer создан
- правило permanent-use помещений зафиксировано
- правило AWAY override для permanent-use принято

### Не завершено

- controlled integration heating policy в `PRG_Heating.st`
- применение `G_Zone_Target_Adjustment[]`
- применение `G_Zone_Priority_Bias[]`
- guest preheat как реальное влияние на heating decision
- пакетная runtime-проверка

---

## Файлы, которые нужно перенести в новую ветку

### Documentation

Перенести полностью:

```text
docs/2026-04-26_engineering_evolution/
```

Ключевые документы:

```text
01_architecture.md
02_coordinator_design.md
03_integration_plan.md
04_results.md
05_mode_system_architecture.md
06_mode_transitions.md
07_presence_layer.md
08_presence_hysteresis.md
09_multi_zone_presence.md
10_presence_aware_heating_policy.md
11_heating_policy_observe.md
12_branch_migration_tasks.md
```

---

## Code files to migrate

### Coordinator

```text
GVL_SYSTEM_COORDINATION.gvl
FB_System_Coordinator.st
PRG_System_Coordinator.st
```

### Mode

```text
E_Behavior_Mode.dut
GVL_MODE.gvl
FB_Mode_Manager.st
PRG_Mode_Manager.st
```

### Presence

```text
GVL_PRESENCE.gvl
FB_Presence_Manager.st
PRG_Presence_Manager.st
```

### Heating Policy Observe

```text
GVL_HEATING_POLICY.gvl
FB_Heating_Policy_Observer.st
PRG_Heating_Policy_Observer.st
```

### Domain files already touched

```text
MAIN.st
PRG_Heating.st
PRG_Ventilation.st
PRG_Lighting.st
```

---

## Expected MAIN order

```text
PRG_IO_Read();
PRG_Safety();
PRG_System();
PRG_Presence_Manager();
PRG_Heating_Policy_Observer();
PRG_Mode_Manager();
PRG_System_Coordinator();
PRG_Policy();
PRG_Command_Arbitration();
PRG_Command_Verifier();
PRG_Security();
PRG_Heating();
PRG_Ventilation();
PRG_Lighting();
PRG_IO_Write();
```

---

## Rules that must be preserved

### Safety ownership

```text
PRG_Safety remains the owner of safety-stop behavior.
Coordinator does not replace Safety.
```

### Coordinator role

```text
Coordinator publishes constraints only.
Coordinator does not directly write actuator state.
```

### Presence role

```text
Presence does not directly control heating, lighting, ventilation or sockets.
Presence publishes occupancy data only.
```

### Heating Policy role

```text
Heating Policy Observe calculates policy class, target adjustment and priority bias.
It must not directly write pumps, valves or heating outputs.
```

---

## Permanent-use room rule

Some zones may be marked as permanent-use zones.

```text
G_Zone_Permanent_Use[i] = TRUE
```

Normal behavior:

```text
HOME/NIGHT + permanent-use empty zone -> mild eco class
```

AWAY behavior:

```text
AWAY + permanent-use empty zone -> permanent-use exception is ignored
```

Guest preheat remains higher priority than AWAY.

---

## Next task after migration

Continue only after repository-state verification.

Task:

```text
Controlled integration of heating policy into decision layer
```

Recommended safe direction:

```text
1. Do not modify PRG_IO_Read.
2. Do not directly control pumps or valves from policy.
3. In PRG_Heating, build local adjusted priority data.
4. Use GVL_HEATING_POLICY.G_Zone_Priority_Bias[] only as bias.
5. Use GVL_HEATING_POLICY.G_Zone_Target_Adjustment[] only after separate target-policy design.
6. Map zone policy to manifold using GVL_CONFIG.G_HMI_FloorHeating_Configs[].manifold_id.
7. Prefer local arrays in PRG_Heating before changing FB_Heating_Decision_Context signature.
```

---

## Verification checklist in new branch

Check these files before continuing:

```text
MAIN.st
PRG_Heating.st
PRG_Ventilation.st
PRG_Lighting.st
FB_System_Coordinator.st
PRG_System_Coordinator.st
FB_Mode_Manager.st
PRG_Mode_Manager.st
FB_Presence_Manager.st
PRG_Presence_Manager.st
FB_Heating_Policy_Observer.st
PRG_Heating_Policy_Observer.st
GVL_SYSTEM_COORDINATION.gvl
GVL_MODE.gvl
GVL_PRESENCE.gvl
GVL_HEATING_POLICY.gvl
E_Behavior_Mode.dut
```

Required checks:

```text
- no truncated files
- no placeholder text
- no missing END_VAR / END_IF / END_FOR / END_CASE
- FB call signatures match their declarations
- PRG_Heating contains no partial heating-policy integration
- PRG_IO_Read was not modified by this evolution wave
```

---

## Runtime validation package after migration

Run as one package:

```text
1. Normal mode
2. Night mode
3. Away mode
4. Maintenance mode
5. Presence auto-away
6. Presence return from away
7. Coordinator heating block
8. Coordinator ventilation block
9. Lighting override block
10. Socket override block
11. Gas/safety priority over behavior mode
12. IO degraded priority over behavior mode
```

---

## Final status

```text
MIGRATION TASK LIST RECORDED
CONTINUE IN CLEAN BRANCH
```