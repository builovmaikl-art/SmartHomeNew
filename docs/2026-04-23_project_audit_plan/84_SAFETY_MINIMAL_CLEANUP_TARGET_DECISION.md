# Safety Minimal Cleanup Target Decision

Дата фиксации: 2026-04-23

## Назначение
Этот документ переводит `83_SAFETY_PRODUCER_OWNERSHIP_SEGMENTATION.md` в следующее узкое решение:
**какой именно ownership-cluster внутри `PRG_Safety.st` должен стать первым minimal cleanup target**.

Цель:
- выбрать наиболее подходящий локальный подscope для следующей remediation-волны;
- не раздувать cleanup до всего `PRG_Safety.st`;
- подтвердить, что следующий шаг будет пропорционален уже подтвержденному smell.

## Основание
Решение опирается на:
- `81_SAFETY_FIX_DIRECTION_DECISION.md`
- `82_SAFETY_PRODUCER_OWNERSHIP_CLEANUP_PLAN.md`
- `83_SAFETY_PRODUCER_OWNERSHIP_SEGMENTATION.md`
- текущее состояние `PRG_Safety.st`

## Что уже подтверждено
К текущему моменту уже зафиксировано:
- safety cluster архитектурно layered и coherent;
- publication boundary через `GVL_INTENT_SAFETY` working and meaningful;
- главный smell сосредоточен в producer-side ownership concentration inside `PRG_Safety.st`;
- `PRG_Safety.st` сегментирован на 4 ownership-clusters;
- наиболее promising candidate по предыдущему этапу выглядит как operator/test/recover workflow cluster.

## Варианты minimal cleanup target

### Option A. Cluster 1 — core hazard/interlock projection
Суть:
- брать в cleanup само ядро producer-role:
  - alarm semantic projection,
  - required-action projection,
  - freeze-related projection.

Почему это слабый кандидат сейчас:
- это наиболее естественная и оправданная часть safety producer-layer;
- её трогать сейчас значит рисковать сломать working publication model без достаточного выигрыша.

### Option B. Cluster 2 — operator/test/recover workflow
Суть:
- брать в cleanup:
  - edge detection для valve-test / selective-recover,
  - activity/deadline workflow,
  - timeout-driven projection в required actions.

Почему это сильный кандидат:
- это stateful workflow semantics поверх core safety producer role;
- этот слой уже выглядит дополнительным, а не центрально-необходимым ядром boundary.

### Option C. Cluster 3 — safety-access coupling
Суть:
- брать в cleanup lock/egress-related semantics:
  - `I_Lock_1_Force_Open`
  - `I_Lock_1_Force_Close_Block`
  - `I_Lock_2_Force_Open`
  - `I_Lock_2_Force_Close_Block`

Почему это не лучший first target:
- этот подscope действительно выделим,
- но здесь выше риск задеть оправданную fire/egress semantics.

### Option D. Cluster 4 — producer-heavier publication tail
Суть:
- брать поля с менее явно подтвержденным consumer landscape.

Почему это не лучший first target:
- это скорее scope для дальнейшего подтверждения/clarification;
- он пока хуже подходит для точечного code cleanup, чем workflow-cluster.

## Решение
На текущем этапе принимается:

# Decision: Option B — Cluster 2 (operator/test/recover workflow)

## Почему выбран именно этот вариант

### SMCT-01. Это наиболее явно не-core часть producer ownership
В отличие от core hazard/interlock projection, operator/test/recover workflow:
- не выглядит обязательным ядром safety boundary;
- добавляет локальную statefulness поверх producer semantics.

Вывод:
- этот cluster естественнее рассматривать как candidate for segregation/cleanup.

### SMCT-02. Это самый узкий scope с наилучшим hygiene payoff
Cluster 2 включает:
- edge detection,
- workflow flags,
- deadlines,
- timeout-driven safety actions.

Вывод:
- это локальный и хорошо очерченный subset, дающий хороший architecture-hygiene payoff при сравнительно низком риске.

### SMCT-03. Это не ломает working publication boundary
Выбор Cluster 2 позволяет:
- не трогать `GVL_INTENT_SAFETY` как model;
- не ломать downstream consumers;
- не вмешиваться в ядро hazard/interlock projection.

Вывод:
- cleanup остается пропорциональным и безопасным.

### SMCT-04. Safety-access coupling лучше оставить вторым кандидатом
Lock/egress semantics действительно выделяются.

Но брать их first cleanup target сейчас рискованнее, чем workflow-cluster, потому что там выше вероятность задеть safety-critical domain coupling.

Вывод:
- Cluster 3 разумно оставить secondary candidate.

## Что именно фиксируется этим решением

### RD-SMCT-01. First cleanup target = operator/test/recover workflow
В следующий локальный cleanup scope должны входить:
- edge detection по valve-test / selective-recover inputs;
- activity/deadline state;
- timeout-driven projection, связанная именно с test/recover workflow semantics.

### RD-SMCT-02. Core hazard/interlock projection остается на месте
На текущем этапе не нужно трогать:
- основную alarm/interlock projection часть `PRG_Safety.st`.

### RD-SMCT-03. Safety-access coupling остается secondary candidate
Lock/egress subset признается значимым,
но не первым cleanup target.

### RD-SMCT-04. Producer-heavier publication tail остается clarification tail
Поля с менее явно подтвержденными consumers пока остаются documented tail, а не immediate cleanup target.

## Что это решение НЕ означает
Это решение не означает:
- немедленное физическое выделение нового POU;
- обязательный code refactor в этом же документе;
- что workflow-cluster уже признан дефектным runtime-wise;
- что остальные части `PRG_Safety.st` теперь закрыты навсегда.

Это означает только:
- следующий локальный safety cleanup должен начинаться именно с operator/test/recover workflow cluster.

## Практический смысл решения
После этого документа safety remediation получает уже не просто segmentation, а конкретный execution focus:
- не весь `PRG_Safety.st`,
- не весь safety cluster,
- а один наиболее узкий и управляемый subset.

Это делает следующий шаг достаточно точным для minimal changeset planning.

## Следующий рекомендуемый документ
- `85_SAFETY_WORKFLOW_CLUSTER_CLEANUP_PLAN.md`

Его задача:
- зафиксировать минимальный cleanup scope вокруг operator/test/recover workflow cluster;
- определить, как его разгружать без ломки core hazard/interlock projection.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения