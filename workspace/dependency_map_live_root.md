# Live root dependency map

## Root files considered

### DUT_OR_ENUM
- E_ALERT_PRIORITY.dut
- E_Debug_Log_Level.dut
- E_Gateway_Command_Type.dut
- E_Lifetime_Device_Type.dut
- E_Outdoor_Mode.dut
- E_PLC_ROLE.dut
- E_Rule_Action_Type.dut
- E_Rule_Comparison.dut
- E_Rule_Condition_Type.dut
- E_SCENARIO_SOURCE.dut
- E_SCENARIO_TYPE.dut
- E_SENSOR_TYPE.dut
- E_System_Operating_Mode.dut
- E_System_Root_Cause.dut
- E_System_Severity.dut
- E_Trend_Parameter_Type.dut
- E_TwoFactor_Method.dut
- E_VALVE_TYPE.dut
- E_VENTILATION_LOCATION.dut
- E_VENTILATION_UNIT_TYPE.dut
- E_Valve_Test_Result.dut
- E_WEATHER_COMPENSATION_METHOD.dut
- E_Zone_Access_Level.dut
- ST_Alarm_Record.dut
- ST_Astro_Time.dut
- ST_BlackBox_Record.dut
- ST_Boiler_Status.dut
- ST_Component_Maintenance.dut
- ST_DHW_Config.dut
- ST_DHW_Status.dut
- ST_Debug_Log_Record.dut
- ST_Debug_Logger_Config.dut
- ST_Device_Health.dut
- ST_EVENT.dut
- ST_Flood_Config.dut
- ST_Flood_Global_Config.dut
- ST_FloorHeating_Circuit_Config.dut
- ST_FloorHeating_Global_Config.dut
- ST_FloorHeating_Manifold_Config.dut
- ST_Gas_Valve_Configuration.dut
- ST_Gateway_Command.dut
- ST_Heating_Config.dut
- ST_History_Record.dut
- ST_Lifetime_Status.dut
- ST_Maintenance_Access_Config.dut
- ST_Manifold_Status.dut
- ST_Operator_Zone_Rights.dut
- ST_Outdoor_Zone_Config.dut
- ST_Owen_Analog_Value.dut
- ST_Persist.dut
- ST_Rule.dut
- ST_Rule_Action.dut
- ST_Scenario_Config.dut
- ST_Scenario_Transition_Config.dut
- ST_Security_Global_Config.dut
- ST_Security_Zone_State.dut
- ST_Sensor_Calibration_Record.dut
- ST_State_Snapshot.dut
- ST_System_Diagnostics.dut
- ST_System_State_Snapshot.dut
- ST_System_State_Summary.dut
- ST_Tariff_Config.dut
- ST_Trend_Config.dut
- ST_Trend_Data.dut
- ST_Trend_Header.dut
- ST_Trend_History_Record.dut
- ST_TwoFactor_Auth_State.dut
- ST_TwoFactor_Data.dut
- ST_User_Rule.dut
- ST_Valve_Test_Config.dut
- ST_Ventilation_Config.dut
- ST_Ventilation_Global_Config.dut
- ST_Ventilation_Scenario_Mode.dut
- ST_Ventilation_Unit.dut
- ST_Ventilation_Unit_Config.dut
- ST_Zone_Sensors.dut

### FUNCTION_BLOCK
- FB_AccessCode_Manager.st
- FB_Access_Control.st
- FB_Alarm_Manager.st
- FB_Analog_Validator.st
- FB_Astro_Timer.st
- FB_BlackBox_Recorder.st
- FB_Boiler_Cascade_Manager.st
- FB_Boiler_OpenTherm_Interface.st
- FB_CO_Detector.st
- FB_CRC32_Calculator.st
- FB_Calibration_Manager.st
- FB_Command_Deduplication.st
- FB_CoreKernel_Live_Observer.st
- FB_DHW_Manager.st
- FB_Device_Predictive_Diag.st
- FB_DryRun_Assertion_Map.st
- FB_DryRun_Simulation_Harness.st
- FB_Emergency_Valve_Open.st
- FB_Exhaust_Ventilation_Controller.st
- FB_Fault_Logger.st
- FB_FloorHeating_Controller.st
- FB_FloorHeating_Freeze_Protection.st
- FB_FloorHeating_Overheat_Protection.st
- FB_Gas_Methane_Detector.st
- FB_Gas_Smoke_Manager.st
- FB_Gas_Valve_Controller.st
- FB_Gateway_Interface.st
- FB_HMAC_SHA1.st
- FB_HMI_Interface.st
- FB_Heating_System_Manager.st
- FB_History_Manager.st
- FB_IO_Module_Watchdog.st
- FB_Lifetime_Predictor.st
- FB_Lighting_Blinds_Manager.st
- FB_LogEvent.st
- FB_Maintenance_Access.st
- FB_Manifold_Pump_Controller.st
- FB_Manual_Valve_Control.st
- FB_NVRAM_Manager.st
- FB_Outdoor_Lighting_Controller.st
- FB_PID_Controller.st
- FB_PLC_Heartbeat.st
- FB_Pre_Departure_Heating.st
- FB_Presence_Playback.st
- FB_Presence_Simulator.st
- FB_Random_Generator.st
- FB_Redundancy_Manager.st
- FB_Rule_Engine.st
- FB_SHA1.st
- FB_Safety_Manager.st
- FB_Scenario_Manager.st
- FB_Scenario_Transition_Controller.st
- FB_Scenario_Transition_Guard.st
- FB_Security_Alarm.st
- FB_Security_System_Manager.st
- FB_Sensor_Analog_Processing.st
- FB_Sensor_Calibration.st
- FB_Sensor_Calibration_Processor.st
- FB_Sensor_Distribution.st
- FB_Simulation_Manager.st
- FB_Smoke_Detector.st
- FB_Socket_Manager.st
- FB_State_Manager.st
- FB_State_Replication.st
- FB_State_Snapshot_Manager.st
- FB_State_Snapshot_NVRAM.st
- FB_Supply_Ventilation_Controller.st
- FB_System_Health.st
- FB_System_Timer.st
- FB_System_Timer_TOF.st
- FB_Trend_Analyzer.st
- FB_Trend_Logger.st
- FB_TwoFactor_Auth.st
- FB_Valve_Test_Manager.st
- FB_Ventilation_System_Manager.st
- FB_Watchdog.st
- FB_Water_Leakage_Manager.st
- FB_Water_Valve_Controller.st
- FB_Zone_Access_Manager.st

### GLOBAL_VAR_LIST
- GVL_ALARM.gvl
- GVL_COMMAND.gvl
- GVL_CONFIG.gvl
- GVL_CONSTANTS.gvl
- GVL_EVENT.gvl
- GVL_GATEWAY.gvl
- GVL_HEALTH_BRIDGE.gvl
- GVL_IO.gvl
- GVL_PERSISTENT.gvl
- GVL_Retain.gvl
- GVL_STATE.gvl
- GVL_STATUS.gvl

### MAIN
- MAIN.st

### OTHER
- IValveController.st

### PROGRAM
- PRG_Heating.st
- PRG_IO_Read.st
- PRG_IO_Write.st
- PRG_Lighting.st
- PRG_PLC_A.st
- PRG_PLC_B.st
- PRG_Safety.st
- PRG_Security.st
- PRG_System.st
- PRG_Test.st
- PRG_Ventilation.st

## Program roots

- MAIN.st
- PRG_Heating.st
- PRG_IO_Read.st
- PRG_IO_Write.st
- PRG_Lighting.st
- PRG_PLC_A.st
- PRG_PLC_B.st
- PRG_Safety.st
- PRG_Security.st
- PRG_System.st
- PRG_Test.st
- PRG_Ventilation.st

## Zero incoming references

- E_Lifetime_Device_Type.dut [DUT_OR_ENUM]
- E_Outdoor_Mode.dut [DUT_OR_ENUM]
- E_Valve_Test_Result.dut [DUT_OR_ENUM]
- E_WEATHER_COMPENSATION_METHOD.dut [DUT_OR_ENUM]
- FB_CO_Detector.st [FUNCTION_BLOCK]
- FB_Calibration_Manager.st [FUNCTION_BLOCK]
- FB_DryRun_Assertion_Map.st [FUNCTION_BLOCK]
- FB_DryRun_Simulation_Harness.st [FUNCTION_BLOCK]
- FB_Emergency_Valve_Open.st [FUNCTION_BLOCK]
- FB_Exhaust_Ventilation_Controller.st [FUNCTION_BLOCK]
- FB_FloorHeating_Freeze_Protection.st [FUNCTION_BLOCK]
- FB_FloorHeating_Overheat_Protection.st [FUNCTION_BLOCK]
- FB_Gas_Methane_Detector.st [FUNCTION_BLOCK]
- FB_Gas_Valve_Controller.st [FUNCTION_BLOCK]
- FB_Maintenance_Access.st [FUNCTION_BLOCK]
- FB_Manifold_Pump_Controller.st [FUNCTION_BLOCK]
- FB_Manual_Valve_Control.st [FUNCTION_BLOCK]
- FB_Outdoor_Lighting_Controller.st [FUNCTION_BLOCK]
- FB_Pre_Departure_Heating.st [FUNCTION_BLOCK]
- FB_Presence_Simulator.st [FUNCTION_BLOCK]
- FB_Security_Alarm.st [FUNCTION_BLOCK]
- FB_Sensor_Analog_Processing.st [FUNCTION_BLOCK]
- FB_Sensor_Calibration.st [FUNCTION_BLOCK]
- FB_Sensor_Calibration_Processor.st [FUNCTION_BLOCK]
- FB_Sensor_Distribution.st [FUNCTION_BLOCK]
- FB_Smoke_Detector.st [FUNCTION_BLOCK]
- FB_State_Snapshot_Manager.st [FUNCTION_BLOCK]
- FB_State_Snapshot_NVRAM.st [FUNCTION_BLOCK]
- FB_Supply_Ventilation_Controller.st [FUNCTION_BLOCK]
- FB_Trend_Analyzer.st [FUNCTION_BLOCK]
- FB_Trend_Logger.st [FUNCTION_BLOCK]
- FB_Water_Valve_Controller.st [FUNCTION_BLOCK]
- FB_Zone_Access_Manager.st [FUNCTION_BLOCK]
- MAIN.st [MAIN]
- PRG_PLC_A.st [PROGRAM]
- PRG_PLC_B.st [PROGRAM]
- ST_Astro_Time.dut [DUT_OR_ENUM]
- ST_Debug_Log_Record.dut [DUT_OR_ENUM]
- ST_Debug_Logger_Config.dut [DUT_OR_ENUM]
- ST_FloorHeating_Global_Config.dut [DUT_OR_ENUM]
- ST_FloorHeating_Manifold_Config.dut [DUT_OR_ENUM]
- ST_Lifetime_Status.dut [DUT_OR_ENUM]
- ST_Maintenance_Access_Config.dut [DUT_OR_ENUM]
- ST_Rule.dut [DUT_OR_ENUM]
- ST_Scenario_Transition_Config.dut [DUT_OR_ENUM]
- ST_Security_Zone_State.dut [DUT_OR_ENUM]
- ST_System_State_Summary.dut [DUT_OR_ENUM]
- ST_Trend_Header.dut [DUT_OR_ENUM]
- ST_Trend_History_Record.dut [DUT_OR_ENUM]
- ST_TwoFactor_Data.dut [DUT_OR_ENUM]
- ST_Ventilation_Unit.dut [DUT_OR_ENUM]
- ST_Zone_Sensors.dut [DUT_OR_ENUM]

## Zero outgoing references

- E_ALERT_PRIORITY.dut [DUT_OR_ENUM]
- E_Debug_Log_Level.dut [DUT_OR_ENUM]
- E_Gateway_Command_Type.dut [DUT_OR_ENUM]
- E_Lifetime_Device_Type.dut [DUT_OR_ENUM]
- E_Outdoor_Mode.dut [DUT_OR_ENUM]
- E_PLC_ROLE.dut [DUT_OR_ENUM]
- E_Rule_Action_Type.dut [DUT_OR_ENUM]
- E_Rule_Comparison.dut [DUT_OR_ENUM]
- E_Rule_Condition_Type.dut [DUT_OR_ENUM]
- E_SCENARIO_SOURCE.dut [DUT_OR_ENUM]
- E_SCENARIO_TYPE.dut [DUT_OR_ENUM]
- E_SENSOR_TYPE.dut [DUT_OR_ENUM]
- E_System_Operating_Mode.dut [DUT_OR_ENUM]
- E_System_Root_Cause.dut [DUT_OR_ENUM]
- E_System_Severity.dut [DUT_OR_ENUM]
- E_Trend_Parameter_Type.dut [DUT_OR_ENUM]
- E_TwoFactor_Method.dut [DUT_OR_ENUM]
- E_VALVE_TYPE.dut [DUT_OR_ENUM]
- E_VENTILATION_LOCATION.dut [DUT_OR_ENUM]
- E_VENTILATION_UNIT_TYPE.dut [DUT_OR_ENUM]
- E_Valve_Test_Result.dut [DUT_OR_ENUM]
- E_WEATHER_COMPENSATION_METHOD.dut [DUT_OR_ENUM]
- E_Zone_Access_Level.dut [DUT_OR_ENUM]
- FB_Analog_Validator.st [FUNCTION_BLOCK]
- FB_CO_Detector.st [FUNCTION_BLOCK]
- FB_CRC32_Calculator.st [FUNCTION_BLOCK]
- FB_CoreKernel_Live_Observer.st [FUNCTION_BLOCK]
- FB_DryRun_Assertion_Map.st [FUNCTION_BLOCK]
- FB_DryRun_Simulation_Harness.st [FUNCTION_BLOCK]
- FB_Emergency_Valve_Open.st [FUNCTION_BLOCK]
- FB_Gas_Methane_Detector.st [FUNCTION_BLOCK]
- FB_IO_Module_Watchdog.st [FUNCTION_BLOCK]
- FB_Lifetime_Predictor.st [FUNCTION_BLOCK]
- FB_Manifold_Pump_Controller.st [FUNCTION_BLOCK]
- FB_Outdoor_Lighting_Controller.st [FUNCTION_BLOCK]
- FB_PID_Controller.st [FUNCTION_BLOCK]
- FB_PLC_Heartbeat.st [FUNCTION_BLOCK]
- FB_Random_Generator.st [FUNCTION_BLOCK]
- FB_SHA1.st [FUNCTION_BLOCK]
- FB_Safety_Manager.st [FUNCTION_BLOCK]
- FB_Scenario_Transition_Controller.st [FUNCTION_BLOCK]
- FB_Security_Alarm.st [FUNCTION_BLOCK]
- FB_Sensor_Calibration.st [FUNCTION_BLOCK]
- FB_Sensor_Distribution.st [FUNCTION_BLOCK]
- FB_Smoke_Detector.st [FUNCTION_BLOCK]
- FB_System_Timer.st [FUNCTION_BLOCK]
- FB_System_Timer_TOF.st [FUNCTION_BLOCK]
- FB_Watchdog.st [FUNCTION_BLOCK]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- GVL_HEALTH_BRIDGE.gvl [GLOBAL_VAR_LIST]
- IValveController.st [OTHER]
- ST_Astro_Time.dut [DUT_OR_ENUM]
- ST_Boiler_Status.dut [DUT_OR_ENUM]
- ST_Component_Maintenance.dut [DUT_OR_ENUM]
- ST_DHW_Config.dut [DUT_OR_ENUM]
- ST_DHW_Status.dut [DUT_OR_ENUM]
- ST_Device_Health.dut [DUT_OR_ENUM]
- ST_EVENT.dut [DUT_OR_ENUM]
- ST_FloorHeating_Circuit_Config.dut [DUT_OR_ENUM]
- ST_FloorHeating_Global_Config.dut [DUT_OR_ENUM]
- ST_Heating_Config.dut [DUT_OR_ENUM]
- ST_Lifetime_Status.dut [DUT_OR_ENUM]
- ST_Maintenance_Access_Config.dut [DUT_OR_ENUM]
- ST_Operator_Zone_Rights.dut [DUT_OR_ENUM]
- ST_Outdoor_Zone_Config.dut [DUT_OR_ENUM]
- ST_Owen_Analog_Value.dut [DUT_OR_ENUM]
- ST_Rule.dut [DUT_OR_ENUM]
- ST_Security_Zone_State.dut [DUT_OR_ENUM]
- ST_Tariff_Config.dut [DUT_OR_ENUM]
- ST_Trend_History_Record.dut [DUT_OR_ENUM]
- ST_Valve_Test_Config.dut [DUT_OR_ENUM]
- ST_Ventilation_Config.dut [DUT_OR_ENUM]
- ST_Ventilation_Unit.dut [DUT_OR_ENUM]

## Forward edges

### E_ALERT_PRIORITY.dut [DUT_OR_ENUM]
- (none)

### E_Debug_Log_Level.dut [DUT_OR_ENUM]
- (none)

### E_Gateway_Command_Type.dut [DUT_OR_ENUM]
- (none)

### E_Lifetime_Device_Type.dut [DUT_OR_ENUM]
- (none)

### E_Outdoor_Mode.dut [DUT_OR_ENUM]
- (none)

### E_PLC_ROLE.dut [DUT_OR_ENUM]
- (none)

### E_Rule_Action_Type.dut [DUT_OR_ENUM]
- (none)

### E_Rule_Comparison.dut [DUT_OR_ENUM]
- (none)

### E_Rule_Condition_Type.dut [DUT_OR_ENUM]
- (none)

### E_SCENARIO_SOURCE.dut [DUT_OR_ENUM]
- (none)

### E_SCENARIO_TYPE.dut [DUT_OR_ENUM]
- (none)

### E_SENSOR_TYPE.dut [DUT_OR_ENUM]
- (none)

### E_System_Operating_Mode.dut [DUT_OR_ENUM]
- (none)

### E_System_Root_Cause.dut [DUT_OR_ENUM]
- (none)

### E_System_Severity.dut [DUT_OR_ENUM]
- (none)

### E_Trend_Parameter_Type.dut [DUT_OR_ENUM]
- (none)

### E_TwoFactor_Method.dut [DUT_OR_ENUM]
- (none)

### E_VALVE_TYPE.dut [DUT_OR_ENUM]
- (none)

### E_VENTILATION_LOCATION.dut [DUT_OR_ENUM]
- (none)

### E_VENTILATION_UNIT_TYPE.dut [DUT_OR_ENUM]
- (none)

### E_Valve_Test_Result.dut [DUT_OR_ENUM]
- (none)

### E_WEATHER_COMPENSATION_METHOD.dut [DUT_OR_ENUM]
- (none)

### E_Zone_Access_Level.dut [DUT_OR_ENUM]
- (none)

### FB_AccessCode_Manager.st [FUNCTION_BLOCK]
- FB_CRC32_Calculator.st [FUNCTION_BLOCK]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]

### FB_Access_Control.st [FUNCTION_BLOCK]
- E_System_Operating_Mode.dut [DUT_OR_ENUM]
- FB_AccessCode_Manager.st [FUNCTION_BLOCK]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- ST_Security_Global_Config.dut [DUT_OR_ENUM]

### FB_Alarm_Manager.st [FUNCTION_BLOCK]
- E_ALERT_PRIORITY.dut [DUT_OR_ENUM]
- FB_System_Timer.st [FUNCTION_BLOCK]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- ST_Alarm_Record.dut [DUT_OR_ENUM]

### FB_Analog_Validator.st [FUNCTION_BLOCK]
- (none)

### FB_Astro_Timer.st [FUNCTION_BLOCK]
- GVL_STATUS.gvl [GLOBAL_VAR_LIST]

### FB_BlackBox_Recorder.st [FUNCTION_BLOCK]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- GVL_Retain.gvl [GLOBAL_VAR_LIST]
- ST_BlackBox_Record.dut [DUT_OR_ENUM]

### FB_Boiler_Cascade_Manager.st [FUNCTION_BLOCK]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]

### FB_Boiler_OpenTherm_Interface.st [FUNCTION_BLOCK]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]

### FB_CO_Detector.st [FUNCTION_BLOCK]
- (none)

### FB_CRC32_Calculator.st [FUNCTION_BLOCK]
- (none)

### FB_Calibration_Manager.st [FUNCTION_BLOCK]
- FB_System_Timer.st [FUNCTION_BLOCK]
- ST_Sensor_Calibration_Record.dut [DUT_OR_ENUM]

### FB_Command_Deduplication.st [FUNCTION_BLOCK]
- E_Gateway_Command_Type.dut [DUT_OR_ENUM]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]

### FB_CoreKernel_Live_Observer.st [FUNCTION_BLOCK]
- (none)

### FB_DHW_Manager.st [FUNCTION_BLOCK]
- E_System_Operating_Mode.dut [DUT_OR_ENUM]
- FB_Analog_Validator.st [FUNCTION_BLOCK]
- FB_System_Timer.st [FUNCTION_BLOCK]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- GVL_STATE.gvl [GLOBAL_VAR_LIST]
- ST_DHW_Config.dut [DUT_OR_ENUM]
- ST_DHW_Status.dut [DUT_OR_ENUM]

### FB_Device_Predictive_Diag.st [FUNCTION_BLOCK]
- FB_System_Timer.st [FUNCTION_BLOCK]
- ST_Device_Health.dut [DUT_OR_ENUM]

### FB_DryRun_Assertion_Map.st [FUNCTION_BLOCK]
- (none)

### FB_DryRun_Simulation_Harness.st [FUNCTION_BLOCK]
- (none)

### FB_Emergency_Valve_Open.st [FUNCTION_BLOCK]
- (none)

### FB_Exhaust_Ventilation_Controller.st [FUNCTION_BLOCK]
- ST_Ventilation_Unit_Config.dut [DUT_OR_ENUM]

### FB_Fault_Logger.st [FUNCTION_BLOCK]
- E_System_Root_Cause.dut [DUT_OR_ENUM]
- E_System_Severity.dut [DUT_OR_ENUM]

### FB_FloorHeating_Controller.st [FUNCTION_BLOCK]
- FB_PID_Controller.st [FUNCTION_BLOCK]
- ST_FloorHeating_Circuit_Config.dut [DUT_OR_ENUM]
- ST_Tariff_Config.dut [DUT_OR_ENUM]

### FB_FloorHeating_Freeze_Protection.st [FUNCTION_BLOCK]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]

### FB_FloorHeating_Overheat_Protection.st [FUNCTION_BLOCK]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]

### FB_Gas_Methane_Detector.st [FUNCTION_BLOCK]
- (none)

### FB_Gas_Smoke_Manager.st [FUNCTION_BLOCK]
- FB_System_Timer.st [FUNCTION_BLOCK]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- PRG_Safety.st [PROGRAM]

### FB_Gas_Valve_Controller.st [FUNCTION_BLOCK]
- IValveController.st [OTHER]
- ST_Gas_Valve_Configuration.dut [DUT_OR_ENUM]

### FB_Gateway_Interface.st [FUNCTION_BLOCK]
- E_Gateway_Command_Type.dut [DUT_OR_ENUM]
- E_PLC_ROLE.dut [DUT_OR_ENUM]
- E_SCENARIO_TYPE.dut [DUT_OR_ENUM]
- FB_CRC32_Calculator.st [FUNCTION_BLOCK]
- FB_Command_Deduplication.st [FUNCTION_BLOCK]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- ST_Gateway_Command.dut [DUT_OR_ENUM]

### FB_HMAC_SHA1.st [FUNCTION_BLOCK]
- FB_SHA1.st [FUNCTION_BLOCK]

### FB_HMI_Interface.st [FUNCTION_BLOCK]
- E_System_Root_Cause.dut [DUT_OR_ENUM]
- E_System_Severity.dut [DUT_OR_ENUM]

### FB_Heating_System_Manager.st [FUNCTION_BLOCK]
- E_Rule_Action_Type.dut [DUT_OR_ENUM]
- E_SCENARIO_TYPE.dut [DUT_OR_ENUM]
- E_System_Operating_Mode.dut [DUT_OR_ENUM]
- FB_Analog_Validator.st [FUNCTION_BLOCK]
- FB_Boiler_Cascade_Manager.st [FUNCTION_BLOCK]
- FB_Boiler_OpenTherm_Interface.st [FUNCTION_BLOCK]
- FB_Device_Predictive_Diag.st [FUNCTION_BLOCK]
- FB_FloorHeating_Controller.st [FUNCTION_BLOCK]
- FB_Lifetime_Predictor.st [FUNCTION_BLOCK]
- FB_PID_Controller.st [FUNCTION_BLOCK]
- FB_Scenario_Transition_Controller.st [FUNCTION_BLOCK]
- FB_System_Timer.st [FUNCTION_BLOCK]
- FB_Valve_Test_Manager.st [FUNCTION_BLOCK]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- GVL_Retain.gvl [GLOBAL_VAR_LIST]
- GVL_STATE.gvl [GLOBAL_VAR_LIST]
- ST_Boiler_Status.dut [DUT_OR_ENUM]
- ST_FloorHeating_Circuit_Config.dut [DUT_OR_ENUM]
- ST_Heating_Config.dut [DUT_OR_ENUM]
- ST_Manifold_Status.dut [DUT_OR_ENUM]
- ST_Rule_Action.dut [DUT_OR_ENUM]
- ST_Scenario_Config.dut [DUT_OR_ENUM]
- ST_Tariff_Config.dut [DUT_OR_ENUM]
- ST_Valve_Test_Config.dut [DUT_OR_ENUM]

### FB_History_Manager.st [FUNCTION_BLOCK]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- GVL_Retain.gvl [GLOBAL_VAR_LIST]
- ST_History_Record.dut [DUT_OR_ENUM]

### FB_IO_Module_Watchdog.st [FUNCTION_BLOCK]
- (none)

### FB_Lifetime_Predictor.st [FUNCTION_BLOCK]
- (none)

### FB_Lighting_Blinds_Manager.st [FUNCTION_BLOCK]
- E_Rule_Action_Type.dut [DUT_OR_ENUM]
- E_SCENARIO_TYPE.dut [DUT_OR_ENUM]
- E_System_Operating_Mode.dut [DUT_OR_ENUM]
- FB_Scenario_Transition_Controller.st [FUNCTION_BLOCK]
- FB_System_Timer_TOF.st [FUNCTION_BLOCK]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- GVL_STATE.gvl [GLOBAL_VAR_LIST]
- ST_Rule_Action.dut [DUT_OR_ENUM]
- ST_Scenario_Config.dut [DUT_OR_ENUM]

### FB_LogEvent.st [FUNCTION_BLOCK]
- GVL_EVENT.gvl [GLOBAL_VAR_LIST]

### FB_Maintenance_Access.st [FUNCTION_BLOCK]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]

### FB_Manifold_Pump_Controller.st [FUNCTION_BLOCK]
- (none)

### FB_Manual_Valve_Control.st [FUNCTION_BLOCK]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]

### FB_NVRAM_Manager.st [FUNCTION_BLOCK]
- GVL_Retain.gvl [GLOBAL_VAR_LIST]

### FB_Outdoor_Lighting_Controller.st [FUNCTION_BLOCK]
- (none)

### FB_PID_Controller.st [FUNCTION_BLOCK]
- (none)

### FB_PLC_Heartbeat.st [FUNCTION_BLOCK]
- (none)

### FB_Pre_Departure_Heating.st [FUNCTION_BLOCK]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]

### FB_Presence_Playback.st [FUNCTION_BLOCK]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- GVL_Retain.gvl [GLOBAL_VAR_LIST]

### FB_Presence_Simulator.st [FUNCTION_BLOCK]
- FB_Presence_Playback.st [FUNCTION_BLOCK]

### FB_Random_Generator.st [FUNCTION_BLOCK]
- (none)

### FB_Redundancy_Manager.st [FUNCTION_BLOCK]
- E_PLC_ROLE.dut [DUT_OR_ENUM]
- FB_PLC_Heartbeat.st [FUNCTION_BLOCK]
- FB_State_Replication.st [FUNCTION_BLOCK]
- FB_System_Timer.st [FUNCTION_BLOCK]
- ST_System_State_Snapshot.dut [DUT_OR_ENUM]

### FB_Rule_Engine.st [FUNCTION_BLOCK]
- E_Rule_Comparison.dut [DUT_OR_ENUM]
- E_Rule_Condition_Type.dut [DUT_OR_ENUM]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- ST_Rule_Action.dut [DUT_OR_ENUM]
- ST_User_Rule.dut [DUT_OR_ENUM]

### FB_SHA1.st [FUNCTION_BLOCK]
- (none)

### FB_Safety_Manager.st [FUNCTION_BLOCK]
- (none)

### FB_Scenario_Manager.st [FUNCTION_BLOCK]
- E_SCENARIO_TYPE.dut [DUT_OR_ENUM]
- E_System_Operating_Mode.dut [DUT_OR_ENUM]

### FB_Scenario_Transition_Controller.st [FUNCTION_BLOCK]
- (none)

### FB_Scenario_Transition_Guard.st [FUNCTION_BLOCK]
- E_SCENARIO_TYPE.dut [DUT_OR_ENUM]

### FB_Security_Alarm.st [FUNCTION_BLOCK]
- (none)

### FB_Security_System_Manager.st [FUNCTION_BLOCK]
- E_TwoFactor_Method.dut [DUT_OR_ENUM]
- FB_AccessCode_Manager.st [FUNCTION_BLOCK]
- FB_Astro_Timer.st [FUNCTION_BLOCK]
- FB_System_Timer.st [FUNCTION_BLOCK]
- FB_TwoFactor_Auth.st [FUNCTION_BLOCK]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- ST_Security_Global_Config.dut [DUT_OR_ENUM]

### FB_Sensor_Analog_Processing.st [FUNCTION_BLOCK]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]

### FB_Sensor_Calibration.st [FUNCTION_BLOCK]
- (none)

### FB_Sensor_Calibration_Processor.st [FUNCTION_BLOCK]
- ST_Sensor_Calibration_Record.dut [DUT_OR_ENUM]

### FB_Sensor_Distribution.st [FUNCTION_BLOCK]
- (none)

### FB_Simulation_Manager.st [FUNCTION_BLOCK]
- E_SCENARIO_TYPE.dut [DUT_OR_ENUM]
- FB_Random_Generator.st [FUNCTION_BLOCK]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- ST_Scenario_Config.dut [DUT_OR_ENUM]

### FB_Smoke_Detector.st [FUNCTION_BLOCK]
- (none)

### FB_Socket_Manager.st [FUNCTION_BLOCK]
- E_Rule_Action_Type.dut [DUT_OR_ENUM]
- E_SCENARIO_TYPE.dut [DUT_OR_ENUM]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- ST_Rule_Action.dut [DUT_OR_ENUM]

### FB_State_Manager.st [FUNCTION_BLOCK]
- E_System_Operating_Mode.dut [DUT_OR_ENUM]
- E_System_Root_Cause.dut [DUT_OR_ENUM]
- E_System_Severity.dut [DUT_OR_ENUM]

### FB_State_Replication.st [FUNCTION_BLOCK]
- E_PLC_ROLE.dut [DUT_OR_ENUM]
- ST_System_State_Snapshot.dut [DUT_OR_ENUM]

### FB_State_Snapshot_Manager.st [FUNCTION_BLOCK]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- ST_State_Snapshot.dut [DUT_OR_ENUM]

### FB_State_Snapshot_NVRAM.st [FUNCTION_BLOCK]
- ST_State_Snapshot.dut [DUT_OR_ENUM]

### FB_Supply_Ventilation_Controller.st [FUNCTION_BLOCK]
- FB_PID_Controller.st [FUNCTION_BLOCK]
- ST_Ventilation_Unit_Config.dut [DUT_OR_ENUM]

### FB_System_Health.st [FUNCTION_BLOCK]
- E_System_Root_Cause.dut [DUT_OR_ENUM]
- E_System_Severity.dut [DUT_OR_ENUM]

### FB_System_Timer.st [FUNCTION_BLOCK]
- (none)

### FB_System_Timer_TOF.st [FUNCTION_BLOCK]
- (none)

### FB_Trend_Analyzer.st [FUNCTION_BLOCK]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]

### FB_Trend_Logger.st [FUNCTION_BLOCK]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- ST_Trend_Config.dut [DUT_OR_ENUM]
- ST_Trend_Data.dut [DUT_OR_ENUM]

### FB_TwoFactor_Auth.st [FUNCTION_BLOCK]
- E_TwoFactor_Method.dut [DUT_OR_ENUM]
- FB_HMAC_SHA1.st [FUNCTION_BLOCK]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- ST_TwoFactor_Auth_State.dut [DUT_OR_ENUM]

### FB_Valve_Test_Manager.st [FUNCTION_BLOCK]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- GVL_Retain.gvl [GLOBAL_VAR_LIST]
- ST_Valve_Test_Config.dut [DUT_OR_ENUM]

### FB_Ventilation_System_Manager.st [FUNCTION_BLOCK]
- E_Rule_Action_Type.dut [DUT_OR_ENUM]
- E_SCENARIO_TYPE.dut [DUT_OR_ENUM]
- E_System_Operating_Mode.dut [DUT_OR_ENUM]
- FB_PID_Controller.st [FUNCTION_BLOCK]
- FB_System_Timer_TOF.st [FUNCTION_BLOCK]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- GVL_STATE.gvl [GLOBAL_VAR_LIST]
- ST_Rule_Action.dut [DUT_OR_ENUM]
- ST_Ventilation_Global_Config.dut [DUT_OR_ENUM]

### FB_Watchdog.st [FUNCTION_BLOCK]
- (none)

### FB_Water_Leakage_Manager.st [FUNCTION_BLOCK]
- FB_System_Timer.st [FUNCTION_BLOCK]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- PRG_Safety.st [PROGRAM]
- ST_Flood_Global_Config.dut [DUT_OR_ENUM]

### FB_Water_Valve_Controller.st [FUNCTION_BLOCK]
- IValveController.st [OTHER]

### FB_Zone_Access_Manager.st [FUNCTION_BLOCK]
- E_Zone_Access_Level.dut [DUT_OR_ENUM]
- ST_Operator_Zone_Rights.dut [DUT_OR_ENUM]

### GVL_ALARM.gvl [GLOBAL_VAR_LIST]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- ST_Alarm_Record.dut [DUT_OR_ENUM]

### GVL_COMMAND.gvl [GLOBAL_VAR_LIST]
- E_SCENARIO_TYPE.dut [DUT_OR_ENUM]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]

### GVL_CONFIG.gvl [GLOBAL_VAR_LIST]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- ST_DHW_Config.dut [DUT_OR_ENUM]
- ST_Flood_Config.dut [DUT_OR_ENUM]
- ST_Flood_Global_Config.dut [DUT_OR_ENUM]
- ST_FloorHeating_Circuit_Config.dut [DUT_OR_ENUM]
- ST_Gas_Valve_Configuration.dut [DUT_OR_ENUM]
- ST_Heating_Config.dut [DUT_OR_ENUM]
- ST_Outdoor_Zone_Config.dut [DUT_OR_ENUM]
- ST_Scenario_Config.dut [DUT_OR_ENUM]
- ST_Security_Global_Config.dut [DUT_OR_ENUM]
- ST_Sensor_Calibration_Record.dut [DUT_OR_ENUM]
- ST_Tariff_Config.dut [DUT_OR_ENUM]
- ST_User_Rule.dut [DUT_OR_ENUM]
- ST_Valve_Test_Config.dut [DUT_OR_ENUM]
- ST_Ventilation_Config.dut [DUT_OR_ENUM]
- ST_Ventilation_Global_Config.dut [DUT_OR_ENUM]
- ST_Ventilation_Unit_Config.dut [DUT_OR_ENUM]

### GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- (none)

### GVL_EVENT.gvl [GLOBAL_VAR_LIST]
- ST_EVENT.dut [DUT_OR_ENUM]

### GVL_GATEWAY.gvl [GLOBAL_VAR_LIST]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- ST_Gateway_Command.dut [DUT_OR_ENUM]

### GVL_HEALTH_BRIDGE.gvl [GLOBAL_VAR_LIST]
- (none)

### GVL_IO.gvl [GLOBAL_VAR_LIST]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- ST_Owen_Analog_Value.dut [DUT_OR_ENUM]

### GVL_PERSISTENT.gvl [GLOBAL_VAR_LIST]
- E_System_Operating_Mode.dut [DUT_OR_ENUM]

### GVL_Retain.gvl [GLOBAL_VAR_LIST]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- ST_BlackBox_Record.dut [DUT_OR_ENUM]
- ST_History_Record.dut [DUT_OR_ENUM]

### GVL_STATE.gvl [GLOBAL_VAR_LIST]
- E_System_Operating_Mode.dut [DUT_OR_ENUM]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- ST_Rule_Action.dut [DUT_OR_ENUM]

### GVL_STATUS.gvl [GLOBAL_VAR_LIST]
- E_SCENARIO_TYPE.dut [DUT_OR_ENUM]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- ST_Boiler_Status.dut [DUT_OR_ENUM]
- ST_DHW_Status.dut [DUT_OR_ENUM]
- ST_Manifold_Status.dut [DUT_OR_ENUM]
- ST_System_Diagnostics.dut [DUT_OR_ENUM]

### IValveController.st [OTHER]
- (none)

### MAIN.st [MAIN]
- PRG_Heating.st [PROGRAM]
- PRG_IO_Read.st [PROGRAM]
- PRG_IO_Write.st [PROGRAM]
- PRG_Lighting.st [PROGRAM]
- PRG_Safety.st [PROGRAM]
- PRG_Security.st [PROGRAM]
- PRG_System.st [PROGRAM]
- PRG_Test.st [PROGRAM]
- PRG_Ventilation.st [PROGRAM]

### PRG_Heating.st [PROGRAM]
- E_System_Operating_Mode.dut [DUT_OR_ENUM]
- FB_DHW_Manager.st [FUNCTION_BLOCK]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]
- GVL_COMMAND.gvl [GLOBAL_VAR_LIST]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- GVL_IO.gvl [GLOBAL_VAR_LIST]
- GVL_STATE.gvl [GLOBAL_VAR_LIST]
- GVL_STATUS.gvl [GLOBAL_VAR_LIST]

### PRG_IO_Read.st [PROGRAM]
- FB_IO_Module_Watchdog.st [FUNCTION_BLOCK]
- FB_System_Timer.st [FUNCTION_BLOCK]
- GVL_COMMAND.gvl [GLOBAL_VAR_LIST]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- GVL_IO.gvl [GLOBAL_VAR_LIST]
- GVL_STATE.gvl [GLOBAL_VAR_LIST]
- GVL_STATUS.gvl [GLOBAL_VAR_LIST]

### PRG_IO_Write.st [PROGRAM]
- GVL_ALARM.gvl [GLOBAL_VAR_LIST]
- GVL_COMMAND.gvl [GLOBAL_VAR_LIST]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- GVL_IO.gvl [GLOBAL_VAR_LIST]
- GVL_STATE.gvl [GLOBAL_VAR_LIST]
- GVL_STATUS.gvl [GLOBAL_VAR_LIST]

### PRG_Lighting.st [PROGRAM]
- FB_Lighting_Blinds_Manager.st [FUNCTION_BLOCK]
- FB_Socket_Manager.st [FUNCTION_BLOCK]
- GVL_ALARM.gvl [GLOBAL_VAR_LIST]
- GVL_COMMAND.gvl [GLOBAL_VAR_LIST]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]
- GVL_STATE.gvl [GLOBAL_VAR_LIST]
- GVL_STATUS.gvl [GLOBAL_VAR_LIST]

### PRG_PLC_A.st [PROGRAM]
- PRG_System.st [PROGRAM]

### PRG_PLC_B.st [PROGRAM]
- PRG_System.st [PROGRAM]

### PRG_Safety.st [PROGRAM]
- E_System_Operating_Mode.dut [DUT_OR_ENUM]
- FB_Gas_Smoke_Manager.st [FUNCTION_BLOCK]
- FB_Water_Leakage_Manager.st [FUNCTION_BLOCK]
- GVL_ALARM.gvl [GLOBAL_VAR_LIST]
- GVL_COMMAND.gvl [GLOBAL_VAR_LIST]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- GVL_HEALTH_BRIDGE.gvl [GLOBAL_VAR_LIST]
- GVL_STATE.gvl [GLOBAL_VAR_LIST]
- GVL_STATUS.gvl [GLOBAL_VAR_LIST]
- PRG_System.st [PROGRAM]

### PRG_Security.st [PROGRAM]
- FB_Access_Control.st [FUNCTION_BLOCK]
- FB_Security_System_Manager.st [FUNCTION_BLOCK]
- GVL_ALARM.gvl [GLOBAL_VAR_LIST]
- GVL_COMMAND.gvl [GLOBAL_VAR_LIST]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]
- GVL_Retain.gvl [GLOBAL_VAR_LIST]
- GVL_STATE.gvl [GLOBAL_VAR_LIST]
- GVL_STATUS.gvl [GLOBAL_VAR_LIST]

