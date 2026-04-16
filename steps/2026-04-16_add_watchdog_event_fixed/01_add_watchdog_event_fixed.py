from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

var_anchor = "L_IO_Fault_Prev : BOOL;\n"
var_insert = "L_Watchdog_Fault_Prev : BOOL;\n"

if var_insert not in text:
    if var_anchor not in text:
        raise SystemExit("VAR anchor not found in live PRG_System.st")
    text = text.replace(var_anchor, var_anchor + var_insert, 1)

anchor = "// === EVENT LOGGING: FAULTS ===\n\n// IO\n"

insert_block = """// WATCHDOG
IF fbWatchdog.VO_Watchdog_Fault AND NOT L_Watchdog_Fault_Prev THEN
    fbLogEvent(
        VI_Event_Type := 11,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 1,
        VI_Param2 := 1
    );
END_IF;

IF NOT fbWatchdog.VO_Watchdog_Fault AND L_Watchdog_Fault_Prev THEN
    fbLogEvent(
        VI_Event_Type := 12,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 1,
        VI_Param2 := 0
    );
END_IF;

L_Watchdog_Fault_Prev := fbWatchdog.VO_Watchdog_Fault;

"""

if insert_block not in text:
    if anchor not in text:
        raise SystemExit("FAULT EVENT anchor not found in live PRG_System.st")
    text = text.replace(anchor, "// === EVENT LOGGING: FAULTS ===\n\n" + insert_block + "// IO\n", 1)

path.write_text(text, encoding="utf-8")
print("OK: watchdog event logging added to PRG_System.st")
