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

## Найденные проблемы

### CO-001 — Неверный порядок вызова Policy
- PRG_Policy вызывается до формирования System_Mode и Safety
- риск: сценарии принимаются на невалидном состоянии
- приоритет: CRITICAL

### OWN-001 — Два владельца System_Mode
- PRG_System и PRG_Safety оба записывают G_System_Mode
- риск: конфликт и недетерминированное поведение
- приоритет: CRITICAL

## Требуемое целевое состояние

Правильный порядок:
1. IO_Read
2. Safety
3. System
4. Policy
5. Managers
6. IO_Write

System_Mode должен иметь единственного владельца:
- FB_System_Health + FB_State_Manager (через PRG_System)

PRG_Safety не должен напрямую изменять G_System_Mode
