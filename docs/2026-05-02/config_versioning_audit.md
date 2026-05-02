# Config Versioning Audit (2026-05-02)

## Найденные проблемы

1. Rollback не восстанавливал данные
2. Отсутствовал snapshot конфигурации
3. Checksum фиктивный
4. Нет freeze системы

## Исправления

1. Добавлен GVL_CONFIG_BACKUP
   - хранит полный snapshot конфигурации

2. Реализован реальный rollback
   - восстановление GVL_CONFIG из backup

3. Добавлен freeze через command layer
   - G_Heating_Block
   - G_Boiler_Stop

4. Rollback стал атомарным
   - копирование всех структур

## Статус

✔ Rollback теперь реальный
✔ Snapshot есть
✔ Система защищена от битого конфига

## Ограничения

- Нет CRC (checksum упрощён)
- Snapshot только в RAM (не persistent)

## Вывод

Узел переведён из "фиктивного" в рабочий.