### PRG_System.st [PROGRAM]
- E_ALERT_PRIORITY.dut [DUT_OR_ENUM]
- E_PLC_ROLE.dut [DUT_OR_ENUM]
- E_Rule_Action_Type.dut [DUT_OR_ENUM]
- E_SCENARIO_SOURCE.dut [DUT_OR_ENUM]
- E_SCENARIO_TYPE.dut [DUT_OR_ENUM]
- E_System_Operating_Mode.dut [DUT_OR_ENUM]
- E_System_Root_Cause.dut [DUT_OR_ENUM]
- FB_Alarm_Manager.st [FUNCTION_BLOCK]
- FB_Astro_Timer.st [FUNCTION_BLOCK]
- FB_BlackBox_Recorder.st [FUNCTION_BLOCK]
- FB_CoreKernel_Live_Observer.st [FUNCTION_BLOCK]
- FB_Fault_Logger.st [FUNCTION_BLOCK]
- FB_Gateway_Interface.st [FUNCTION_BLOCK]
- FB_HMI_Interface.st [FUNCTION_BLOCK]
- FB_History_Manager.st [FUNCTION_BLOCK]
- FB_LogEvent.st [FUNCTION_BLOCK]
- FB_NVRAM_Manager.st [FUNCTION_BLOCK]
- FB_Redundancy_Manager.st [FUNCTION_BLOCK]
- FB_Rule_Engine.st [FUNCTION_BLOCK]
- FB_Safety_Manager.st [FUNCTION_BLOCK]
- FB_Scenario_Manager.st [FUNCTION_BLOCK]
- FB_Scenario_Transition_Guard.st [FUNCTION_BLOCK]
- FB_Simulation_Manager.st [FUNCTION_BLOCK]
- FB_State_Manager.st [FUNCTION_BLOCK]
- FB_System_Health.st [FUNCTION_BLOCK]
- FB_Watchdog.st [FUNCTION_BLOCK]
- GVL_ALARM.gvl [GLOBAL_VAR_LIST]
- GVL_COMMAND.gvl [GLOBAL_VAR_LIST]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- GVL_GATEWAY.gvl [GLOBAL_VAR_LIST]
- GVL_HEALTH_BRIDGE.gvl [GLOBAL_VAR_LIST]
- GVL_IO.gvl [GLOBAL_VAR_LIST]
- GVL_PERSISTENT.gvl [GLOBAL_VAR_LIST]
- GVL_Retain.gvl [GLOBAL_VAR_LIST]
- GVL_STATE.gvl [GLOBAL_VAR_LIST]
- GVL_STATUS.gvl [GLOBAL_VAR_LIST]
- ST_BlackBox_Record.dut [DUT_OR_ENUM]
- ST_History_Record.dut [DUT_OR_ENUM]
- ST_Persist.dut [DUT_OR_ENUM]
- ST_System_State_Snapshot.dut [DUT_OR_ENUM]

### PRG_Test.st [PROGRAM]
- FB_Analog_Validator.st [FUNCTION_BLOCK]
- FB_Random_Generator.st [FUNCTION_BLOCK]
- FB_TwoFactor_Auth.st [FUNCTION_BLOCK]

### PRG_Ventilation.st [PROGRAM]
- E_System_Operating_Mode.dut [DUT_OR_ENUM]
- FB_Ventilation_System_Manager.st [FUNCTION_BLOCK]
- GVL_COMMAND.gvl [GLOBAL_VAR_LIST]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- GVL_HEALTH_BRIDGE.gvl [GLOBAL_VAR_LIST]
- GVL_STATE.gvl [GLOBAL_VAR_LIST]
- GVL_STATUS.gvl [GLOBAL_VAR_LIST]

### ST_Alarm_Record.dut [DUT_OR_ENUM]
- E_ALERT_PRIORITY.dut [DUT_OR_ENUM]

### ST_Astro_Time.dut [DUT_OR_ENUM]
- (none)

### ST_BlackBox_Record.dut [DUT_OR_ENUM]
- E_System_Operating_Mode.dut [DUT_OR_ENUM]

### ST_Boiler_Status.dut [DUT_OR_ENUM]
- (none)

### ST_Component_Maintenance.dut [DUT_OR_ENUM]
- (none)

### ST_DHW_Config.dut [DUT_OR_ENUM]
- (none)

### ST_DHW_Status.dut [DUT_OR_ENUM]
- (none)

### ST_Debug_Log_Record.dut [DUT_OR_ENUM]
- E_Debug_Log_Level.dut [DUT_OR_ENUM]

### ST_Debug_Logger_Config.dut [DUT_OR_ENUM]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]

### ST_Device_Health.dut [DUT_OR_ENUM]
- (none)

### ST_EVENT.dut [DUT_OR_ENUM]
- (none)

### ST_Flood_Config.dut [DUT_OR_ENUM]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]

### ST_Flood_Global_Config.dut [DUT_OR_ENUM]
- E_VALVE_TYPE.dut [DUT_OR_ENUM]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]

### ST_FloorHeating_Circuit_Config.dut [DUT_OR_ENUM]
- (none)

### ST_FloorHeating_Global_Config.dut [DUT_OR_ENUM]
- (none)

### ST_FloorHeating_Manifold_Config.dut [DUT_OR_ENUM]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- ST_FloorHeating_Circuit_Config.dut [DUT_OR_ENUM]

### ST_Gas_Valve_Configuration.dut [DUT_OR_ENUM]
- E_VALVE_TYPE.dut [DUT_OR_ENUM]

### ST_Gateway_Command.dut [DUT_OR_ENUM]
- E_Gateway_Command_Type.dut [DUT_OR_ENUM]
- E_SCENARIO_TYPE.dut [DUT_OR_ENUM]

### ST_Heating_Config.dut [DUT_OR_ENUM]
- (none)

### ST_History_Record.dut [DUT_OR_ENUM]
- E_ALERT_PRIORITY.dut [DUT_OR_ENUM]

### ST_Lifetime_Status.dut [DUT_OR_ENUM]
- (none)

### ST_Maintenance_Access_Config.dut [DUT_OR_ENUM]
- (none)

### ST_Manifold_Status.dut [DUT_OR_ENUM]
- ST_Device_Health.dut [DUT_OR_ENUM]

### ST_Operator_Zone_Rights.dut [DUT_OR_ENUM]
- (none)

### ST_Outdoor_Zone_Config.dut [DUT_OR_ENUM]
- (none)

### ST_Owen_Analog_Value.dut [DUT_OR_ENUM]
- (none)

### ST_Persist.dut [DUT_OR_ENUM]
- E_System_Operating_Mode.dut [DUT_OR_ENUM]

### ST_Rule.dut [DUT_OR_ENUM]
- (none)

### ST_Rule_Action.dut [DUT_OR_ENUM]
- E_Rule_Action_Type.dut [DUT_OR_ENUM]

### ST_Scenario_Config.dut [DUT_OR_ENUM]
- E_SCENARIO_TYPE.dut [DUT_OR_ENUM]

### ST_Scenario_Transition_Config.dut [DUT_OR_ENUM]
- E_SCENARIO_TYPE.dut [DUT_OR_ENUM]

### ST_Security_Global_Config.dut [DUT_OR_ENUM]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]

### ST_Security_Zone_State.dut [DUT_OR_ENUM]
- (none)

### ST_Sensor_Calibration_Record.dut [DUT_OR_ENUM]
- E_SENSOR_TYPE.dut [DUT_OR_ENUM]

### ST_State_Snapshot.dut [DUT_OR_ENUM]
- E_SCENARIO_TYPE.dut [DUT_OR_ENUM]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]

### ST_System_Diagnostics.dut [DUT_OR_ENUM]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]

### ST_System_State_Snapshot.dut [DUT_OR_ENUM]
- E_SCENARIO_TYPE.dut [DUT_OR_ENUM]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]

### ST_System_State_Summary.dut [DUT_OR_ENUM]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]

### ST_Tariff_Config.dut [DUT_OR_ENUM]
- (none)

### ST_Trend_Config.dut [DUT_OR_ENUM]
- E_Trend_Parameter_Type.dut [DUT_OR_ENUM]

### ST_Trend_Data.dut [DUT_OR_ENUM]
- ST_Trend_Config.dut [DUT_OR_ENUM]

### ST_Trend_Header.dut [DUT_OR_ENUM]
- E_Trend_Parameter_Type.dut [DUT_OR_ENUM]

### ST_Trend_History_Record.dut [DUT_OR_ENUM]
- (none)

### ST_TwoFactor_Auth_State.dut [DUT_OR_ENUM]
- E_TwoFactor_Method.dut [DUT_OR_ENUM]

### ST_TwoFactor_Data.dut [DUT_OR_ENUM]
- E_TwoFactor_Method.dut [DUT_OR_ENUM]

### ST_User_Rule.dut [DUT_OR_ENUM]
- E_Rule_Action_Type.dut [DUT_OR_ENUM]
- E_Rule_Comparison.dut [DUT_OR_ENUM]
- E_Rule_Condition_Type.dut [DUT_OR_ENUM]

### ST_Valve_Test_Config.dut [DUT_OR_ENUM]
- (none)

### ST_Ventilation_Config.dut [DUT_OR_ENUM]
- (none)

### ST_Ventilation_Global_Config.dut [DUT_OR_ENUM]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- ST_Ventilation_Scenario_Mode.dut [DUT_OR_ENUM]

### ST_Ventilation_Scenario_Mode.dut [DUT_OR_ENUM]
- GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]

### ST_Ventilation_Unit.dut [DUT_OR_ENUM]
- (none)

### ST_Ventilation_Unit_Config.dut [DUT_OR_ENUM]
- E_VENTILATION_LOCATION.dut [DUT_OR_ENUM]
- E_VENTILATION_UNIT_TYPE.dut [DUT_OR_ENUM]

### ST_Zone_Sensors.dut [DUT_OR_ENUM]
- ST_Component_Maintenance.dut [DUT_OR_ENUM]

## Reverse edges

### E_ALERT_PRIORITY.dut [DUT_OR_ENUM]
- FB_Alarm_Manager.st [FUNCTION_BLOCK]
- PRG_System.st [PROGRAM]
- ST_Alarm_Record.dut [DUT_OR_ENUM]
- ST_History_Record.dut [DUT_OR_ENUM]

### E_Debug_Log_Level.dut [DUT_OR_ENUM]
- ST_Debug_Log_Record.dut [DUT_OR_ENUM]

### E_Gateway_Command_Type.dut [DUT_OR_ENUM]
- FB_Command_Deduplication.st [FUNCTION_BLOCK]
- FB_Gateway_Interface.st [FUNCTION_BLOCK]
- ST_Gateway_Command.dut [DUT_OR_ENUM]

### E_Lifetime_Device_Type.dut [DUT_OR_ENUM]
- (none)

### E_Outdoor_Mode.dut [DUT_OR_ENUM]
- (none)

### E_PLC_ROLE.dut [DUT_OR_ENUM]
- FB_Gateway_Interface.st [FUNCTION_BLOCK]
- FB_Redundancy_Manager.st [FUNCTION_BLOCK]
- FB_State_Replication.st [FUNCTION_BLOCK]
- PRG_System.st [PROGRAM]

### E_Rule_Action_Type.dut [DUT_OR_ENUM]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]
- FB_Lighting_Blinds_Manager.st [FUNCTION_BLOCK]
- FB_Socket_Manager.st [FUNCTION_BLOCK]
- FB_Ventilation_System_Manager.st [FUNCTION_BLOCK]
- PRG_System.st [PROGRAM]
- ST_Rule_Action.dut [DUT_OR_ENUM]
- ST_User_Rule.dut [DUT_OR_ENUM]

### E_Rule_Comparison.dut [DUT_OR_ENUM]
- FB_Rule_Engine.st [FUNCTION_BLOCK]
- ST_User_Rule.dut [DUT_OR_ENUM]

### E_Rule_Condition_Type.dut [DUT_OR_ENUM]
- FB_Rule_Engine.st [FUNCTION_BLOCK]
- ST_User_Rule.dut [DUT_OR_ENUM]

