# 🚀 PROJECT ROADMAP
**Project:** SmartHomeNew
**Baseline Date:** 2026-04-06

---

# 1. PRINCIPLES (MANDATORY)

1. Не ломаем runtime
2. Любые изменения — через shadow + comparison
3. Нет прямой записи в GVL из нового ядра
4. Только Active PLC влияет на систему
5. Любая новая логика сначала как observer

---

# 2. CURRENT STAGE

```
STAGE: VALIDATION
```

Цель:
- доказать что CoreKernel = Legacy

---

# 3. STAGE PLAN

## STAGE 1 — VALIDATION (текущий)

### Цель
Полное совпадение shadow и legacy

### Шаги
- [ ] Проверить VO_Diff_Found
- [ ] Найти и устранить расхождения
- [ ] Зафиксировать стабильный 0 diff

### Критерий завершения
```
VO_Diff_Found = 0 стабильно
```

---

## STAGE 2 — COVERAGE EXPANSION

### Цель
Перенос логики в CoreKernel

### Области
- [ ] System_Mode
- [ ] Alarm
- [ ] DHW
- [ ] Ventilation
- [ ] Safety

### Правило
Каждый блок:
```
Legacy → Shadow → Comparison → Fix → OK
```

---

## STAGE 3 — PARTIAL SWITCH

### Цель
Начать использовать CoreKernel

### Шаги
- [ ] Включить отдельные функции через feature flag
- [ ] Сравнивать в runtime

---

## STAGE 4 — FULL MIGRATION

### Цель
Удаление legacy логики

### Шаги
- [ ] Отключение старых FB
- [ ] Полный переход на CoreKernel

---

## STAGE 5 — OPTIMIZATION

### Цель
Упрощение системы

- [ ] Удаление shadow слоя
- [ ] Удаление comparison

---

# 4. PROGRESS TRACKING

| Stage | Status |
|------|--------|
| Validation | 🔄 |
| Coverage | ⏳ |
| Partial Switch | ⏳ |
| Full Migration | ⏳ |
| Optimization | ⏳ |

---

# 5. RULE OF WORK

Каждое изменение:

1. Добавляется как draft
2. Подключается в shadow
3. Сравнивается
4. Фиксится
5. Только потом в runtime

---

# 6. CRITICAL STOP CONDITIONS

Останавливаемся если:
- diff нестабилен
- поведение не объясняется
- появляются side effects

---

# 7. FINAL GOAL

```
Полностью детерминированная система
без legacy зависимостей
с прозрачной логикой
```

---

**END OF ROADMAP**
