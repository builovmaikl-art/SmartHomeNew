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