### E_SCENARIO_SOURCE.dut [DUT_OR_ENUM]
- PRG_System.st [PROGRAM]

### E_SCENARIO_TYPE.dut [DUT_OR_ENUM]
- FB_Gateway_Interface.st [FUNCTION_BLOCK]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]
- FB_Lighting_Blinds_Manager.st [FUNCTION_BLOCK]
- FB_Scenario_Manager.st [FUNCTION_BLOCK]
- FB_Scenario_Transition_Guard.st [FUNCTION_BLOCK]
- FB_Simulation_Manager.st [FUNCTION_BLOCK]
- FB_Socket_Manager.st [FUNCTION_BLOCK]
- FB_Ventilation_System_Manager.st [FUNCTION_BLOCK]
- GVL_COMMAND.gvl [GLOBAL_VAR_LIST]
- GVL_STATUS.gvl [GLOBAL_VAR_LIST]
- PRG_System.st [PROGRAM]
- ST_Gateway_Command.dut [DUT_OR_ENUM]
- ST_Scenario_Config.dut [DUT_OR_ENUM]
- ST_Scenario_Transition_Config.dut [DUT_OR_ENUM]
- ST_State_Snapshot.dut [DUT_OR_ENUM]
- ST_System_State_Snapshot.dut [DUT_OR_ENUM]

### E_SENSOR_TYPE.dut [DUT_OR_ENUM]
- ST_Sensor_Calibration_Record.dut [DUT_OR_ENUM]

### E_System_Operating_Mode.dut [DUT_OR_ENUM]
- FB_Access_Control.st [FUNCTION_BLOCK]
- FB_DHW_Manager.st [FUNCTION_BLOCK]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]
- FB_Lighting_Blinds_Manager.st [FUNCTION_BLOCK]
- FB_Scenario_Manager.st [FUNCTION_BLOCK]
- FB_State_Manager.st [FUNCTION_BLOCK]
- FB_Ventilation_System_Manager.st [FUNCTION_BLOCK]
- GVL_PERSISTENT.gvl [GLOBAL_VAR_LIST]
- GVL_STATE.gvl [GLOBAL_VAR_LIST]
- PRG_Heating.st [PROGRAM]
- PRG_Safety.st [PROGRAM]
- PRG_System.st [PROGRAM]
- PRG_Ventilation.st [PROGRAM]
- ST_BlackBox_Record.dut [DUT_OR_ENUM]
- ST_Persist.dut [DUT_OR_ENUM]

### E_System_Root_Cause.dut [DUT_OR_ENUM]
- FB_Fault_Logger.st [FUNCTION_BLOCK]
- FB_HMI_Interface.st [FUNCTION_BLOCK]
- FB_State_Manager.st [FUNCTION_BLOCK]
- FB_System_Health.st [FUNCTION_BLOCK]
- PRG_System.st [PROGRAM]

### E_System_Severity.dut [DUT_OR_ENUM]
- FB_Fault_Logger.st [FUNCTION_BLOCK]
- FB_HMI_Interface.st [FUNCTION_BLOCK]
- FB_State_Manager.st [FUNCTION_BLOCK]
- FB_System_Health.st [FUNCTION_BLOCK]

### E_Trend_Parameter_Type.dut [DUT_OR_ENUM]
- ST_Trend_Config.dut [DUT_OR_ENUM]
- ST_Trend_Header.dut [DUT_OR_ENUM]

### E_TwoFactor_Method.dut [DUT_OR_ENUM]
- FB_Security_System_Manager.st [FUNCTION_BLOCK]
- FB_TwoFactor_Auth.st [FUNCTION_BLOCK]
- ST_TwoFactor_Auth_State.dut [DUT_OR_ENUM]
- ST_TwoFactor_Data.dut [DUT_OR_ENUM]

### E_VALVE_TYPE.dut [DUT_OR_ENUM]
- ST_Flood_Global_Config.dut [DUT_OR_ENUM]
- ST_Gas_Valve_Configuration.dut [DUT_OR_ENUM]

### E_VENTILATION_LOCATION.dut [DUT_OR_ENUM]
- ST_Ventilation_Unit_Config.dut [DUT_OR_ENUM]

### E_VENTILATION_UNIT_TYPE.dut [DUT_OR_ENUM]
- ST_Ventilation_Unit_Config.dut [DUT_OR_ENUM]

### E_Valve_Test_Result.dut [DUT_OR_ENUM]
- (none)

### E_WEATHER_COMPENSATION_METHOD.dut [DUT_OR_ENUM]
- (none)

### E_Zone_Access_Level.dut [DUT_OR_ENUM]
- FB_Zone_Access_Manager.st [FUNCTION_BLOCK]

### FB_AccessCode_Manager.st [FUNCTION_BLOCK]
- FB_Access_Control.st [FUNCTION_BLOCK]
- FB_Security_System_Manager.st [FUNCTION_BLOCK]

### FB_Access_Control.st [FUNCTION_BLOCK]
- PRG_Security.st [PROGRAM]

### FB_Alarm_Manager.st [FUNCTION_BLOCK]
- PRG_System.st [PROGRAM]

### FB_Analog_Validator.st [FUNCTION_BLOCK]
- FB_DHW_Manager.st [FUNCTION_BLOCK]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]
- PRG_Test.st [PROGRAM]

### FB_Astro_Timer.st [FUNCTION_BLOCK]
- FB_Security_System_Manager.st [FUNCTION_BLOCK]
- PRG_System.st [PROGRAM]

### FB_BlackBox_Recorder.st [FUNCTION_BLOCK]
- PRG_System.st [PROGRAM]

### FB_Boiler_Cascade_Manager.st [FUNCTION_BLOCK]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]

### FB_Boiler_OpenTherm_Interface.st [FUNCTION_BLOCK]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]

### FB_CO_Detector.st [FUNCTION_BLOCK]
- (none)

### FB_CRC32_Calculator.st [FUNCTION_BLOCK]
- FB_AccessCode_Manager.st [FUNCTION_BLOCK]
- FB_Gateway_Interface.st [FUNCTION_BLOCK]

### FB_Calibration_Manager.st [FUNCTION_BLOCK]
- (none)

### FB_Command_Deduplication.st [FUNCTION_BLOCK]
- FB_Gateway_Interface.st [FUNCTION_BLOCK]

### FB_CoreKernel_Live_Observer.st [FUNCTION_BLOCK]
- PRG_System.st [PROGRAM]

### FB_DHW_Manager.st [FUNCTION_BLOCK]
- PRG_Heating.st [PROGRAM]

### FB_Device_Predictive_Diag.st [FUNCTION_BLOCK]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]

### FB_DryRun_Assertion_Map.st [FUNCTION_BLOCK]
- (none)

### FB_DryRun_Simulation_Harness.st [FUNCTION_BLOCK]
- (none)

### FB_Emergency_Valve_Open.st [FUNCTION_BLOCK]
- (none)

### FB_Exhaust_Ventilation_Controller.st [FUNCTION_BLOCK]
- (none)

### FB_Fault_Logger.st [FUNCTION_BLOCK]
- PRG_System.st [PROGRAM]

### FB_FloorHeating_Controller.st [FUNCTION_BLOCK]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]

### FB_FloorHeating_Freeze_Protection.st [FUNCTION_BLOCK]
- (none)

### FB_FloorHeating_Overheat_Protection.st [FUNCTION_BLOCK]
- (none)

### FB_Gas_Methane_Detector.st [FUNCTION_BLOCK]
- (none)

### FB_Gas_Smoke_Manager.st [FUNCTION_BLOCK]
- PRG_Safety.st [PROGRAM]

### FB_Gas_Valve_Controller.st [FUNCTION_BLOCK]
- (none)

### FB_Gateway_Interface.st [FUNCTION_BLOCK]
- PRG_System.st [PROGRAM]

### FB_HMAC_SHA1.st [FUNCTION_BLOCK]
- FB_TwoFactor_Auth.st [FUNCTION_BLOCK]

### FB_HMI_Interface.st [FUNCTION_BLOCK]
- PRG_System.st [PROGRAM]

### FB_Heating_System_Manager.st [FUNCTION_BLOCK]
- PRG_Heating.st [PROGRAM]

### FB_History_Manager.st [FUNCTION_BLOCK]
- PRG_System.st [PROGRAM]

### FB_IO_Module_Watchdog.st [FUNCTION_BLOCK]
- PRG_IO_Read.st [PROGRAM]

### FB_Lifetime_Predictor.st [FUNCTION_BLOCK]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]

### FB_Lighting_Blinds_Manager.st [FUNCTION_BLOCK]
- PRG_Lighting.st [PROGRAM]

### FB_LogEvent.st [FUNCTION_BLOCK]
- PRG_System.st [PROGRAM]

### FB_Maintenance_Access.st [FUNCTION_BLOCK]
- (none)

### FB_Manifold_Pump_Controller.st [FUNCTION_BLOCK]
- (none)

### FB_Manual_Valve_Control.st [FUNCTION_BLOCK]
- (none)

### FB_NVRAM_Manager.st [FUNCTION_BLOCK]
- PRG_System.st [PROGRAM]

### FB_Outdoor_Lighting_Controller.st [FUNCTION_BLOCK]
- (none)

### FB_PID_Controller.st [FUNCTION_BLOCK]
- FB_FloorHeating_Controller.st [FUNCTION_BLOCK]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]
- FB_Supply_Ventilation_Controller.st [FUNCTION_BLOCK]
- FB_Ventilation_System_Manager.st [FUNCTION_BLOCK]

### FB_PLC_Heartbeat.st [FUNCTION_BLOCK]
- FB_Redundancy_Manager.st [FUNCTION_BLOCK]

### FB_Pre_Departure_Heating.st [FUNCTION_BLOCK]
- (none)

### FB_Presence_Playback.st [FUNCTION_BLOCK]
- FB_Presence_Simulator.st [FUNCTION_BLOCK]

### FB_Presence_Simulator.st [FUNCTION_BLOCK]
- (none)

### FB_Random_Generator.st [FUNCTION_BLOCK]
- FB_Simulation_Manager.st [FUNCTION_BLOCK]
- PRG_Test.st [PROGRAM]

### FB_Redundancy_Manager.st [FUNCTION_BLOCK]
- PRG_System.st [PROGRAM]

### FB_Rule_Engine.st [FUNCTION_BLOCK]
- PRG_System.st [PROGRAM]

### FB_SHA1.st [FUNCTION_BLOCK]
- FB_HMAC_SHA1.st [FUNCTION_BLOCK]

### FB_Safety_Manager.st [FUNCTION_BLOCK]
- PRG_System.st [PROGRAM]

