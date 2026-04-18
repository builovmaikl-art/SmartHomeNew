from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

old = "    VI_Device_Active  := FALSE,\n    VI_Device_ID      := GVL_Lifetime.G_Device_Pump,\n"
new = "    VI_Device_Active  := GVL_PERSISTENT.P_DHW_Heating_Active,\n    VI_Device_ID      := GVL_Lifetime.G_Device_Pump,\n"

if old not in text:
    raise SystemExit("Pump lifetime call pattern not found in PRG_System.st")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: connected lifetime pump signal to GVL_PERSISTENT.P_DHW_Heating_Active")
