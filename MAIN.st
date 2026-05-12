PROGRAM MAIN

// ======================================================
// MAIN CYCLIC EXECUTION PIPELINE
// ======================================================
// Required CODESYS Task Configuration:
//   - Assign only PROGRAM MAIN to the cyclic task.
//   - Do not assign child PRG_* programs directly to the same task.
//   - Configure the real cycle time in CODESYS Task Configuration.
//   - Recommended main control cycle: 100 ms.
// ======================================================

// 1. Time / init / configuration
PRG_Time_Service();
PRG_Time_Monotonic_Governor();
PRG_System_Init();
PRG_Config_Manager();
PRG_Config_Validation();
PRG_Config_Versioning();
PRG_System_Runtime_Base();

// 2. PLC role arbitration
PRG_PLC_Arbitration();

// 3. PLC ownership / fencing governance
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

// 8. Transport pipeline
PRG_Modbus_Master();
PRG_Modbus_RTU_Bridge();
PRG_Modbus_RTU_Driver();
PRG_Modbus_RTU_SysCom_Backend();
PRG_Modbus_RTU_SysCom_Transport();
PRG_Modbus_Register_Scan();
PRG_OpenTherm_Transport();
PRG_OpenTherm_Adapter_Status();

// 9. Transport freshness governance
PRG_Transport_Freshness_Governor();

// 10. Runtime authority barrier
PRG_Runtime_Barrier();

// 11. Immutable runtime snapshot governance
PRG_Runtime_Snapshot_Governor();

// 12. Distributed epoch reconciliation governance
PRG_Distributed_Epoch_Governor();

// 13. Distributed immutable snapshot reconciliation governance
PRG_Distributed_Snapshot_Governor();

// 14. Distributed deterministic publication commit governance
PRG_Distributed_Commit_Governor();

// 15. Distributed deterministic commit observability projection
PRG_Distributed_Commit_Observability();

// 16. Semantic execution continuity governance
PRG_Semantic_Progress_Governor();

// 17. Semantic execution continuity observability
PRG_Semantic_Progress_Observability();

// 18. Semantic publication commit coherence governance
PRG_Semantic_Commit_Governor();

// 19. Semantic publication commit observability
PRG_Semantic_Commit_Observability();

// 20. Observability authority governance
PRG_Observability_Governor();

// 21. Recovery cleanup governance
PRG_Recovery_Cleanup_Governor();

// 22. Domain execution and projection
PRG_Heating();
PRG_Ventilation();
PRG_Water();
PRG_Access();
PRG_Lighting();

// 23. Pre-output safety barrier
PRG_PreOutput_Safety_Barrier();

// 24. Output freshness governance
PRG_Output_Freshness_Governor();

// 25. Final physical IO projection
PRG_IO_Write();

// 26. Verification, diagnostics, history, HMI
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