### FB_Scenario_Manager.st [FUNCTION_BLOCK]
- PRG_System.st [PROGRAM]

### FB_Scenario_Transition_Controller.st [FUNCTION_BLOCK]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]
- FB_Lighting_Blinds_Manager.st [FUNCTION_BLOCK]

### FB_Scenario_Transition_Guard.st [FUNCTION_BLOCK]
- PRG_System.st [PROGRAM]

### FB_Security_Alarm.st [FUNCTION_BLOCK]
- (none)

### FB_Security_System_Manager.st [FUNCTION_BLOCK]
- PRG_Security.st [PROGRAM]

### FB_Sensor_Analog_Processing.st [FUNCTION_BLOCK]
- (none)

### FB_Sensor_Calibration.st [FUNCTION_BLOCK]
- (none)

### FB_Sensor_Calibration_Processor.st [FUNCTION_BLOCK]
- (none)

### FB_Sensor_Distribution.st [FUNCTION_BLOCK]
- (none)

### FB_Simulation_Manager.st [FUNCTION_BLOCK]
- PRG_System.st [PROGRAM]

### FB_Smoke_Detector.st [FUNCTION_BLOCK]
- (none)

### FB_Socket_Manager.st [FUNCTION_BLOCK]
- PRG_Lighting.st [PROGRAM]

### FB_State_Manager.st [FUNCTION_BLOCK]
- PRG_System.st [PROGRAM]

### FB_State_Replication.st [FUNCTION_BLOCK]
- FB_Redundancy_Manager.st [FUNCTION_BLOCK]

### FB_State_Snapshot_Manager.st [FUNCTION_BLOCK]
- (none)

### FB_State_Snapshot_NVRAM.st [FUNCTION_BLOCK]
- (none)

### FB_Supply_Ventilation_Controller.st [FUNCTION_BLOCK]
- (none)

### FB_System_Health.st [FUNCTION_BLOCK]
- PRG_System.st [PROGRAM]

### FB_System_Timer.st [FUNCTION_BLOCK]
- FB_Alarm_Manager.st [FUNCTION_BLOCK]
- FB_Calibration_Manager.st [FUNCTION_BLOCK]
- FB_DHW_Manager.st [FUNCTION_BLOCK]
- FB_Device_Predictive_Diag.st [FUNCTION_BLOCK]
- FB_Gas_Smoke_Manager.st [FUNCTION_BLOCK]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]
- FB_Redundancy_Manager.st [FUNCTION_BLOCK]
- FB_Security_System_Manager.st [FUNCTION_BLOCK]
- FB_Water_Leakage_Manager.st [FUNCTION_BLOCK]
- PRG_IO_Read.st [PROGRAM]

### FB_System_Timer_TOF.st [FUNCTION_BLOCK]
- FB_Lighting_Blinds_Manager.st [FUNCTION_BLOCK]
- FB_Ventilation_System_Manager.st [FUNCTION_BLOCK]

### FB_Trend_Analyzer.st [FUNCTION_BLOCK]
- (none)

### FB_Trend_Logger.st [FUNCTION_BLOCK]
- (none)

### FB_TwoFactor_Auth.st [FUNCTION_BLOCK]
- FB_Security_System_Manager.st [FUNCTION_BLOCK]
- PRG_Test.st [PROGRAM]

### FB_Valve_Test_Manager.st [FUNCTION_BLOCK]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]

### FB_Ventilation_System_Manager.st [FUNCTION_BLOCK]
- PRG_Ventilation.st [PROGRAM]

### FB_Watchdog.st [FUNCTION_BLOCK]
- PRG_System.st [PROGRAM]

### FB_Water_Leakage_Manager.st [FUNCTION_BLOCK]
- PRG_Safety.st [PROGRAM]

### FB_Water_Valve_Controller.st [FUNCTION_BLOCK]
- (none)

### FB_Zone_Access_Manager.st [FUNCTION_BLOCK]
- (none)

### GVL_ALARM.gvl [GLOBAL_VAR_LIST]
- PRG_IO_Write.st [PROGRAM]
- PRG_Lighting.st [PROGRAM]
- PRG_Safety.st [PROGRAM]
- PRG_Security.st [PROGRAM]
- PRG_System.st [PROGRAM]

### GVL_COMMAND.gvl [GLOBAL_VAR_LIST]
- PRG_Heating.st [PROGRAM]
- PRG_IO_Read.st [PROGRAM]
- PRG_IO_Write.st [PROGRAM]
- PRG_Lighting.st [PROGRAM]
- PRG_Safety.st [PROGRAM]
- PRG_Security.st [PROGRAM]
- PRG_System.st [PROGRAM]
- PRG_Ventilation.st [PROGRAM]

### GVL_CONFIG.gvl [GLOBAL_VAR_LIST]
- FB_Access_Control.st [FUNCTION_BLOCK]
- FB_DHW_Manager.st [FUNCTION_BLOCK]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]
- FB_TwoFactor_Auth.st [FUNCTION_BLOCK]
- PRG_Heating.st [PROGRAM]
- PRG_IO_Read.st [PROGRAM]
- PRG_Lighting.st [PROGRAM]
- PRG_Safety.st [PROGRAM]
- PRG_Security.st [PROGRAM]
- PRG_System.st [PROGRAM]
- PRG_Ventilation.st [PROGRAM]

### GVL_CONSTANTS.gvl [GLOBAL_VAR_LIST]
- FB_AccessCode_Manager.st [FUNCTION_BLOCK]
- FB_Access_Control.st [FUNCTION_BLOCK]
- FB_Alarm_Manager.st [FUNCTION_BLOCK]
- FB_BlackBox_Recorder.st [FUNCTION_BLOCK]
- FB_Boiler_Cascade_Manager.st [FUNCTION_BLOCK]
- FB_Boiler_OpenTherm_Interface.st [FUNCTION_BLOCK]
- FB_Command_Deduplication.st [FUNCTION_BLOCK]
- FB_DHW_Manager.st [FUNCTION_BLOCK]
- FB_FloorHeating_Freeze_Protection.st [FUNCTION_BLOCK]
- FB_FloorHeating_Overheat_Protection.st [FUNCTION_BLOCK]
- FB_Gas_Smoke_Manager.st [FUNCTION_BLOCK]
- FB_Gateway_Interface.st [FUNCTION_BLOCK]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]
- FB_History_Manager.st [FUNCTION_BLOCK]
- FB_Lighting_Blinds_Manager.st [FUNCTION_BLOCK]
- FB_Maintenance_Access.st [FUNCTION_BLOCK]
- FB_Manual_Valve_Control.st [FUNCTION_BLOCK]
- FB_Pre_Departure_Heating.st [FUNCTION_BLOCK]
- FB_Presence_Playback.st [FUNCTION_BLOCK]
- FB_Rule_Engine.st [FUNCTION_BLOCK]
- FB_Security_System_Manager.st [FUNCTION_BLOCK]
- FB_Sensor_Analog_Processing.st [FUNCTION_BLOCK]
- FB_Simulation_Manager.st [FUNCTION_BLOCK]
- FB_Socket_Manager.st [FUNCTION_BLOCK]
- FB_State_Snapshot_Manager.st [FUNCTION_BLOCK]
- FB_Trend_Analyzer.st [FUNCTION_BLOCK]
- FB_Trend_Logger.st [FUNCTION_BLOCK]
- FB_TwoFactor_Auth.st [FUNCTION_BLOCK]
- FB_Valve_Test_Manager.st [FUNCTION_BLOCK]
- FB_Ventilation_System_Manager.st [FUNCTION_BLOCK]
- FB_Water_Leakage_Manager.st [FUNCTION_BLOCK]
- GVL_ALARM.gvl [GLOBAL_VAR_LIST]
- GVL_COMMAND.gvl [GLOBAL_VAR_LIST]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]
- GVL_GATEWAY.gvl [GLOBAL_VAR_LIST]
- GVL_IO.gvl [GLOBAL_VAR_LIST]
- GVL_Retain.gvl [GLOBAL_VAR_LIST]
- GVL_STATE.gvl [GLOBAL_VAR_LIST]
- GVL_STATUS.gvl [GLOBAL_VAR_LIST]
- PRG_Heating.st [PROGRAM]
- PRG_IO_Read.st [PROGRAM]
- PRG_IO_Write.st [PROGRAM]
- PRG_Safety.st [PROGRAM]
- PRG_System.st [PROGRAM]
- PRG_Ventilation.st [PROGRAM]
- ST_Debug_Logger_Config.dut [DUT_OR_ENUM]
- ST_Flood_Config.dut [DUT_OR_ENUM]
- ST_Flood_Global_Config.dut [DUT_OR_ENUM]
- ST_FloorHeating_Manifold_Config.dut [DUT_OR_ENUM]
- ST_Security_Global_Config.dut [DUT_OR_ENUM]
- ST_State_Snapshot.dut [DUT_OR_ENUM]
- ST_System_Diagnostics.dut [DUT_OR_ENUM]
- ST_System_State_Snapshot.dut [DUT_OR_ENUM]
- ST_System_State_Summary.dut [DUT_OR_ENUM]
- ST_Ventilation_Global_Config.dut [DUT_OR_ENUM]
- ST_Ventilation_Scenario_Mode.dut [DUT_OR_ENUM]

### GVL_EVENT.gvl [GLOBAL_VAR_LIST]
- FB_LogEvent.st [FUNCTION_BLOCK]

### GVL_GATEWAY.gvl [GLOBAL_VAR_LIST]
- PRG_System.st [PROGRAM]

### GVL_HEALTH_BRIDGE.gvl [GLOBAL_VAR_LIST]
- PRG_Safety.st [PROGRAM]
- PRG_System.st [PROGRAM]
- PRG_Ventilation.st [PROGRAM]

### GVL_IO.gvl [GLOBAL_VAR_LIST]
- PRG_Heating.st [PROGRAM]
- PRG_IO_Read.st [PROGRAM]
- PRG_IO_Write.st [PROGRAM]
- PRG_System.st [PROGRAM]

### GVL_PERSISTENT.gvl [GLOBAL_VAR_LIST]
- PRG_System.st [PROGRAM]

### GVL_Retain.gvl [GLOBAL_VAR_LIST]
- FB_BlackBox_Recorder.st [FUNCTION_BLOCK]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]
- FB_History_Manager.st [FUNCTION_BLOCK]
- FB_NVRAM_Manager.st [FUNCTION_BLOCK]
- FB_Presence_Playback.st [FUNCTION_BLOCK]
- FB_Valve_Test_Manager.st [FUNCTION_BLOCK]
- PRG_Security.st [PROGRAM]
- PRG_System.st [PROGRAM]

