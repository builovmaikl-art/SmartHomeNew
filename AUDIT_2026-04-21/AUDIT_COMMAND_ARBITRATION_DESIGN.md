# COMMAND ARBITRATION DESIGN

## Цель
Ввести детерминированный слой принятия решений, устраняющий multi-writer, race conditions и нарушения безопасности.

---

## 1. Общая архитектура

```
GVL_INTENT_SAFETY
GVL_INTENT_SYSTEM
GVL_INTENT_USER
↓
PRG_Command_Arbitration
↓
GVL_COMMAND (final, write-once)
```

---

## 2. Разделение слоёв

### GVL_INTENT_SAFETY
- только факты и ограничения
- примеры:
  - Gas_Alarm
  - Fire_Alarm
  - Leak_Detected

### GVL_INTENT_SYSTEM
- решения системы
- freeze protection
- degraded mode

### GVL_INTENT_USER
- команды пользователя
- HMI / Gateway

---

## 3. Принцип работы Arbitration

Каждая команда формируется по правилу:

```
IF Safety constraint THEN
    Command := SAFE_STATE
ELSIF System constraint THEN
    Command := SYSTEM_STATE
ELSIF User intent THEN
    Command := USER_REQUEST
ELSE
    Command := DEFAULT
END_IF
```

---

## 4. Приоритеты

1. Safety
2. System
3. Policy
4. User

---

## 5. Примеры

### Газ
```
IF Gas_Alarm THEN
    Gas := CLOSE
ELSE
    Gas := System/User
END_IF
```

### Замки
```
IF Fire THEN
    Lock := OPEN
ELSE
    Lock := Security
END_IF
```

### Вентиляция
```
IF Fire OR Gas THEN
    Vent := STOP
ELSE
    Vent := Manager
END_IF
```

---

## 6. Правила системы

- только PRG_Command_Arbitration пишет в GVL_COMMAND
- все остальные пишут только в GVL_INTENT_*
- IO получает только GVL_COMMAND

---

## 7. Требования

- детерминизм
- отсутствие multi-writer
- безопасность гарантирована

---

## 8. План внедрения

### Шаг 1
Создать GVL_INTENT_* структуры

### Шаг 2
Перенаправить записи из PRG в intent

### Шаг 3
Создать PRG_Command_Arbitration

### Шаг 4
Удалить прямые записи в GVL_COMMAND

### Шаг 5
Добавить final validation перед IO

---

## 9. Критерий завершения

- ни один PRG не пишет в GVL_COMMAND
- все команды проходят через arbitration
- система детерминирована

---

## 10. Риски

- большой объём изменений
- необходимость поэтапной миграции
- необходимость повторного аудита
