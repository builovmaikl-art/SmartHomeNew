# SAFETY → GVL_INTENT_SAFETY MIGRATION PLAN

## Текущее состояние
Миграция `PRG_Safety -> GVL_INTENT_SAFETY` начинается после ввода новых intent-слоёв.

## Важное замечание
Текущий `PRG_Safety.st` в репозитории должен использоваться как источник только после проверки его полноты. Перед фактической механической миграцией нужен полный body файла без укороченных маркеров и без потери участков логики.

---

## Цель миграции
Убрать из `PRG_Safety` прямые записи в `GVL_COMMAND` и заменить их публикацией safety-intent в `GVL_INTENT_SAFETY`.

---

## Что должно публиковаться в GVL_INTENT_SAFETY

### Gas / boiler / ventilation
- `I_Gas_Close_Required`
- `I_Boiler_Stop_Required`
- `I_Vent_Stop_Required`
- `I_Vent_Force_PV3_Boost`
- `I_Vent_Force_Supply_100`
- `I_Vent_Force_Supply_80`
- `I_Vent_Force_Exhaust_100`

### Water
- `I_Water_Main_Close_Required`
- `I_Water_Zone_Close_Required[*]`
- `I_Water_Selective_Recovery_Allowed`
- `I_Water_Recovery_Target_Zone`

### Locks / evacuation
- `I_Lock_1_Force_Open`
- `I_Lock_1_Force_Close_Block`
- `I_Lock_2_Force_Open`
- `I_Lock_2_Force_Close_Block`
- `I_Evacuation_Mode_Active`

### Safety facts
- `I_Fire_Alarm_Active`
- `I_Gas_Alarm_Active`
- `I_Leak_Alarm_Active`
- `I_CO_Warning_Active`
- `I_System_Safe_Stop_Required`
- `I_Freeze_Protection_Required`

---

## Обязательный pattern inside PRG_Safety

### 1. Reset per cycle
В начале публикации каждый цикл intent fields должны сбрасываться в safe defaults.

### 2. Publish constraints
`PRG_Safety` публикует only facts / required / force / block.

### 3. No final commands
`PRG_Safety` не пишет в `GVL_COMMAND`.

---

## Migration order inside PRG_Safety

### Stage A
Заменить прямые writes:
- gas close
- boiler stop
- vent stop / force
- lock open / close block
- water main close

### Stage B
Перенести safety facts и traceability meta fields

### Stage C
Оставить временно test/recovery user edges как consumers of input layer до отдельной миграции `GVL_COMMAND -> GVL_INTENT_USER`

---

## Expected post-condition
- `PRG_Safety` больше не владеет final command layer
- `PRG_Safety` владеет только safety intent publication
- следующий шаг: включение `PRG_Command_Arbitration`
