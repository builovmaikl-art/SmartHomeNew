# Equipment Decisions Log

## Water Zonal Valves

Decision: Use motorized ball valves (шаровые клапаны с электроприводом).

Rationale:
- Provide reliable OPEN/CLOSE position feedback (end switches)
- Suitable for long-term static positions (low wear vs solenoid valves)
- Fail-safe behavior is more predictable
- Better suited for selective zone control logic implemented in Steps 70–72

Rejected alternative:
- Solenoid valves (электромагнитные клапаны)
  - Higher wear in long-open scenarios
  - Less suitable for precise positional feedback

Control/feedback requirements:
- OPEN command
- CLOSE command
- OPEN_FB (optional but recommended)
- CLOSE_FB (mandatory for safety validation)

Notes:
- CLOSE_FB is critical for аварийная логика (water/gas shutoff confirmation)
- OPEN_FB improves diagnostics and test mode validation

Status: Approved

## 📌 Дополнение

### Адресные устройства
- датчики и выключатели поддерживают адресную модель
- переназначение через HMI

### Клапаны воды
- тип: шаровые с электроприводом
- обязательны концевики

