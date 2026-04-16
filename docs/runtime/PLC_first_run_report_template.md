# PLC First Run Report Template

## 1. Общая информация
- Дата прогона:
- Версия проекта / commit:
- PLC / target:
- Кто запускал:

## 2. Старт проекта
- Проект скомпилировался: YES / NO
- Проект стартовал: YES / NO
- Были ли стартовые ошибки:
- Комментарий:

## 3. System mode
- `GVL_STATE.G_System_Mode`:
- `GVL_STATE.G_System_Mode_Text`:
- `GVL_STATUS.G_System_Mode_Cause`:
- Норма / отклонение:
- Комментарий:

## 4. Scenario layer
- `GVL_STATUS.G_Current_Scenario` после старта:
- `GVL_STATUS.G_Previous_Scenario` после старта:
- Штатная смена сценария: OK / FAIL
- Event/history перехода: OK / FAIL
- Policy AWAY при armed: OK / FAIL
- Soft guard `AWAY -> PARTY`: OK / FAIL
- `HMI_Last_Message`:
- Комментарий:

## 5. Dangerous action
- Arm state: OK / FAIL
- Timeout path: OK / FAIL
- Deny path: OK / FAIL
- Apply only in NORMAL/DEGRADED: OK / FAIL
- Комментарий:

## 6. Safety
- Flood response: OK / FAIL / NOT TESTED
- Gas response: OK / FAIL / NOT TESTED
- Fire/smoke response: OK / FAIL / NOT TESTED
- Confirm/recover block under hazard: OK / FAIL / NOT TESTED
- Комментарий:

## 7. Events / health
- Mode event 4: OK / FAIL / NOT TESTED
- Scenario event: OK / FAIL / NOT TESTED
- Policy events 5/6/7: OK / FAIL / NOT TESTED
- Watchdog 11/12: OK / FAIL / NOT TESTED
- IO fault 2/3: OK / FAIL / NOT TESTED
- Комментарий:

## 8. Gateway
- One-shot `VO_*`: OK / FAIL
- Telegram != sync time: OK / FAIL
- Sync/reset/config separated: OK / FAIL
- Комментарий:

## 9. Dry-run non-interference
- Dry-run helpers inactive: YES / NO
- Production path independent from dry-run: YES / NO
- Комментарий:

## 10. Красные флаги
- Были ли критические отклонения:
- Что именно:
- Требуется ли откат / срочный фикс:

## 11. Следующий шаг
- Что делать дальше:
- Нужен ли следующий кодовый фикс:
- Нужен ли повторный прогон:
