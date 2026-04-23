# Progress Log

## 2026-04-23

### Initial entry
Создана dated-папка `docs/2026-04-23_project_audit_plan/` для фиксации актуального цикла анализа.

#### Зафиксировано
- Анализ ведется по живому корню репозитория.
- `snapshots/`, `archive/`, `workspace/` и старые `AUDIT_*` не считаются источником истины.
- Часть старых audit-выводов уже устарела относительно текущего `MAIN.st`.

#### Первичные подтвержденные рабочие темы
1. Проверка статуса корневого `PRG_Heating.st`.
2. Разбор command-layer migration (`GVL_COMMAND` / `GVL_COMMAND_SHADOW` / arbitration / verifier).
3. Проверка interface mismatch в `PRG_Security` -> `FB_Access_Control`.
4. Очистка расхождений между live root и вспомогательными dependency/audit материалами.

#### Следующий рекомендуемый документ
- отдельный heating audit внутри этой же папки.

#### Формат следующих записей
Для каждой следующей записи фиксировать:
- что именно было проанализировано,
- какие выводы подтверждены по live root,
- какие выводы отвергнуты как устаревшие,
- какой следующий шаг выбран.

---

### Heating cluster audit
Проанализированы:
- `MAIN.st`
- `PRG_Heating.st`
- `FB_Heating_System_Manager.st`
- `FB_DHW_Manager.st`
- `docs/systems/heating.md`

#### Подтверждено по live root
- `PRG_Heating` реально подключен в `MAIN.st` как живой program layer.
- `PRG_Heating.st` в текущем корне хранится как сокращенный текстовый фрагмент с вставками `omitted for brevity` и `rest unchanged`.
- `FB_Heating_System_Manager.st` выглядит как полноценный доменный рабочий блок.
- `FB_DHW_Manager.st` выглядит как полноценный policy-driven блок.
- Концептуальная heating documentation согласована с целевым policy-driven направлением.

#### Выводы, которые пока не утверждаются
- Нельзя утверждать, что вся heating logic сломана целиком.
- Нельзя безопасно переходить к точечному heating refactoring, пока не подтвержден или не восстановлен целостный источник `PRG_Heating.st`.

#### Выбранный следующий шаг
- оформить remediation plan для heating cluster,
- после этого решать вопрос восстановления целостного `PRG_Heating.st` как первого технического действия.

---

### Heating remediation plan
Оформлен документ `05_HEATING_REMEDIATION_PLAN.md`.

#### Зафиксировано
- до восстановления целостного `PRG_Heating.st` запрещено считать heating cluster готовым к точечному функциональному рефакторингу;
- следующим техническим этапом должны стать H-R1/H-R2:
  - подтверждение статуса текущего `PRG_Heating.st`,
  - поиск и выбор основного кандидата на восстановление полного heating wrapper.

#### Выбранный следующий шаг
- перейти к поиску и подтверждению основного кандидата на восстановление полного `PRG_Heating.st` с фиксацией происхождения кандидата.

---

### Heating source recovery audit
Оформлен документ `06_HEATING_SOURCE_RECOVERY_AUDIT.md`.

#### Подтверждено
- `snapshots/2026-04-23/PRG_Heating.st` повторяет тот же сокращенный placeholder-like дефект, что и текущий live root, и исключен как источник восстановления;
- `snapshots/project_clean_state_2026_04_16/PRG_Heating.st` является полным, но более старым резервным кандидатом;
- `snapshots/2026-04-22/PRG_Heating.st` выбран как основной кандидат на восстановление, потому что он полный и лучше согласуется с текущими heating request / preheat / target temperature связями живого корня.

#### Выбранный следующий шаг
- перейти к H-R3 и оформить compatibility check для основного кандидата перед любым восстановлением файла в корень.

---

### Heating recovery compatibility check
Оформлен документ `07_HEATING_RECOVERY_COMPATIBILITY_CHECK.md`.

#### Подтверждено
- основной кандидат совместим с текущим live root не буквально, а как recovery candidate с ограниченным адаптационным слоем;
- по `MAIN.st`, `FB_Heating_System_Manager.st` и `FB_DHW_Manager.st` кандидат остается близким к текущей архитектуре;
- главный compatibility-риск сосредоточен в ownership heating request layer: кандидат использует `GVL_HEATING_REQUEST`, тогда как текущий live root уже использует heating-request публикации через `GVL_STATE`.

#### Выбранный следующий шаг
- оформить `08_HEATING_RECOVERY_CHANGESET_PLAN.md` и зафиксировать минимальный recovery changeset до фактического восстановления `PRG_Heating.st`.

---

### Heating recovery changeset plan
Оформлен документ `08_HEATING_RECOVERY_CHANGESET_PLAN.md`.

