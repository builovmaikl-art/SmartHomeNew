# Heating Target Ownership Decision

Дата фиксации: 2026-04-23

## Вопрос
Кто должен быть owner для:
- `GVL_STATE.G_Target_Temperature`

после recovery и на этапе ownership cleanup?

## Проверенные факты
1. В текущем live root `PRG_Policy.st` публикует в heating bridge только coarse heating intents:
   - `GVL_STATE.G_Preheat_Request`
   - `GVL_STATE.G_Freeze_Request`
2. В текущем live root `PRG_Heating.st` выполняет локальный arbitration/stabilization слой через `L_Last_Mode` и пишет итоговое значение в:
   - `GVL_STATE.G_Target_Temperature`
3. По текущему поиску в живом корне `G_Target_Temperature` не участвует как отдельный распределенный owner-layer во множестве мест, а фактически связан прежде всего с `PRG_Heating` и декларацией в `GVL_STATE`.

## Решение
На текущем этапе owner для `GVL_STATE.G_Target_Temperature` **формально закрепляется за `PRG_Heating`**.

## Почему принято именно такое решение

### D-01. `PRG_Policy` должен оставаться owner coarse intent, а не heating-domain stabilization
`PRG_Policy` уже владеет грубыми намерениями:
- preheat request,
- freeze request.

Но текущее формирование итоговой target temperature в `PRG_Heating` включает heating-domain semantics:
- локальную стабилизацию через `L_Mode_Hold_Timer`,
- переходы между normal / preheat / freeze,
- derived target arbitration.

Это уже не просто policy intent, а доменная heating-логика.

Вывод:
- поднимать это в `PRG_Policy` сейчас означало бы расширять policy-слой вниз в сторону отопительной доменной логики.

### D-02. В текущем состоянии `PRG_Heating` является естественной точкой вычисления target
`PRG_Heating` уже читает:
- `G_Preheat_Request`,
- `G_Freeze_Request`,
- `G_System_Mode`,
- safety context,
- heating runtime context.

Именно он уже выполняет arbitration/stabilization до вызова `FB_Heating_System_Manager`.

Вывод:
- делать другой owner для target temperature без отдельного вынесенного target-arbitration слоя сейчас преждевременно.

### D-03. Вынесение target ownership вверх сейчас привело бы к redesign, а не к cleanup
Если перенести owner `G_Target_Temperature` в `PRG_Policy` прямо сейчас, потребуется:
- перенос логики стабилизации,
- изменение границ между policy и heating,
- повторная проверка semantics для preheat/freeze transitions.

Это уже не локальное cleanup-решение, а заметный redesign архитектурных границ.

## Формальное правило ownership
На текущем этапе закрепляется следующее разделение:

### Owner coarse heating intents
`PRG_Policy`

Поля:
- `GVL_STATE.G_Preheat_Request`
- `GVL_STATE.G_Freeze_Request`

### Owner derived heating target
`PRG_Heating`

Поле:
- `GVL_STATE.G_Target_Temperature`

## Ограничения этого решения
Это решение не означает, что текущая форма target arbitration является окончательной навсегда.

Оно означает только следующее:
- на текущем cleanup-этапе target ownership не выносится выше policy-слоя;
- owner `G_Target_Temperature` формально признается за `PRG_Heating`;
- вопрос может быть пересмотрен позже только при отдельном явном redesign-решении.

## Что теперь считается допустимым
После этого решения допустимо:
- оставлять запись `GVL_STATE.G_Target_Temperature` внутри `PRG_Heating`;
- считать `PRG_Heating` легитимным owner derived target arbitration;
- чистить другие части wrapper, не пытаясь одновременно переносить target ownership в другой слой.

## Что теперь считается недопустимым без отдельного решения
Недопустимо:
- неявно переносить target ownership в `PRG_Policy`;
- создавать второго скрытого owner для `G_Target_Temperature`;
- использовать `GVL_HEATING_REQUEST` как параллельный owner target temperature;
- менять semantics target arbitration под видом мелкого cleanup.

## Практический вывод для следующего этапа
Так как owner для `G_Target_Temperature` теперь закреплен, следующий cleanup-этап можно фокусировать уже не на target ownership, а на:
- diagnostics/maintenance gating,
- ширине прямых публикаций из `PRG_Heating`,
- возможном разделении wrapper и supporting layers.

## Следующий рекомендуемый документ
- `14_HEATING_DIAGNOSTICS_GATING_CLEANUP_PLAN.md`

Его задача:
- разобрать, что именно из diagnostics/maintenance gating должно остаться в `PRG_Heating`,
- а что лучше вынести из wrapper в отдельный поддерживающий слой.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения