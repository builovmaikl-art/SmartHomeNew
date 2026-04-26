# 87 — Calibration Mapping Registry

Дата фиксации: 2026-04-24
Последняя синхронизация: 2026-04-24
Режим: documentation + implementation status

## Цель

Формализовать подключение всех сенсоров через единый mapping-подход:

```text
RAW (GVL_IO) → Calibration → State (GVL_STATE) → Diagnostics
```

---

## Итог аудита

```text
CALIBRATION PIPELINE IMPLEMENTED
```

Sensor processing приведён к унифицированной схеме.

---

## Текущая карта (АКТУАЛЬНОЕ СОСТОЯНИЕ)

### 1. Outdoor Temperature

```text
Processing: Calibration FB
Status: IMPLEMENTED
```

---

### 2. Room Temperatures

```text
Processing: Calibration FB
Status: IMPLEMENTED
```

---

### 3. Floor Temperatures

```text
Processing: Calibration FB
Status: IMPLEMENTED
```

---

### 4. Supply Temperatures

```text
Processing: Calibration FB
Status: IMPLEMENTED
```

---

### 5. Room Humidity

```text
Processing: Calibration FB
Status: IMPLEMENTED
```

---

### 6. Room CO2

```text
Processing: Calibration FB
Status: IMPLEMENTED
```

---

### 7. Manifold Pressure

```text
Processing: Analog FB
Status: IMPLEMENTED (by design)
```

---

### 8. Manifold Current

```text
Processing: Analog FB
Status: IMPLEMENTED (by design)
```

---

### 9. Manifold Supply Temp

```text
Processing: Calibration FB
Status: IMPLEMENTED
```

---

### 10. Manifold Return Temp

```text
Processing: Calibration FB
Status: IMPLEMENTED
```

---

### 11. Methane Sensors

```text
Processing: Calibration FB
Status: IMPLEMENTED
```

---

### 12. CO Sensors

```text
Processing: Calibration FB
Status: IMPLEMENTED
```

---

### 13. DHW

```text
Processing: direct
Status: ACCEPTED (no calibration required in current scope)
```

---

## Финальный статус

```text
NO OPEN CALIBRATION DEBT
```

---

## Примечание

Дальнейшие изменения sensor pipeline должны соответствовать этому реестру.

Любые новые сенсоры:

```text
обязательно проходят через calibration mapping
```
