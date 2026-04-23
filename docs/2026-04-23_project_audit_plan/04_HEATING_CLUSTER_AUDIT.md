# Heating Cluster Audit

Дата фиксации: 2026-04-23

## Область аудита
- `PRG_Heating.st`
- `FB_Heating_System_Manager.st`
- `FB_DHW_Manager.st`
- `docs/systems/heating.md`
- связь heating cluster с `MAIN.st`

## Метод
Аудит выполнен по живому корню репозитория. Архивы и snapshots не использовались как источник истины.

## Главный вывод
Heating cluster в текущем корне нельзя считать целостно подтвержденным runtime-контуром, потому что основной orchestration-layer файл `PRG_Heating.st` выглядит как сокращенный, а не как полноценный program source.

При этом нижний слой cluster выглядит значительно лучше:
- `FB_Heating_System_Manager.st` выглядит как полноценный большой рабочий функциональный блок,
- `FB_DHW_Manager.st` выглядит как полноценный и логически завершенный функциональный блок,
- subsystem docs по heating совпадают с целевым policy-driven направлением.

То есть проблема heating cluster сейчас выглядит не как отсутствие доменной логики, а как проблема целостности program-layer и состояния миграции вокруг него.

## Подтвержденные наблюдения

### H-001. PRG_Heating подключен в MAIN как live program
Heating-контур реально входит в текущий вызовной граф верхнего уровня через `MAIN.st`.

Вывод:
- проблема с `PRG_Heating.st` относится к live root, а не к неиспользуемому архивному коду.

Приоритет: CRITICAL.

### H-002. PRG_Heating в корне хранится как сокращенный текстовый фрагмент
В текущем `PRG_Heating.st` присутствуют буквальные вставки:
- `... (same code omitted for brevity until thermal block, unchanged)`
- `// rest unchanged`

Это несовместимо с представлением файла как полноценного runtime program source.

Вывод:
- либо файл в корне поврежден,
- либо в корень попал сокращенный редакторский вариант,
- либо корень репозитория временно содержит неисполняемую промежуточную форму heating program.

Приоритет: CRITICAL.

### H-003. FB_Heating_System_Manager выглядит как реальный рабочий доменный блок
По структуре `FB_Heating_System_Manager.st` видно:
- полноценный интерфейс,
- policy-driven обработку `NORMAL / SAFE_STOP / DEGRADED / FREEZE_PROTECTION`,
- freeze / emergency / IO-failsafe ветви,
- heating diagnostics,
- многоуровневую доменную логику отопления.

Вывод:
- доменная heating logic не отсутствует;
- основной риск сосредоточен не в самом FB, а в program wrapper, orchestration и ownership-связях.

Приоритет: HIGH.

### H-004. FB_DHW_Manager выглядит целостным и согласованным с policy-driven подходом
По структуре `FB_DHW_Manager.st` видно:
- явный вход `VI_System_Mode`,
- policy override для `SAFE_STOP` и `FREEZE_PROTECTION`,
- явную диагностику IO / sensors,
- логически завершенный цикл нагрева и рециркуляции.

Вывод:
- DHW-подконтур выглядит значительно более цельным, чем `PRG_Heating` wrapper.

Приоритет: MEDIUM.

### H-005. Heating subsystem docs совпадают с целевым архитектурным вектором
Документация `docs/systems/heating.md` фиксирует, что heating:
- policy-driven,
- потребляет `System Mode`,
- не должен локально арбитрировать global mode,
- должен публиковать деградацию вверх.

Вывод:
- концептуальный слой heating описан правильно;
- основное расхождение сейчас между documentation target и фактическим состоянием orchestration/program layer.

Приоритет: MEDIUM.

## Зафиксированные проблемы heating cluster

### HC-001. Нарушена целостность live program layer
`PRG_Heating.st` сейчас нельзя воспринимать как надежный live-source.

Риск:
- невозможность уверенно анализировать heating call flow сверху вниз,
- невозможность отличить реальный runtime-path от сокращенного текстового placeholder,
- высокий риск неверных последующих правок в heating cluster.

### HC-002. Анализ cluster сверху вниз сейчас частично блокирован состоянием PRG_Heating
Пока не подтвержден полноценный текст `PRG_Heating.st`, нельзя завершить:
- корректную карту вызовов heating -> DHW -> commands -> outputs,
- ownership-аудит heating wrapper,
- проверку всех side effects в `GVL_STATE`, `GVL_STATUS`, `GVL_COMMAND`.

### HC-003. Подсистемный FB-слой все еще тесно связан с глобалами
Даже при хорошем policy-driven направлении `FB_Heating_System_Manager` и `FB_DHW_Manager` пишут в глобальные признаки деградации через `GVL_STATE`.

Риск:
- ослабление ownership boundaries,
- усложнение тестирования cluster изолированно,
- смешение subsystem behavior и global publication.

Это не главный аварийный дефект heating cluster, но это важная архитектурная тема после восстановления program-layer.

## Что пока НЕ утверждается

### NHC-001. Нельзя утверждать, что heating logic в целом сломана
Пока подтвержден только дефект представления `PRG_Heating.st` в корне. Полный runtime-эффект без compile/run проверки не подтверждается.

### NHC-002. Нельзя безопасно править heating cluster с середины
Пока program-layer не восстановлен или не подтвержден, любые точечные правки внутри heating orchestration несут повышенный риск, потому что live wrapper неизвестен не полностью.

## Решение по этапу heating audit
Первое действие в heating cluster должно быть не функциональная оптимизация и не локальный cleanup, а:

### Решение HC-R1
Подтвердить и восстановить целостный источник `PRG_Heating.st` в живом корне.

Только после этого переходить к:
- ownership-аудиту heating wrapper,
- DHW/heating interface map,
- cleanup прямых записей в глобальные diagnostics flags,
- policy-contract clarification для heating cluster.

## Следующий рекомендуемый документ
`05_HEATING_REMEDIATION_PLAN.md`

Его задача:
- зафиксировать безопасный порядок восстановления heating cluster,
- определить, какие проверки нужно сделать до любой содержательной правки heating logic,
- определить критерии, после которых heating cluster можно считать снова пригодным для детального рефакторинга.