### GVL_STATE.gvl [GLOBAL_VAR_LIST]
- FB_DHW_Manager.st [FUNCTION_BLOCK]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]
- FB_Lighting_Blinds_Manager.st [FUNCTION_BLOCK]
- FB_Ventilation_System_Manager.st [FUNCTION_BLOCK]
- PRG_Heating.st [PROGRAM]
- PRG_IO_Read.st [PROGRAM]
- PRG_IO_Write.st [PROGRAM]
- PRG_Lighting.st [PROGRAM]
- PRG_Safety.st [PROGRAM]
- PRG_Security.st [PROGRAM]
- PRG_System.st [PROGRAM]
- PRG_Ventilation.st [PROGRAM]

### GVL_STATUS.gvl [GLOBAL_VAR_LIST]
- FB_Astro_Timer.st [FUNCTION_BLOCK]
- PRG_Heating.st [PROGRAM]
- PRG_IO_Read.st [PROGRAM]
- PRG_IO_Write.st [PROGRAM]
- PRG_Lighting.st [PROGRAM]
- PRG_Safety.st [PROGRAM]
- PRG_Security.st [PROGRAM]
- PRG_System.st [PROGRAM]
- PRG_Ventilation.st [PROGRAM]

### IValveController.st [OTHER]
- FB_Gas_Valve_Controller.st [FUNCTION_BLOCK]
- FB_Water_Valve_Controller.st [FUNCTION_BLOCK]

### MAIN.st [MAIN]
- (none)

### PRG_Heating.st [PROGRAM]
- MAIN.st [MAIN]

### PRG_IO_Read.st [PROGRAM]
- MAIN.st [MAIN]

### PRG_IO_Write.st [PROGRAM]
- MAIN.st [MAIN]

### PRG_Lighting.st [PROGRAM]
- MAIN.st [MAIN]

### PRG_PLC_A.st [PROGRAM]
- (none)

### PRG_PLC_B.st [PROGRAM]
- (none)

### PRG_Safety.st [PROGRAM]
- FB_Gas_Smoke_Manager.st [FUNCTION_BLOCK]
- FB_Water_Leakage_Manager.st [FUNCTION_BLOCK]
- MAIN.st [MAIN]

### PRG_Security.st [PROGRAM]
- MAIN.st [MAIN]

### PRG_System.st [PROGRAM]
- MAIN.st [MAIN]
- PRG_PLC_A.st [PROGRAM]
- PRG_PLC_B.st [PROGRAM]
- PRG_Safety.st [PROGRAM]

### PRG_Test.st [PROGRAM]
- MAIN.st [MAIN]

### PRG_Ventilation.st [PROGRAM]
- MAIN.st [MAIN]

### ST_Alarm_Record.dut [DUT_OR_ENUM]
- FB_Alarm_Manager.st [FUNCTION_BLOCK]
- GVL_ALARM.gvl [GLOBAL_VAR_LIST]

### ST_Astro_Time.dut [DUT_OR_ENUM]
- (none)

### ST_BlackBox_Record.dut [DUT_OR_ENUM]
- FB_BlackBox_Recorder.st [FUNCTION_BLOCK]
- GVL_Retain.gvl [GLOBAL_VAR_LIST]
- PRG_System.st [PROGRAM]

### ST_Boiler_Status.dut [DUT_OR_ENUM]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]
- GVL_STATUS.gvl [GLOBAL_VAR_LIST]

### ST_Component_Maintenance.dut [DUT_OR_ENUM]
- ST_Zone_Sensors.dut [DUT_OR_ENUM]

### ST_DHW_Config.dut [DUT_OR_ENUM]
- FB_DHW_Manager.st [FUNCTION_BLOCK]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]

### ST_DHW_Status.dut [DUT_OR_ENUM]
- FB_DHW_Manager.st [FUNCTION_BLOCK]
- GVL_STATUS.gvl [GLOBAL_VAR_LIST]

### ST_Debug_Log_Record.dut [DUT_OR_ENUM]
- (none)

### ST_Debug_Logger_Config.dut [DUT_OR_ENUM]
- (none)

### ST_Device_Health.dut [DUT_OR_ENUM]
- FB_Device_Predictive_Diag.st [FUNCTION_BLOCK]
- ST_Manifold_Status.dut [DUT_OR_ENUM]

### ST_EVENT.dut [DUT_OR_ENUM]
- GVL_EVENT.gvl [GLOBAL_VAR_LIST]

### ST_Flood_Config.dut [DUT_OR_ENUM]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]

### ST_Flood_Global_Config.dut [DUT_OR_ENUM]
- FB_Water_Leakage_Manager.st [FUNCTION_BLOCK]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]

### ST_FloorHeating_Circuit_Config.dut [DUT_OR_ENUM]
- FB_FloorHeating_Controller.st [FUNCTION_BLOCK]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]
- ST_FloorHeating_Manifold_Config.dut [DUT_OR_ENUM]

### ST_FloorHeating_Global_Config.dut [DUT_OR_ENUM]
- (none)

### ST_FloorHeating_Manifold_Config.dut [DUT_OR_ENUM]
- (none)

### ST_Gas_Valve_Configuration.dut [DUT_OR_ENUM]
- FB_Gas_Valve_Controller.st [FUNCTION_BLOCK]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]

### ST_Gateway_Command.dut [DUT_OR_ENUM]
- FB_Gateway_Interface.st [FUNCTION_BLOCK]
- GVL_GATEWAY.gvl [GLOBAL_VAR_LIST]

### ST_Heating_Config.dut [DUT_OR_ENUM]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]

### ST_History_Record.dut [DUT_OR_ENUM]
- FB_History_Manager.st [FUNCTION_BLOCK]
- GVL_Retain.gvl [GLOBAL_VAR_LIST]
- PRG_System.st [PROGRAM]

### ST_Lifetime_Status.dut [DUT_OR_ENUM]
- (none)

### ST_Maintenance_Access_Config.dut [DUT_OR_ENUM]
- (none)

### ST_Manifold_Status.dut [DUT_OR_ENUM]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]
- GVL_STATUS.gvl [GLOBAL_VAR_LIST]

### ST_Operator_Zone_Rights.dut [DUT_OR_ENUM]
- FB_Zone_Access_Manager.st [FUNCTION_BLOCK]

### ST_Outdoor_Zone_Config.dut [DUT_OR_ENUM]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]

### ST_Owen_Analog_Value.dut [DUT_OR_ENUM]
- GVL_IO.gvl [GLOBAL_VAR_LIST]

### ST_Persist.dut [DUT_OR_ENUM]
- PRG_System.st [PROGRAM]

### ST_Rule.dut [DUT_OR_ENUM]
- (none)

### ST_Rule_Action.dut [DUT_OR_ENUM]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]
- FB_Lighting_Blinds_Manager.st [FUNCTION_BLOCK]
- FB_Rule_Engine.st [FUNCTION_BLOCK]
- FB_Socket_Manager.st [FUNCTION_BLOCK]
- FB_Ventilation_System_Manager.st [FUNCTION_BLOCK]
- GVL_STATE.gvl [GLOBAL_VAR_LIST]

### ST_Scenario_Config.dut [DUT_OR_ENUM]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]
- FB_Lighting_Blinds_Manager.st [FUNCTION_BLOCK]
- FB_Simulation_Manager.st [FUNCTION_BLOCK]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]

### ST_Scenario_Transition_Config.dut [DUT_OR_ENUM]
- (none)

### ST_Security_Global_Config.dut [DUT_OR_ENUM]
- FB_Access_Control.st [FUNCTION_BLOCK]
- FB_Security_System_Manager.st [FUNCTION_BLOCK]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]

### ST_Security_Zone_State.dut [DUT_OR_ENUM]
- (none)

### ST_Sensor_Calibration_Record.dut [DUT_OR_ENUM]
- FB_Calibration_Manager.st [FUNCTION_BLOCK]
- FB_Sensor_Calibration_Processor.st [FUNCTION_BLOCK]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]

### ST_State_Snapshot.dut [DUT_OR_ENUM]
- FB_State_Snapshot_Manager.st [FUNCTION_BLOCK]
- FB_State_Snapshot_NVRAM.st [FUNCTION_BLOCK]

### ST_System_Diagnostics.dut [DUT_OR_ENUM]
- GVL_STATUS.gvl [GLOBAL_VAR_LIST]

### ST_System_State_Snapshot.dut [DUT_OR_ENUM]
- FB_Redundancy_Manager.st [FUNCTION_BLOCK]
- FB_State_Replication.st [FUNCTION_BLOCK]
- PRG_System.st [PROGRAM]

### ST_System_State_Summary.dut [DUT_OR_ENUM]
- (none)

### ST_Tariff_Config.dut [DUT_OR_ENUM]
- FB_FloorHeating_Controller.st [FUNCTION_BLOCK]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]

### ST_Trend_Config.dut [DUT_OR_ENUM]
- FB_Trend_Logger.st [FUNCTION_BLOCK]
- ST_Trend_Data.dut [DUT_OR_ENUM]

### ST_Trend_Data.dut [DUT_OR_ENUM]
- FB_Trend_Logger.st [FUNCTION_BLOCK]

### ST_Trend_Header.dut [DUT_OR_ENUM]
- (none)

### ST_Trend_History_Record.dut [DUT_OR_ENUM]
- (none)

### ST_TwoFactor_Auth_State.dut [DUT_OR_ENUM]
- FB_TwoFactor_Auth.st [FUNCTION_BLOCK]

### ST_TwoFactor_Data.dut [DUT_OR_ENUM]
- (none)

### ST_User_Rule.dut [DUT_OR_ENUM]
- FB_Rule_Engine.st [FUNCTION_BLOCK]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]

### ST_Valve_Test_Config.dut [DUT_OR_ENUM]
- FB_Heating_System_Manager.st [FUNCTION_BLOCK]
- FB_Valve_Test_Manager.st [FUNCTION_BLOCK]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]

### ST_Ventilation_Config.dut [DUT_OR_ENUM]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]

### ST_Ventilation_Global_Config.dut [DUT_OR_ENUM]
- FB_Ventilation_System_Manager.st [FUNCTION_BLOCK]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]

### ST_Ventilation_Scenario_Mode.dut [DUT_OR_ENUM]
- ST_Ventilation_Global_Config.dut [DUT_OR_ENUM]

### ST_Ventilation_Unit.dut [DUT_OR_ENUM]
- (none)

### ST_Ventilation_Unit_Config.dut [DUT_OR_ENUM]
- FB_Exhaust_Ventilation_Controller.st [FUNCTION_BLOCK]
- FB_Supply_Ventilation_Controller.st [FUNCTION_BLOCK]
- GVL_CONFIG.gvl [GLOBAL_VAR_LIST]

### ST_Zone_Sensors.dut [DUT_OR_ENUM]
- (none)

