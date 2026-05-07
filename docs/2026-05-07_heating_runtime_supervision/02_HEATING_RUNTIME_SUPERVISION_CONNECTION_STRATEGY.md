# Heating Runtime Supervision Connection Strategy

Дата фиксации: 2026-05-07

## Статус

Решение зафиксировано как архитектурная стратегия подключения heating runtime supervision FB family.

Режим фиксации: Direct Repository Modification Mode.  
Тип проверки: repository file-state verification only.  
Runtime/build/PLC verification: не выполнялась.

---

# 1. Главный принцип

`FB_Heating_Runtime_*` family нельзя подключать в runtime wholesale.

Наличие файла и успешная компиляция не означают, что POU должен быть частью active runtime execution graph.

Подключение допускается только если FB:

```text
1. имеет понятную read-only роль;
2. получает finalized runtime/diagnostic state;
3. не управляет отоплением;
4. не меняет command/domain outputs;
5. не создает параллельную orchestration authority;
6. имеет bounded publication surface;
7. имеет clear lifecycle / enable gating;
8. не дублирует уже существующую active функциональность.
```

---

# 2. Текущий безопасный runtime anchor

Уже допустимый и реализованный путь:

```text
MAIN
→ PRG_Heating
  → active heating runtime
  → finalized runtime context
  → FB_Heating_Runtime_Observer_Authorization
  → FB_Heating_Runtime_Observer
  → GVL_Heating_Runtime_Observation
```

Этот path считается единственным допустимым anchor для дальнейших bounded supervision extensions.

---

# 3. Запрещенная схема подключения

Запрещено подключать supervision family как новый управляющий runtime-layer:

```text
PRG_Heating
→ FB_Heating_Runtime_Coordinator
→ FB_Heating_Runtime_Orchestration_Shell
→ FB_Heating_Runtime_Event_Manager
→ predictive/adaptive/anomaly engines
→ runtime decisions
```

Причина:
- это создаст вторую orchestration authority;
- нарушит ownership boundaries;
- смешает observation и control;
- создаст ложную уверенность, что compile-visible prototypes являются deployed behavior;
- усложнит verification без фактической runtime необходимости.

---

# 4. Что можно подключать первым

## Phase 1 — Commissioning visibility only

Допустимые расширения:

```text
- last enable request timestamp;
- last operational timestamp;
- last rollback timestamp;
- lifecycle scan counters;
- bounded lifecycle transition journal.
```

Условия:
- read-only;
- фиксированный размер storage;
- no replay;
- no runtime authority;
- no control outputs.

---

## Phase 2 — Authorization diagnostics

Допустимые расширения:

```text
- E_Runtime_Observer_Deny_Reason;
- explicit deny reason publication;
- deny counter;
- deny reason text.
```

Условия:
- только диагностика authorization path;
- не влияет на heating control;
- не обходит существующий authorization FB.

---

## Phase 3 — HMI projection

Допустимые расширения:

```text
- FB_Heating_Runtime_Observer_HMI_Projection;
- HMI-safe lifecycle fields;
- HMI-safe commissioning fields;
- HMI-safe observation validity fields.
```

Условия:
- HMI path остается read-only;
- HMI не получает writable runtime authority;
- raw observation и HMI representation разделены.

---

## Phase 5 — Runtime observation realism improvement

Допустимые расширения:

```text
- real DHW executed evidence;
- real heating executed evidence;
- real diagnostics executed evidence;
- real output projection last evidence;
- publication-before-diagnostics validation;
- diagnostics-before-observer validation.
```

Условия:
- только observation evidence;
- без изменения active heating decisions;
- без изменения output projection order.

---

# 5. Что пока НЕ подключать

Следующие группы остаются future-reserved / compile-visible scaffolding, пока не будет отдельного bounded design document:

