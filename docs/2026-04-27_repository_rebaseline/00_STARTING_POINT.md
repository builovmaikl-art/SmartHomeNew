# 00 — Repository Rebaseline Starting Point

Дата: 2026-04-27
Назначение: новая отправная точка фиксации фактического состояния репозитория перед продолжением работ

---

## Причина создания новой папки

Текущая работа дошла до состояния, где часть документации описывает более ранний safety/workflow план, а фактический код уже ушёл дальше.

Чтобы не продолжать работу из неоднозначной точки, дальнейшие фиксации выполняются в новой папке:

```text
docs/2026-04-27_repository_rebaseline/
```

Эта папка используется как новая рабочая линия фиксации:

```text
current repository state -> verified observations -> next scoped changes
```

---

## Режим работы

Текущая фиксация выполнена в режиме:

```text
Direct Repository Modification Mode
```

Это означает:

- изменения в документации вносятся напрямую в репозиторий;
- подтверждение выполняется по фактическому состоянию файлов в GitHub;
- это не считается runtime/build подтверждением;
- для runtime-affecting изменений Full Verification Mode остаётся предпочтительным.

---

## Управляющие правила

Перед дальнейшими изменениями сохраняются правила из:

```text
AGENTS.md
docs/MASTER_GUIDE.md
docs/WORKFLOW.md
```

Ключевые правила:

1. Реализованный код в репозитории является фактом текущей реализации.
2. Документация должна быть приведена в соответствие с текущим кодом, если обнаружено расхождение.
3. Safety имеет приоритет над comfort/optimization.
4. Нельзя смешивать verification modes.
5. После каждой правки требуется проверка результата по фактическому состоянию репозитория.

---

## Обязательное правило после правок

После любого изменения в репозитории обязательно выполнить post-change verification.

Минимальная проверка для документационных изменений:

```text
1. Перечитать изменённый файл из репозитория.
2. Убедиться, что файл не обрезан.
3. Убедиться, что вставка попала в правильный path.
4. Убедиться, что содержание соответствует намерению изменения.
5. Указать режим проверки в итоговом сообщении.
```

Для code/runtime-affecting изменений дополнительно требуется:

```text
1. Проверить корректность вставки в изменённых ST/GVL/DUT файлах.
2. Проверить отсутствие обрывов файла и placeholder text.
3. Проверить баланс END_VAR / END_IF / END_FOR / END_CASE по изменённому срезу.
4. Проверить соответствие FB call signatures их объявлениям.
5. Выполнить доступную терминальную или build/smoke проверку, если среда позволяет.
```

Это правило является обязательным для дальнейшей работы в этой папке.

---

## Фактическая отправная точка по safety/workflow

На момент создания этой фиксации уже обнаружено расхождение между ранее зафиксированным safety-plan и текущим кодом.

Факт текущего кода:

```text
FB_Safety_Workflow_Manager.st exists
PRG_Safety.st contains fbSafetyWorkflow instance
PRG_Safety.st calls fbSafetyWorkflow(...)
```

Следствие:

```text
workflow helper extraction already exists in code
```

Это означает, что документы, где выбран только local structural segregation without new helper/POU, должны рассматриваться как более ранняя planning stage, а не как актуальное описание текущего кода.

---

## Фактическая отправная точка по engineering evolution

Документ:

```text
docs/2026-04-26_engineering_evolution/12_branch_migration_tasks.md
```

фиксирует необходимость переноса состояния в чистую ветку и continuation только после repository-state verification.

Для новой рабочей линии это означает:

```text
Before next functional integration, first align documentation with actual repository state.
```

Особенно важно не начинать controlled integration heating policy into decision layer, пока не завершена фиксация фактической точки старта.

---

## Что считается текущей целью новой папки

Цель этой папки:

1. Зафиксировать фактическое состояние репозитория после safety/workflow и engineering-evolution изменений.
2. Отделить реальные факты кода от устаревших planning-документов.
3. Вести дальнейшие фиксации последовательно и проверяемо.
4. Перед каждым следующим шагом явно указывать:
   - что проверено;
   - что изменено;
   - каким режимом подтверждено;
   - какие ограничения остаются.

---

## Что пока не считается подтверждённым

Эта фиксация не подтверждает:

- полную runtime-сборку текущего состояния;
- отсутствие всех возможных компиляционных ошибок;
- корректность поведения на реальном PLC/runtime;
- завершённость safety redesign;
- завершённость heating policy integration.

Эти пункты требуют отдельной Full Verification Mode проверки.

---

## Следующие рекомендуемые документы в этой папке

```text
01_REPOSITORY_STATE_VERIFICATION.md
02_SAFETY_WORKFLOW_REALITY_CHECK.md
03_ENGINEERING_EVOLUTION_MIGRATION_ALIGNMENT.md
```

Рекомендуемый следующий шаг:

```text
01_REPOSITORY_STATE_VERIFICATION.md
```

Его задача:

- пройти checklist текущего репозитория;
- зафиксировать, какие файлы проверены;
- отдельно отметить устаревшие документы и фактические code-state изменения;
- не вносить runtime-affecting изменений до завершения verification pass.

---

## Статус

```text
REBASELINE STARTING POINT RECORDED
CONTINUE FIXATIONS IN docs/2026-04-27_repository_rebaseline/
POST-CHANGE FILE VERIFICATION REQUIRED AFTER EVERY REPO EDIT
```