# Rebuild-first DUT scope

## Targets
- ST_User_Rule.dut
- ST_Rule_Action.dut
- ST_Alarm_Record.dut
- ST_History_Record.dut
- ST_BlackBox_Record.dut

## Strategy
- do not edit active DUT in-place
- prepare replacement model in workspace
- separate core data from UI/projection/compatibility
- integrate later by explicit migration steps
