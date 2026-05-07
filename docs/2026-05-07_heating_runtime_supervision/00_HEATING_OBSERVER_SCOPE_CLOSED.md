# Heating Observer Runtime Scope — Closed

Дата закрытия: 2026-05-07

## Статус

Стартовый документ `HEATING_MINIMAL_OBSERVER_ATTACHMENT_ARCHITECTURE.md` обработан.

Цель этапа была:
- безопасно подключить passive observer к heating runtime;
- читать только finalized runtime state;
- сохранить работу `PRG_Heating.st` без изменения отопительной логики;
- подготовить понятную публикацию состояния для telemetry/HMI.

Этап выполнен.

---

## Реализованные runtime-файлы

### Runtime observer

- `FB_Heating_Runtime_Observer.st`

Назначение:
- читает finalized runtime context;
- публикует passive observation payload;
- не сканирует внутренние runtime-структуры напрямую.

### Runtime authorization / enable evaluation

- `FB_Heating_Runtime_Observer_Authorization.st`

Назначение:
- разделяет request и effective enablement;
- проверяет bootstrap/passive/read-only условия;
- возвращает status code/text.

### Runtime lifecycle enum

- `E_Runtime_Observer_Lifecycle_State.typ`

Состояния:
- `ROS_INACTIVE`
- `ROS_AUTHORIZATION_PENDING`
- `ROS_AUTHORIZATION_DENIED`
- `ROS_STABILIZATION`
- `ROS_OPERATIONAL`
- `ROS_ROLLBACK`
- `ROS_FAULTED`

### Runtime observer GVL

- `GVL_Heating_Runtime_Observer.gvl`

Назначение:
- request;
- effective enablement;
- lifecycle status;
- validation markers;
- bootstrap limitation flags.

### Runtime observation GVL

- `GVL_Heating_Runtime_Observation.gvl`

Назначение:
- observation payload;
- publication validity;
- stabilization state;
- operational state;
- lifecycle code/text;
- commissioning visibility.

### Runtime integration

- `PRG_Heating.st`

Изменения:
- добавлен finalized runtime context;
- подключена enable evaluation;
- подключён observer;
- добавлены lifecycle transitions;
- добавлен reset publication payload при отключении;
- сохранён output projection порядок.

---

## Что считается завершённым

- passive observer подключён;
- finalized-state observation используется;
- lifecycle state публикуется;
- lifecycle code/text публикуются;
- commissioning visibility есть;
- stale payload reset реализован;
- first-cycle stabilization реализован;
- rollback cleanup реализован.

---

## Что не входило в этот этап

- predictive runtime control;
- adaptive runtime control;
- replay engine activation;
- autonomous orchestration;
- writable HMI controls.

---

## Итог

Heating observer runtime scope завершён.

Дальнейшая работа должна идти как отдельный read-only extension roadmap.

Следующий документ:
- `docs/2026-05-07_heating_runtime_supervision/01_HEATING_SUPERVISION_EXTENSION_ROADMAP.md`
