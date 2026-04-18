from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

pump_old = """fbLifetimePump(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Device_Active  := GVL_PERSISTENT.P_DHW_Heating_Active,
    VI_Device_ID      := GVL_Lifetime.G_Device_Pump,
    VIO_Status        := GVL_Lifetime.G_Status[1]
);"""

pump_new = """fbLifetimePump(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Device_Active  := GVL_PERSISTENT.P_DHW_Heating_Active,
    VI_Device_ID      := GVL_Lifetime.G_Device_Pump,
    VI_Nominal_Hours  := GVL_Lifetime.G_Pump_Nominal_Hours,
    VIO_Status        := GVL_Lifetime.G_Status[1]
);"""

fan_old = """fbLifetimeFan(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Device_Active  := (
        GVL_STATE.G_Supply_Fans[1] > 0 OR
        GVL_STATE.G_Exhaust_Fans[1] > 0
    ),
    VI_Device_ID      := GVL_Lifetime.G_Device_Fan,
    VIO_Status        := GVL_Lifetime.G_Status[2]
);"""

fan_new = """fbLifetimeFan(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Device_Active  := (
        GVL_STATE.G_Supply_Fans[1] > 0 OR
        GVL_STATE.G_Exhaust_Fans[1] > 0
    ),
    VI_Device_ID      := GVL_Lifetime.G_Device_Fan,
    VI_Nominal_Hours  := GVL_Lifetime.G_Fan_Nominal_Hours,
    VIO_Status        := GVL_Lifetime.G_Status[2]
);"""

if pump_old not in text:
    raise SystemExit("Pump lifetime call not found")
if fan_old not in text:
    raise SystemExit("Fan lifetime call not found")

text = text.replace(pump_old, pump_new, 1)
text = text.replace(fan_old, fan_new, 1)

path.write_text(text, encoding="utf-8")
print("OK: patched PRG_System lifetime calls with nominal hours")
