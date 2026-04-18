# Snapshot Layer — Phase 1 (Baseline)

## Статус
✅ Стабильно  
✅ Компилируется  
✅ Интегрировано в PRG_System  

---

## Архитектура

### Компоненты
- FB_State_Snapshot_Manager (in-memory ring buffer)
- PRG_System integration (observer layer)

### Trigger
- Rising edge:
  Sensor_Shadow_Rate_Alert_Active (FALSE → TRUE)

---

## Данные snapshot

ST_State_Snapshot:
- timestamp_ms
- operator_id
- scenario_id
- lighting_levels
- floor_heating_setpoints
- alarm_active
- crc32

---

## Ограничения (Phase 1)
- нет debounce
- нет multi-event
- нет persistence (NVRAM / file)
- нет replay

---

## Назначение

- диагностический слой
- фиксация событий системы
- база для future forensic / replay

---

## Следующие этапы

Phase 2:
- multi-event triggers
- event classification

Phase 3:
- persistence (NVRAM / file)