#### Подтверждено
- минимальный recovery changeset должен быть ограничен восстановлением полного `PRG_Heating.st` и минимальными адаптациями owner-слоя heating requests;
- `GVL_STATE` зафиксирован как текущий live-root owner-слой для `Preheat / Freeze / Target Temperature` в рамках recovery-предположения;
- возврат к `GVL_HEATING_REQUEST` как к основному owner-слою в рамках этого этапа считается уже не recovery, а redesign.

#### Выбранный следующий шаг
- оформить `09_HEATING_RECOVERY_EXECUTION_PLAN.md` с точным порядком внесения recovery-изменений в репозиторий.

---

### Heating recovery execution plan
Оформлен документ `09_HEATING_RECOVERY_EXECUTION_PLAN.md`.

#### Подтверждено
- execution plan ограничен восстановлением полного `PRG_Heating.st` и не включает redesign heating cluster;
- recovery должен выполняться на базе `snapshots/2026-04-22/PRG_Heating.st` с минимальной owner-layer adaptation;
- `MAIN.st`, интерфейсы heating/DHW FB и intent-based reset path должны остаться без архитектурного отката.

#### Выбранный следующий шаг
- перейти от planning-документов к фактическому выполнению recovery-изменения в корневом `PRG_Heating.st`, а затем зафиксировать результат в `10_HEATING_RECOVERY_RESULT.md`.

---

### Heating recovery execution result
Выполнено recovery-изменение корневого `PRG_Heating.st`.

#### Подтверждено по состоянию репозитория
- корневой `PRG_Heating.st` восстановлен как полный непрерывный source-файл;
- placeholder-вставки `omitted for brevity` / `rest unchanged` удалены из live root;
- `VI_Preheat_Request` адаптирован к current-live owner-слою через `GVL_STATE.G_Preheat_Request`;
- intent-based `VI_Reset_Errors := GVL_INTENT_USER.I_Reset_Errors` сохранен;
- `MAIN.st` и интерфейсы heating/DHW FB не изменялись.

#### Выбранный следующий шаг
- зафиксировать post-recovery ownership audit heating wrapper в отдельном документе `11_HEATING_POST_RECOVERY_OWNERSHIP_AUDIT.md`.

---

### Heating post-recovery ownership audit
Оформлен документ `11_HEATING_POST_RECOVERY_OWNERSHIP_AUDIT.md`.

#### Подтверждено
- после recovery heating wrapper снова стал прозрачным для ownership-разбора;
- heating request layer приходит сверху через `GVL_STATE`, без rollback ownership в `GVL_HEATING_REQUEST` как current-live owner;
- `PRG_Heating` остается крупным writer-узлом для `GVL_STATE` и `GVL_STATUS`, особенно в части target temperature, diagnostics и maintenance gating;
- это допустимо как post-recovery состояние, но не является финально очищенным ownership-состоянием.

#### Выбранный следующий шаг
- оформить `12_HEATING_OWNERSHIP_CLEANUP_PLAN.md` и разложить, что именно выносить из `PRG_Heating` на следующем cleanup-этапе.

---

### Heating ownership cleanup plan
Оформлен документ `12_HEATING_OWNERSHIP_CLEANUP_PLAN.md`.

#### Подтверждено
- следующим cleanup-этапом должны стать не новые recovery-работы, а архитектурная развязка ownership внутри heating cluster;
- первым приоритетом cleanup признан вопрос owner для `GVL_STATE.G_Target_Temperature`;
- вторым приоритетом признано разделение orchestration и diagnostics/maintenance gating внутри `PRG_Heating`;
- DHW пока не предлагается автоматически выносить из wrapper без отдельного contract-решения.

#### Выбранный следующий шаг
- оформить `13_HEATING_TARGET_OWNERSHIP_DECISION.md` и принять явное решение по owner для `G_Target_Temperature`.

---

### Heating target ownership decision
Оформлен документ `13_HEATING_TARGET_OWNERSHIP_DECISION.md`.

#### Подтверждено
- coarse heating intents остаются в ownership у `PRG_Policy` через `GVL_STATE.G_Preheat_Request` и `GVL_STATE.G_Freeze_Request`;
- derived heating target `GVL_STATE.G_Target_Temperature` закреплен за `PRG_Heating` как за owner-слоем domain-specific arbitration/stabilization;
- вынос owner для `G_Target_Temperature` в `PRG_Policy` на текущем этапе признан premature redesign, а не локальным cleanup.

#### Выбранный следующий шаг
- оформить `14_HEATING_DIAGNOSTICS_GATING_CLEANUP_PLAN.md` и перейти к следующему ownership-cleanup кластеру.