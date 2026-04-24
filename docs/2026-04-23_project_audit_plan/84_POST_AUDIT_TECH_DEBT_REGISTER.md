# 84 — Post-audit Technical Debt Register

Дата фиксации: 2026-04-24
Режим: audit/debt register only
Scope: runtime-код не изменялся

## Контекст

По итогам восстановления и аудита цепочек IO / Diagnostics / Heating были выявлены места, которые не являются немедленными runtime-багами, но требуют отдельной фиксации как технический долг и зоны усиления.

Цель этого документа — зафиксировать долги до следующей волны изменений, чтобы не продолжать развитие системы поверх неформализованных рисков.

---

## P0 — Protected core file policy для `PRG_IO_Read.st`

### Наблюдение

`PRG_IO_Read.st` несколько раз был повреждён частичными update/merge-операциями:

- терялись блоки чтения IO;
- появлялись заглушки вида `...`;
- реальные runtime-связи заменялись сокращёнными шаблонами;
- после восстановления возникали ошибки из-за несверенных сигнатур FB.

### Риск

`PRG_IO_Read.st` является producer-ядром для многих downstream-подсистем:

- heating;
- safety;
- diagnostics;
- DHW;
- gas/flood/smoke;
- ventilation-related state.

Любая неполная замена файла может сделать систему логически рабочей на верхнем уровне, но недостоверной по входным данным.

### Решение

Ввести правило:

> `PRG_IO_Read.st` нельзя править сокращёнными шаблонами, частичными переписываниями или “same code omitted”.

Разрешённые режимы изменения:

1. full-file merge с последующим чтением файла;
2. минимальный diff с проверкой затронутого участка;
3. обязательная сверка producer-chain `GVL_IO -> PRG_IO_Read -> GVL_STATE`.

### Статус

Зафиксировать как постоянное правило сопровождения.

---

## P1 — `PRG_Safety.st`: cleanup Cluster 2

### Наблюдение

Предыдущая segmentation safety producer ownership выделила 4 ownership-cluster в `PRG_Safety.st`:

1. core hazard / interlock projection;
2. operator / test / recover workflow;
3. safety-access coupling;
4. producer-heavier publication tail.

Практический вывод сегментации: первый minimal cleanup target — Cluster 2, operator/test/recover workflow.

### Почему это важно

Core hazard/interlock projection выглядит естественным ядром safety producer-role. А operator/test/recover workflow выглядит более подходящим кандидатом для отделения или хотя бы структурного упрощения.

### Риск

Если продолжать расширять `PRG_Safety.st` без сегментации, файл станет смешивать:

- safety producer logic;
- operator workflow;
- test/recovery orchestration;
- access coupling;
- publication side-effects.

### Решение

Следующий cleanup по safety должен начинаться не с core hazard, а с Cluster 2.

### Статус

Debt зафиксирован. Runtime-код не трогать до отдельной задачи.

---

## P1 — Energy Management Wave 4.x extraction candidate

### Наблюдение

В `PRG_Heating.st` внедрены слои:

- Wave 4.1 — count limit;
- Wave 4.2 — thermal budget;
- Wave 4.3 — time slicing;
- Wave 4.4 — proportional duty cycle;
- Wave 4.5 — load-aware balancing.

Функционально логика полезна, но плотность `PRG_Heating.st` выросла.

### Риск

Дальнейшее развитие energy-management внутри `PRG_Heating.st` приведёт к смешению:

- heating orchestration;
- energy arbitration;
- thermal load estimation;
- duty-cycle scheduling;
- degradation policy.

### Решение

Следующий этап energy-management должен рассматриваться как кандидат на вынос в отдельный FB, например:

- `FB_Heating_Energy_Manager`;
- `FB_Manifold_Load_Balancer`;
- `FB_Thermal_Budget_Controller`.

### Статус

Не рефакторить немедленно. Зафиксировать как архитектурный долг перед следующими волнами.

---

## P1 — Calibration mapping registry

### Наблюдение

Калибровочная инфраструктура присутствует в `GVL_CONFIG`, но подключение сенсоров должно быть формализовано.

Нужна явная таблица:

```text
sensor group -> raw source -> calibration record -> state target -> fault/diagnostic path
```

### Риск

Без такой таблицы новые sensor groups могут подключаться непоследовательно:

- часть через calibration;
- часть напрямую;
- часть через analog FB;
- часть вообще только как declaration в `GVL_STATE`.

### Решение

Создать отдельный документ calibration map перед следующими расширениями sensor pipeline.

### Статус

Debt зафиксирован.

---

## P2 — Diagnostics severity/code model

### Наблюдение

Pressure/current correlation добавлена, но диагностический смысл пока выражается через BOOL-флаги и текстовые поля.

### Риск

Строки удобны для HMI, но неудобны для системной логики:

- нет устойчивого enum-кода причины;
- сложнее агрегировать severity;
- сложнее строить реакцию системы без string matching.

### Решение

Ввести слой diagnostic classification:

- code;
- severity;
- source subsystem;
- first affected index;
- human-readable text.

### Статус

Не срочно. Подготовить после стабилизации IO и Safety cleanup.

---

## P2 — Safety bootstrap ownership review

### Наблюдение

В `PRG_IO_Read.st` присутствуют bootstrap/reset присвоения safety-related полей, например safety alarm defaults.

### Риск

IO producer может начать владеть safety-state, хотя safety-state должен принадлежать safety producer.

### Решение

Проверить ownership:

- какие safety fields должны только читаться из IO;
- какие должны публиковаться исключительно `PRG_Safety.st`;
- какие bootstrap defaults допустимы только как временный compatibility layer.

### Статус

Audit-candidate. Не менять без отдельного ownership review.

---

## Итоговый приоритет

```text
P0  PRG_IO_Read protected core policy
P1  PRG_Safety Cluster 2 cleanup
P1  Energy Management extraction candidate
P1  Calibration mapping registry
P2  Diagnostics severity/code model
P2  Safety bootstrap ownership review
```

## Рекомендуемый следующий документ

`85_CALIBRATION_MAPPING_REGISTRY.md`

или, если идти по safety:

`85_SAFETY_CLUSTER_2_CLEANUP_PLAN.md`
