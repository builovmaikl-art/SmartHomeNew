from pathlib import Path

path = Path("FB_Alarm_Manager.st")
text = path.read_text(encoding="utf-8")

old = """// Shadow bridge: System -> BlackBox V2 (diagnostic only)
fbBlackBoxV2Core(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_System_Mode := 0,
    VI_Critical_Alarm_Active := VO_Global_Critical,
    VI_Warning_Active := VO_Global_Warning,
    VI_First_Fault_Type := TO_BYTE(VI_First_Fault_Type),
    VI_First_Fault_Source := TO_BYTE(VI_First_Fault_Source),
    VI_Gas_Alarm := VI_Gas_Alarm,
    VI_Fire_Alarm := VI_Fire_Alarm,
    VI_Flood_Alarm := VI_Flood_Alarm,
    VO_Snapshot => L_BlackBox_V2_Snapshot_Shadow
);
"""

new = """// Shadow bridge: System -> BlackBox V2 (diagnostic only)
// Inlined from FB_BlackBox_V2_Core
L_BlackBox_V2_Snapshot_Shadow.Gas_Alarm := VI_Gas_Alarm;
L_BlackBox_V2_Snapshot_Shadow.Fire_Alarm := VI_Fire_Alarm;
L_BlackBox_V2_Snapshot_Shadow.Flood_Alarm := VI_Flood_Alarm;
L_BlackBox_V2_Snapshot_Shadow.First_Fault_Type := TO_BYTE(VI_First_Fault_Type);
L_BlackBox_V2_Snapshot_Shadow.First_Fault_Source := TO_BYTE(VI_First_Fault_Source);
"""

if old not in text:
    raise SystemExit("BlackBox V2 core call block not found")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: inlined blackbox V2 core logic into FB_Alarm_Manager.st")
