# COMMAND ARBITRATION IMPLEMENTATION (REAL LOGIC)

## Цель
Определить конкретную реализацию PRG_Command_Arbitration на уровне ST-кода.

---

## 1. Общий шаблон

Каждая команда формируется строго по приоритету:

```st
// Template
IF Safety_Constraint THEN
    Command := SAFE_VALUE;
ELSIF System_Constraint THEN
    Command := SYSTEM_VALUE;
ELSIF User_Intent THEN
    Command := USER_VALUE;
ELSE
    Command := DEFAULT_VALUE;
END_IF;
```

---

## 2. GAS CONTROL (реальный код)

```st
// GAS CONTROL
IF GVL_INTENT_SAFETY.I_Gas_Close_Required THEN
    GVL_COMMAND.CMD_Gas_Close := TRUE;
    GVL_COMMAND.CMD_Gas_Open := FALSE;

ELSIF GVL_INTENT_SYSTEM.I_Dangerous_Action_Allowed THEN
    GVL_COMMAND.CMD_Gas_Open := GVL_INTENT_USER.I_Gas_Selective_Recover;
    GVL_COMMAND.CMD_Gas_Close := NOT GVL_COMMAND.CMD_Gas_Open;

ELSE
    GVL_COMMAND.CMD_Gas_Close := TRUE;
    GVL_COMMAND.CMD_Gas_Open := FALSE;
END_IF;
```

---

## 3. WATER CONTROL

```st
// WATER MAIN
IF GVL_INTENT_SAFETY.I_Water_Main_Close_Required THEN
    GVL_COMMAND.CMD_Water_Close := TRUE;
    GVL_COMMAND.CMD_Water_Open := FALSE;

ELSIF GVL_INTENT_USER.I_Water_Selective_Recover THEN
    GVL_COMMAND.CMD_Water_Open := TRUE;
    GVL_COMMAND.CMD_Water_Close := FALSE;

ELSE
    GVL_COMMAND.CMD_Water_Close := FALSE;
END_IF;
```

---

## 4. VENTILATION CONTROL

```st
// VENTILATION
IF GVL_INTENT_SAFETY.I_Vent_Stop_Required THEN
    GVL_COMMAND.CMD_Vent_Stop := TRUE;
    GVL_COMMAND.CMD_Vent_Start := FALSE;

ELSE
    GVL_COMMAND.CMD_Vent_Start := TRUE; // from manager later
    GVL_COMMAND.CMD_Vent_Stop := FALSE;
END_IF;
```

---

## 5. LOCK CONTROL (CRITICAL)

```st
// LOCK 1
IF GVL_INTENT_SAFETY.I_Lock_1_Force_Open THEN
    GVL_COMMAND.G_Lock_1_Open := TRUE;
    GVL_COMMAND.G_Lock_1_Close := FALSE;

ELSIF GVL_INTENT_USER.I_Lock_1_Open_Request THEN
    GVL_COMMAND.G_Lock_1_Open := TRUE;
    GVL_COMMAND.G_Lock_1_Close := FALSE;

ELSIF GVL_INTENT_USER.I_Lock_1_Close_Request THEN
    GVL_COMMAND.G_Lock_1_Close := TRUE;
    GVL_COMMAND.G_Lock_1_Open := FALSE;

ELSE
    GVL_COMMAND.G_Lock_1_Open := FALSE;
    GVL_COMMAND.G_Lock_1_Close := FALSE;
END_IF;
```

---

## 6. GATE / WICKET

```st
IF GVL_INTENT_USER.I_Gate_Open_Request AND GVL_INTENT_SYSTEM.I_Access_Open_Allowed THEN
    GVL_COMMAND.G_Gate_Open := TRUE;
ELSE
    GVL_COMMAND.G_Gate_Open := FALSE;
END_IF;
```

---

## 7. FINAL SAFETY GATE (обязательно)

```st
// FINAL SAFETY ENFORCEMENT
IF GVL_INTENT_SAFETY.I_Evacuation_Mode_Active THEN
    GVL_COMMAND.G_Lock_1_Close := FALSE;
    GVL_COMMAND.G_Lock_2_Close := FALSE;
    GVL_COMMAND.G_Lock_1_Open := TRUE;
    GVL_COMMAND.G_Lock_2_Open := TRUE;
END_IF;

IF GVL_INTENT_SAFETY.I_Gas_Close_Required THEN
    GVL_COMMAND.CMD_Gas_Open := FALSE;
END_IF;
```

---

## 8. Ключевые правила

- все команды вычисляются каждый цикл (no latch inside command layer)
- нет сохранения старых значений
- arbitration всегда overwrite

---

## 9. Расположение в pipeline

PRG_Command_Arbitration должен выполняться:

```
IO_Read
→ Safety
→ System
→ Policy
→ PRG_Command_Arbitration
→ Managers
→ IO_Write
```

---

## 10. Критерии корректности

- одинаковый input → одинаковый output
- нет multi-writer
- safety невозможно обойти

---

## 11. Следующий шаг

- внедрение GVL_INTENT_* в код
- постепенное отключение прямых записей в GVL_COMMAND
- повторный аудит
