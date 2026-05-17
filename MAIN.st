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

// 2. Peer heartbeat ingestion
PRG_Peer_Heartbeat_Ingestion();

// 3. PLC role arbitration
PRG_PLC_Arbitration();

// 4. PLC ownership / fencing governance
PRG_PLC_Fencing_Governor();

// 5. IO read, passive quality observation and normalized inputs
PRG_IO_Read();
PRG_Input_Quality_Read();
PRG_Input_Processing();

// 6. Base mode, presence and safety
PRG_Mode_Manager();
PRG_Presence_Manager();
PRG_Safety();
PRG_Safety_Operator();
PRG_Safety_Shutdown();
PRG_Safety_Recovery();

// 7. Intent, adaptive behavior, scenario and policy
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

// 8. Command arbitration
PRG_Command_Arbitration();

// 9. Transport pipeline
PRG_Modbus_Master();
PRG_Modbus_RTU_Bridge();
PRG_Modbus_RTU_Driver();
PRG_Modbus_RTU_SysCom_Backend();
PRG_Modbus_RTU_SysCom_Transport();
PRG_Modbus_Register_Scan();
PRG_OpenTherm_Transport();
PRG_OpenTherm_Adapter_Status();

// 10. Transport freshness governance
PRG_Transport_Freshness_Governor();

// 11. Runtime authority barrier
PRG_Runtime_Barrier();

// 12. Immutable runtime snapshot governance
PRG_Runtime_Snapshot_Governor();

// 13. Canonical peer session publication
PRG_Peer_Session_Publication();

// 14. HA session replication boundary
PRG_HA_Session_Replication();

// 15. Distributed peer ingestion
PRG_Distributed_Peer_Ingestion();

// 16. Distributed epoch reconciliation governance
PRG_Distributed_Epoch_Governor();

// 17. Distributed snapshot publication
PRG_Distributed_Snapshot_Publication();

// 18. Distributed snapshot ingestion
PRG_Distributed_Snapshot_Ingestion();

// 19. Distributed immutable snapshot reconciliation governance
PRG_Distributed_Snapshot_Governor();

// 20. Distributed runtime fabric supervisor
// Must run before distributed commit governance because commit authority
// consumes centralized distributed execution gates.
PRG_Distributed_Runtime_Supervisor();

// 21. Distributed commit publication
PRG_Distributed_Commit_Publication();

// 22. Distributed commit ingestion
PRG_Distributed_Commit_Ingestion();

// 23. Distributed deterministic publication commit governance
PRG_Distributed_Commit_Governor();

// 24. Distributed deterministic commit observability projection
PRG_Distributed_Commit_Observability();

// 25. Semantic execution continuity governance
PRG_Semantic_Progress_Governor();

// 26. Systemic convergence governance
PRG_Convergence_Governor();

// 27. Recovery cleanup governance
// Must run before observability publication because observability
// must export final recovery/convergence authority state.
PRG_Recovery_Cleanup_Governor();

// 28. Observability authority governance
PRG_Observability_Governor();

// 29. Domain execution and projection
PRG_Heating();
PRG_Heating_Supervisory_Publication();
PRG_Ventilation();

// Water/Flood pipeline:
//   1. build semantic/supervisory/authority projections;
//   2. build deterministic output projection and reconciliation;
//   3. bridge final Water domain projection into GVL_WATER_OUTPUT.
PRG_Water_Supervisory_Publication();
PRG_Water_Output_Projection();
PRG_Water();

PRG_Access();
PRG_Lighting();

// 30. Output freshness governance
// Must run before immutable physical snapshot governance because
// physical snapshot epoch coherence consumes Output_Publication_Epoch.
PRG_Output_Freshness_Governor();

// 31. Immutable physical snapshot governance
// Must run before sensor consensus and telemetry causality governance
// to prevent in-cycle physical telemetry mutation races.
PRG_Physical_Snapshot_Governor();

// 32. Physical sensor consensus governance
// Must run after immutable physical snapshot freeze/publication.
PRG_Sensor_Consensus_Governor();

// 33. Telemetry causality governance
// Must run before physical authority epoch governance because
// global physical authority coherence consumes telemetry epochs.
PRG_Telemetry_Causality_Governor();

// 34. Global physical authority epoch governance
// Must run before authority lineage governance because lineage
// continuity consumes finalized physical authority epochs.
PRG_Physical_Authority_Epoch_Governor();

// 35. Persistent authority lineage governance
// Must run before authority revocation governance because
// revocation consumes finalized lineage continuity state.
PRG_Authority_Lineage_Governor();

// 36. Global authority revocation governance
// Must run before authority restoration governance because
// restoration consumes finalized revocation state.
PRG_Authority_Revocation_Governor();

// 37. Deterministic authority restoration governance
// Must run before pre-output barrier to guarantee staged and
// causally ordered reopening of the authority fabric.
PRG_Authority_Restoration_Governor();

// 38. Pre-output safety barrier
PRG_PreOutput_Safety_Barrier();

// 39. Final physical IO projection
PRG_IO_Write();

// 40. Deterministic field actuation governance
// Must run after physical IO write and before physical
// transaction governance to guarantee field-confirmed execution.
PRG_Actuation_Authority_Governor();

// 41. Deterministic physical transaction governance
// Must run before temporal stability governance to guarantee
// atomic cross-actuator plant convergence.
PRG_Physical_Transaction_Governor();

// 42. Deterministic temporal stability governance
// Must run before environmental authority governance to guarantee
// stable post-convergence physical authority.
PRG_Temporal_Stability_Governor();

// 43. Environmental authority governance
// Must run before runtime resource governance to guarantee
// external environmental causality compatibility.
PRG_Environmental_Authority_Governor();

// 44. Runtime resource authority governance
// Must run before semantic continuity governance to guarantee
// deterministic runtime execution envelope stability.
PRG_Runtime_Resource_Authority_Governor();

// 45. Semantic continuity authority governance
// Must run before observability truth governance to guarantee
// deterministic alignment with declared system intent.
PRG_Semantic_Continuity_Authority_Governor();

// 46. Authoritative observability truth governance
// Must run before diagnostics/HMI publication to guarantee
// operator-visible truth matches active authority state.
PRG_Observability_Truth_Governor();

// 47. Observability authority coherence governance
// Must run after authoritative observability truth governance.
PRG_Observability_Authority_Governor();

// 48. Verification, diagnostics, history, HMI
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