```text
FB_Heating_Runtime_Coordinator
FB_Heating_Runtime_Orchestration_Shell
FB_Heating_Runtime_Integration_Bridge_Manager
FB_Heating_Runtime_Event_Manager
FB_Heating_Runtime_Contract_Validator
FB_Heating_Runtime_Synchronization_Monitor
FB_Heating_Runtime_Observation_Validator
FB_Heating_Runtime_Observation_Aggregator
FB_Heating_Runtime_Phase_Telemetry_Aggregator
FB_Heating_Runtime_Phase_Sequencing_Validator
FB_Heating_Runtime_Phase_Transition_Observer
FB_Heating_Runtime_Timeline_Observer
FB_Heating_Runtime_Latency_Validator
FB_Heating_Runtime_Jitter_Detector
FB_Heating_Runtime_Stability_Model
FB_Heating_Runtime_RootCause_Correlator
FB_Heating_Runtime_Causality_Propagation_Analyzer
FB_Heating_Runtime_Degradation_Timeline_Rebuilder
FB_Heating_Runtime_Degradation_Trend_Analyzer
FB_Heating_Runtime_Event_Reconstruction_Engine
FB_Heating_Runtime_Fault_Replay_Analyzer
FB_Heating_Runtime_Anomaly_Aggregator
FB_Heating_Runtime_Anomaly_Correlator
FB_Heating_Runtime_Anomaly_Severity_Classifier
FB_Heating_Runtime_Anomaly_Weighting_Engine
FB_Heating_Runtime_Confidence_Decay_Analyzer
FB_Heating_Runtime_Supervision_Confidence_Analyzer
FB_Heating_Runtime_Supervision_Integrity_Validator
FB_Heating_Runtime_Predictive_Correlation_Weighting_Engine
FB_Heating_Runtime_OT_Instability_Predictor
FB_Heating_Runtime_Cascade_Collapse_Predictor
FB_Heating_Runtime_OT_Cascade_Correlator
FB_Heating_Runtime_Intelligence_Consistency_Analyzer
FB_Heating_Runtime_Adaptive_Drift_Detector
FB_Heating_Runtime_Adaptive_Risk_Scorer
```

Статус этих FB:

```text
file exists / compile-visible / not proven active / future-reserved until classified deeper
```

---

# 6. Delete/archive policy

Удалять такие FB автоматически нельзя.

Перед удалением нужен отдельный classification decision:

```text
1. obsolete duplicate;
2. misleading prototype;
3. future-reserved useful building block;
4. required helper with incomplete call graph evidence.
```

Allowed actions:

```text
- keep active;
- connect intentionally as bounded read-only extension;
- mark future-reserved;
- archive/move out of active expectation;
- delete only if explicitly obsolete and covered by audit decision.
```

---

# 7. Integration rule for any future connection

Любое новое подключение supervision FB должно идти только через следующий contract:

```text
finalized state/context input
→ authorization/lifecycle gating
→ read-only processing
→ bounded observation publication
→ optional HMI-safe projection
```

Запрещено:

```text
- writing GVL_HEATING_OUTPUT;
- writing GVL_COMMAND_SHADOW;
- writing physical IO;
- changing PRG_Heating active control decisions;
- owning heating orchestration;
- enabling predictive/adaptive runtime authority;
- executing replay as runtime behavior;
- creating unbounded event/history buffers;
- duplicating blackbox/history systems.
```

---

# 8. Current recommendation

Следующий практический шаг:

```text
Implement Phase 1 or Phase 2 only.
```

Recommended first target:

```text
Phase 2 — Authorization diagnostics expansion
```

Причина:
- небольшая область;
- не влияет на heating control;
- улучшает commissioning/debug visibility;
- естественно расширяет уже активный `FB_Heating_Runtime_Observer_Authorization`;
- не требует подключения coordinator/orchestration/event manager.

---

# 9. Decision summary

Решение:

```text
Do not connect the whole heating runtime supervision family.
Connect only bounded, read-only, lifecycle-gated extensions through the existing passive observer path.
Keep control ownership inside the current heating runtime and command/domain pipeline.
Classify the rest as future-reserved until proven necessary.
```

Статус: зафиксировано.
