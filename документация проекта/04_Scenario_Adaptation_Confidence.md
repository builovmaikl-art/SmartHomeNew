# 04. Scenario / Adaptation / Confidence

## Scenario Engine

Отвечает за поведенческую логику.

### Цели:
- Комфорт
- Ночной режим
- Вентиляция
- Безопасность доступа

## Формула

```text
Score = Base × Adapt × Confidence
```

## Confidence

```text
Instant × Reputation
```

## Reputation

```text
rep_new = rep_old*(1-α) + conf*α
rep = rep + (1-rep)*decay
```

## Поведение

- Плохой датчик → вес снижается
- Стабильный датчик → вес растёт

## Итог

Scenario использует только GVL_INPUT
