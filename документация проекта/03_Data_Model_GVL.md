# 03. Data Model (GVL)

## Назначение

Документ описывает глобальные переменные (GVL) и их зону ответственности.

## Основные GVL

- GVL_STATE — сырые данные из IO
- GVL_INPUT — нормализованные и валидированные данные
- GVL_COMMAND_SHADOW — финальные команды
- GVL_*_OUTPUT — доменные выходы
- GVL_DEBUG_VIEW — HMI

## Ownership правила

| GVL | Кто пишет |
|-----|----------|
| GVL_STATE | PRG_IO_Read |
| GVL_INPUT | PRG_Input_Processing |
| GVL_COMMAND_SHADOW | PRG_Command_Arbitration |
| GVL_*_OUTPUT | Domain PRG |
| GVL_IO | PRG_IO_Write |

## Поток данных

```text
STATE → INPUT → COMMAND → OUTPUT → IO
```

## Запрещено

- Прямая запись в IO
- Обход COMMAND слоя
- Чтение STATE в Scenario
