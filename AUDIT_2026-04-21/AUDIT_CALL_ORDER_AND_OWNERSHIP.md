# CALL ORDER AND OWNERSHIP AUDIT

## Фактический порядок вызовов (из MAIN)
1. PRG_IO_Read
2. PRG_Policy
3. PRG_System
4. PRG_Safety
5. PRG_Security
6. PRG_Heating
7. PRG_Ventilation
8. PRG_Lighting
9. PRG_IO_Write

## Что это означает по факту
- `PRG_Policy` принимает решение по `GVL_STATE.G_System_Mode` до того, как `PRG_System` и `PRG_Safety` завершили публикацию фактического safety/system state текущего цикла.
- `PRG_Heating`, `PRG_Ventilation`, `PRG_Lighting`, `PRG_Security` работают уже после `PRG_System` и `PRG_Safety`, но зависят от качества ownership глобальных состояний и команд.
- `PRG_IO_Write` выглядит как единая точка записи в физические выходы, что является правильным целевым принципом.

## Найденные проблемы

### CO-001 — Неверный порядок вызова Policy
- `PRG_Policy` вызывается до формирования `System_Mode` и safety-state текущего цикла.
- риск: сценарии и policy-bridge принимаются на невалидном или устаревшем состоянии.
- приоритет: CRITICAL.

### OWN-001 — Два владельца System_Mode
- `PRG_System` и `PRG_Safety` оба записывают `GVL_STATE.G_System_Mode`.
- риск: конфликт ownership и недетерминированное поведение режима.
- приоритет: CRITICAL.

### OWN-002 — Policy использует режим, owner которого не стабилизирован в момент вызова
- `PRG_Policy` опирается на `GVL_STATE.G_System_Mode`, но вызывается до завершения актуального mode arbitration.
- риск: policy принимает решение на предыдущем цикле / неполном состоянии.
- приоритет: CRITICAL.

### OWN-003 — Ownership командного слоя не централизован
- `GVL_COMMAND` используется как общий mutable-layer, в который пишут разные программы:
  - `PRG_Safety` публикует safety-команды;
  - `PRG_Security` публикует access-команды и 2FA-команды;
  - `PRG_System` публикует gateway / operator / maintenance side-effects;
  - `PRG_IO_Write` уже только читает команды.
- риск: команда может быть записана несколькими владельцами без единого arbitration layer.
- приоритет: HIGH.

### OWN-004 — Security motion input broken at source adapter
- в `PRG_Security` массив `L_Motion_Sensors_16` заполняется сам из себя (`L_Motion_Sensors_16[L_i] := L_Motion_Sensors_16[L_i];`), а не из runtime state.
- риск: охранный manager получает некорректный motion input.
- приоритет: HIGH.

## Ownership map (текущее состояние)

### 1. System mode
**Фактические writers:**
- `PRG_System`
- `PRG_Safety`

**Целевой owner:**
- только `FB_System_Health + FB_State_Manager` через `PRG_System`

### 2. Scenario intent / policy intent
**Фактические writers/readers:**
- `PRG_System` заполняет policy requests (`GVL_POLICY.G_Scenario_Request_*`)
- `PRG_Policy` вычисляет `GVL_POLICY.G_Scenario_Intent` и `GVL_POLICY.G_Scenario_Source`
- `PRG_System` затем потребляет `GVL_POLICY.G_Scenario_Intent`

**Вывод:**
- ownership intent задуман централизованно через `GVL_POLICY`, но текущий call-order ломает эту модель.

### 3. Command layer (`GVL_COMMAND`)
**Фактические owners по подсистемам:**
- `PRG_Safety` — аварийные команды газа / воды / вентиляции / locks
- `PRG_Security` — gate / wicket / lock / 2FA-related commands
- `PRG_System` — gateway bridge, reset, operator and maintenance related command side-effects
- HMI / gateway / retain/config layers также участвуют как источники входящих intent

**Вывод:**
- нужен явный audit-комментарий: command layer сейчас выступает смешанным transport+ownership слоем, а не строго арбитрируемым command bus.

### 4. Physical IO (`GVL_IO`)
**Фактический writer:**
- `PRG_IO_Write`

**Вывод:**
- физическая запись выглядит централизованной, это сильная сторона текущей архитектуры.
- дальнейший аудит должен проверять не direct writes в `GVL_IO`, а скрытые конфликты upstream в `GVL_STATE` и `GVL_COMMAND`.

## Требуемое целевое состояние

### Правильный порядок выполнения
1. `IO_Read`
2. `Safety`
3. `System`
4. `Policy`
5. `Managers`
6. `IO_Write`

### Правильный ownership
- `System_Mode` — единственный owner: `PRG_System`
- `Scenario_Intent` — единственный owner: `PRG_Policy`
- `Physical IO` — единственный owner: `PRG_IO_Write`
- `Safety commands` — после отдельного audit-решения должны быть централизованы через явный command arbitration layer, а не через разрозненные прямые записи в `GVL_COMMAND`

## Следующие точки аудита
1. `AUDIT_CHAIN_SYSTEM_MODE.md`
2. `AUDIT_CHAIN_SAFETY_ACTIONS.md`
3. отдельная фиксация ownership для `GVL_COMMAND`
