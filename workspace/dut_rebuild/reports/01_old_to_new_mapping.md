# Old to new DUT mapping draft

## Rule engine
- ST_User_Rule.dut -> ST_User_Rule_V2.dut
- ST_Rule_Action.dut -> ST_Rule_Action_V2.dut

## Alarm
- ST_Alarm_Record.dut -> ST_Alarm_Core_Record_V2.dut + ST_Alarm_View_Record_V2.dut + ST_Alarm_Event_V2.dut

## History / BlackBox
- ST_History_Record.dut -> ST_History_Event_V2.dut
- ST_BlackBox_Record.dut -> ST_BlackBox_Snapshot_V2.dut
