# 02. Safety Pipeline

## Назначение

Safety слой отвечает за детекцию опасных состояний и генерацию обязательных команд безопасности.

## Приоритеты

```text
FIRE > GAS > WATER_LEAK > GLOBAL_STOP > NORMAL
```

## Pipeline

```text
INPUT → PRG_Safety → PRG_Safety_Shutdown → PRG_Command_Arbitration
```

## Гарантии

- Safety команды не могут быть переопределены.
- Command layer всегда повторно применяет safety блокировки.
- User intent не может нарушить safety.

## Fail-safe

### PLC inactive

```text
Gas close
Boiler stop
Heating block
Vent stop
Water block
```

### Input degraded

```text
GLOBAL_STOP
```

## Evacuation режим

```text
Locks → OPEN
Gate/Wicket → OPEN
Close → BLOCKED
```

## Recovery

Recovery работает через отдельный state-machine и требует подтверждения оператора.
