# 87 — Calibration Mapping Registry

Дата фиксации: 2026-04-24
Режим: documentation only
Runtime-код: не изменялся

## Цель

Формализовать подключение всех сенсоров через единый mapping-подход:

```text
RAW (GVL_IO) → Calibration → State (GVL_STATE) → Diagnostics
```

---

## Проблема

На текущий момент сенсоры подключены неравномерно:

- часть через calibration FB
- часть напрямую
- часть через analog processing
- часть ранее отсутствовала в runtime

Это создаёт риск:

- разной точности
- несогласованной фильтрации
- пропущенных ошибок

---

## Структура реестра

Для каждой группы сенсоров фиксируется:

```text
Sensor Group
Raw Source (GVL_IO)
Processing Type (direct / calibration / analog FB)
Calibration Record (GVL_CONFIG)
State Target (GVL_STATE)
Diagnostics Path
```

---

## Текущая карта

### 1. Outdoor Temperature

```text
Raw: AI_Temp_Outdoor.rValue
Processing: Calibration FB
State: G_Outdoor_Temp
```

---

### 2. Room Temperatures

```text
Raw: AI_Room_Temps[]
Processing: Calibration FB
State: G_Room_Temps[]
```

---

### 3. Floor Temperatures

```text
Raw: AI_Floor_Temps[]
Processing: Calibration FB
State: G_Floor_Temps[]
```

---

### 4. Supply Temperatures

```text
Raw: AI_Supply_Temps[]
Processing: direct (status checked)
State: G_Supply_Temps[]
```

⚠️ кандидат на calibration

---

### 5. Room Humidity

```text
Raw: AI_Room_Hum[]
Processing: direct
State: G_Room_Hum[]
```

⚠️ кандидат на calibration

---

### 6. Room CO2

```text
Raw: AI_Room_CO2[]
Processing: direct
State: G_Room_CO2[]
```

⚠️ кандидат на calibration

---

### 7. Manifold Pressure

```text
Raw: AI_Manifold_Pressures[]
Processing: Analog FB
State: G_Manifold_Pressures[]
Diagnostics: YES
```

---

### 8. Manifold Current

```text
Raw: AI_Manifold_Currents[]
Processing: Analog FB
State: G_Manifold_Currents[]
Diagnostics: YES
```

---

### 9. Manifold Supply Temp

```text
Raw: AI_Manifold_Temps_Supply[]
Processing: direct (status checked)
State: G_Manifold_T_Supply[]
```

⚠️ кандидат на calibration

---

### 10. Manifold Return Temp

```text
Raw: AI_Manifold_Temps_Return[]
Processing: scaled INT→REAL
State: G_Manifold_T_Return[]
```

⚠️ кандидат на calibration

---

### 11. Methane Sensors

```text
Raw: AI_Methane_LEL[]
Processing: direct (status checked)
State: G_Methane_Sensors[]
```

⚠️ кандидат на calibration

---

### 12. CO Sensors

```text
Raw: AI_CO_PPM[]
Processing: direct
State: G_CO_Sensors[]
```

⚠️ кандидат на calibration

---

### 13. DHW

```text
Raw: AI_DHW_Temp / AI_DHW_Pressure
Processing: direct
State: G_DHW_Temp / G_DHW_Pressure
```

⚠️ кандидат на calibration

---

## Классификация

```text
A — уже корректно через FB
B — допустимо напрямую
C — требует унификации (calibration)
```

---

## Рекомендация

Следующий этап:

```text
Wave IO.Calib.1 — унификация sensor processing
```

Но:

```text
НЕ внедрять сразу массово
сначала выбрать 1–2 группы
```

---

## Статус

P1 долг формализован
система стабилизирована
готово к постепенному улучшению
