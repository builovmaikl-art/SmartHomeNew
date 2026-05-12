PROGRAM MAIN

// ======================================================
// MAIN CYCLIC EXECUTION PIPELINE
// ======================================================
// Required CODESYS Task Configuration:
//   - Assign only PROGRAM MAIN to the cyclic task.
//   - Do not assign child PRG_* programs directly to the same task.
//   - Configure the real cycle time in CODESYS Task Configuration.
//   - Recommended main control cycle: 100 ms.
//
// Execution principle:
//   1. Time / init / configuration
//   2. PLC role arbitration
//   3. PLC ownership / fencing governance
//   4. IO read and input normalization
//   5. Mode, presence and safety
//   6. Intent, behavior, scenario and policy
//   7. Command arbitration
//   8. Runtime authority barrier
//   9. Domain execution
//   10. Pre-output safety barrier
//   11. Output freshness governance
//   12. Physical IO write
//   13. Verification, diagnostics, history, HMI
// ======================================================

// 1. Time / init / configuration
PRG_Time_Service();
PRG_System_Init();
PRG_Config_Manager();
PRG_Config_Validation();
PRG_Config_Versioning();
PRG_System_Runtime_Base();

// 2. PLC role arbitration
PRG_PLC_Arbitration();

// 3. PLC ownership / fencing governance.
// Must execute immediately after arbitration and before runtime publication.
PRG_PLC_Fencing_Governor();

// 4. IO read and normalized inputs
PRG_IO_Read();
PRG_Input_Processing();

// 5. Base mode, presence and safety
PRG_Mode_Manager();
PRG_Presence_Manager();
PRG_Safety();
PRG_Safety_Operator();
PRG_Safety_Shutdown();
PRG_Safety_Recovery();

// 6. Intent, adaptive behavior, scenario and policy
PRG_System_Intent();
PRG_Security();
PRG_System_Access_Maintenance();
PRG_User_Adapt_Control();
PRG_Behavior_Adapt_Profile();
PRG_Scenario_Engine();
PRG_System_Scenario_Rules();
PRG_System_Evacuation();
PRG_Policy();
PRG_Heating_Policy_Manager();
PRG_Heating_Policy_Observer();
PRG_System_Coordinator();

// 7. Command arbitration
PRG_Command_Arbitration();

// 7.5 Modbus/OpenTherm transport pipeline.
// Modbus master schedules requests.
// RTU bridge exports request/imports confirmed response.
// RTU driver builds TX frame and consumes validated RX frame.
// SysCom backend performs physical serial IO.
// SysCom transport boundary transfers bytes between backend and RTU runtime.
// Register scanner is strictly read-only diagnostics.
// OpenTherm transport decodes wire image before validation.
PRG_Modbus_Master();
PRG_Modbus_RTU_Bridge();
PRG_Modbus_RTU_Driver();
PRG_Modbus_RTU_SysCom_Backend();
PRG_Modbus_RTU_SysCom_Transport();
PRG_Modbus_Register_Scan();
PRG_OpenTherm_Transport();
PRG_OpenTherm_Adapter_Status();

// 8. Authoritative runtime barrier.
// Must execute after arbitration/fencing and before domain output projection.
PRG_Runtime_Barrier();

// 9. Domain execution and domain output projection
PRG_Heating();
PRG_Ventilation();
PRG_Water();
PRG_Access();
PRG_Lighting();

// 10. Authoritative pre-output safety barrier.
// Must execute after all domain output projection and before output freshness governance.
PRG_PreOutput_Safety_Barrier();

// 11. Output freshness governance.
// Must execute before physical IO publication.
PRG_Output_Freshness_Governor();

// 12. Final physical IO projection.
// Must remain after runtime/output authority barriers.
PRG_IO_Write();

// 13. Verification, explainability, diagnostics, history, HMI
PRG_Command_Verifier();
PRG_Explainability();
PRG_System_Health();
PRG_System_Alarm_Gateway();
PRG_System_Diagnostics();
PRG_System_Diagnostics_Ext();
PRG_System_History();
PRG_System_BlackBox();
PRG_System_Trend();
PRG_System_Simulation();
PRG_HMI_Dashboard();
PRG_Debug_View();

// >>> BULK_SYNC_ANCHOR: MAIN <<<
END_PROGRAM
