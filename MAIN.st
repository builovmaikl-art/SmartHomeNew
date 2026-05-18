PROGRAM MAIN
VAR
    fbSystemRedundancyOrchestrator : FB_System_Redundancy_Orchestrator;
    fbSystemDiagnostics : FB_System_Diagnostics;
    fbStateReplication : FB_State_Replication;
    fbRedundancyManager : FB_Redundancy_Manager;
    fbPLCHeartbeat : FB_PLC_Heartbeat;

    L_Main_Local_State : ST_System_State_Snapshot;
    L_Main_Remote_State : ST_System_State_Snapshot;
    L_Main_Synced_State : ST_System_State_Snapshot;
    L_Main_State_Updated : BOOL;
    L_Main_PLC_Active : BOOL;
    L_Main_RTT_MS : UDINT;
    L_Main_Loss_Count : UDINT;
    L_Main_Max_RTT : UDINT;
END_VAR

PRG_Time_Service();
PRG_Time_Monotonic_Governor();
PRG_System_Init();
PRG_Config_Manager();
PRG_Config_Validation();
PRG_Config_Versioning();
PRG_System_Runtime_Base();

PRG_Temporal_Domain();
PRG_Runtime_Core_Domain();
PRG_Safety_Domain();
PRG_Recovery_Domain();
PRG_Distributed_Domain();
PRG_Verification_Domain();
PRG_Semantic_Commit_Governor();

fbPLCHeartbeat(
    VI_Local_ID := GVL_STATUS.G_PLC_ID,
    VI_System_Time := GVL_STATUS.G_System_Time_MS,
    VI_Remote_Pulse := GVL_IO.DI_Partner_Pulse,
    VI_Remote_Is_Active := GVL_IO.DI_Partner_Active,
    VI_Gateway_Ping_OK := GVL_GATEWAY.G_Gateway_Ping_OK,
    VO_Is_Active => L_Main_PLC_Active,
    VO_RTT_MS => L_Main_RTT_MS,
    VO_Loss_Count => L_Main_Loss_Count,
    VO_Max_RTT => L_Main_Max_RTT
);

fbStateReplication(
    VI_Local_Role := SEL(GVL_STATUS.G_Is_Active_PLC, E_PLC_ROLE.ROLE_STANDBY, E_PLC_ROLE.ROLE_ACTIVE),
    VI_Sync_Req := FALSE,
    VI_Local_State := L_Main_Local_State,
    VI_Remote_State := L_Main_Remote_State,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VO_State_Updated => L_Main_State_Updated,
    VO_Synced_State => L_Main_Synced_State
);

fbRedundancyManager(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Local_PLC_ID := GVL_STATUS.G_PLC_ID,
    VI_Remote_Pulse := GVL_IO.DI_Partner_Pulse,
    VI_Remote_Is_Active := GVL_IO.DI_Partner_Active,
    VI_Gateway_Ping_OK := GVL_GATEWAY.G_Gateway_Ping_OK,
    VI_Local_State := L_Main_Local_State,
    VI_Remote_State := L_Main_Remote_State
);

fbSystemDiagnostics();

fbSystemRedundancyOrchestrator(
    VIO_Local_State := L_Main_Local_State,
    VIO_Remote_State := L_Main_Remote_State
);

PRG_Peer_Heartbeat_Ingestion();
PRG_PLC_Arbitration();
PRG_PLC_Fencing_Governor();
PRG_IO_Read();
PRG_Input_Quality_Read();
PRG_Input_Processing();
PRG_Mode_Manager();
PRG_Presence_Manager();
PRG_Safety();
PRG_Safety_Operator();
PRG_Safety_Shutdown();
PRG_Safety_Recovery();
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
PRG_Command_Arbitration();
PRG_Modbus_Master();
PRG_Modbus_RTU_Bridge();
PRG_Modbus_RTU_Driver();
PRG_Modbus_RTU_SysCom_Backend();
PRG_Modbus_RTU_SysCom_Transport();
PRG_Modbus_Register_Scan();
PRG_OpenTherm_Transport();
PRG_OpenTherm_Adapter_Status();
PRG_Transport_Freshness_Governor();
PRG_Runtime_Barrier();
PRG_Runtime_Snapshot_Governor();
PRG_Peer_Session_Publication();
PRG_HA_Session_Replication();
PRG_Distributed_Peer_Ingestion();
PRG_Distributed_Epoch_Governor();
PRG_Distributed_Snapshot_Publication();
PRG_Distributed_Snapshot_Ingestion();
PRG_Distributed_Snapshot_Governor();
PRG_Distributed_Runtime_Supervisor();
PRG_Distributed_Commit_Publication();
PRG_Distributed_Commit_Ingestion();
PRG_Distributed_Commit_Governor();
PRG_Distributed_Commit_Observability();
PRG_Semantic_Progress_Governor();
PRG_Convergence_Governor();
PRG_Recovery_Cleanup_Governor();
PRG_Observability_Governor();
PRG_Heating();
PRG_Heating_Supervisory_Publication();
PRG_Ventilation();
PRG_Water_Supervisory_Publication();
PRG_Water_Output_Projection();
PRG_Water();
PRG_Access();
PRG_Lighting();
PRG_Output_Freshness_Governor();
PRG_Physical_Snapshot_Governor();
PRG_Sensor_Consensus_Governor();
PRG_Telemetry_Causality_Governor();
PRG_Physical_Authority_Epoch_Governor();
PRG_Authority_Lineage_Governor();
PRG_Authority_Revocation_Governor();
PRG_Authority_Restoration_Governor();
PRG_PreOutput_Safety_Barrier();
PRG_IO_Write();
PRG_Actuation_Authority_Governor();
PRG_Physical_Transaction_Governor();
PRG_Temporal_Stability_Governor();
PRG_Environmental_Authority_Governor();
PRG_Runtime_Resource_Authority_Governor();
PRG_Semantic_Continuity_Authority_Governor();
PRG_Observability_Truth_Governor();
PRG_Historical_Truth_Governor();
PRG_Global_Authority_Sync_Governor();
PRG_Control_Temporal_Coherence_Governor();
PRG_Actuator_Semantic_Verification_Governor();
PRG_Energy_Causality_Governor();
PRG_Runtime_Sustainability_Governor();
PRG_Semantic_Preservation_Governor();
PRG_Operator_Semantic_Alignment_Governor();
PRG_Semantic_Federation_Governor();
PRG_Compliance_Federation_Governor();
PRG_Forensic_Evidence_Governor();
PRG_Epistemic_Integrity_Governor();
PRG_Meta_Governance_Governor();
PRG_Authority_Provenance_Governor();
PRG_Provenance_Continuity_Governor();
PRG_Trust_Epoch_Monotonicity_Governor();
PRG_Semantic_Epoch_Invariance_Governor();
PRG_Governance_Observer_Consensus_Governor();
PRG_Execution_Projection_Integrity_Governor();
PRG_Governance_Feedback_Integrity_Governor();
PRG_Governance_Validator_Integrity_Governor();
PRG_Governance_Liveness_Integrity_Governor();
PRG_Governance_Publication_Binding_Governor();
PRG_Physical_SafeState_Lattice_Governor();
PRG_CrossDomain_FailSafe_Closure_Governor();
PRG_Deterministic_Recovery_Path_Governor();
PRG_Recovery_Ordering_Integrity_Governor();
PRG_Recovery_Reactivation_Control_Governor();
PRG_Authority_Resurrection_Boundary_Governor();
PRG_Energy_Isolation_Causality_Governor();
PRG_Residual_Energy_State_Governor();
PRG_Power_Domain_Segmentation_Governor();
PRG_Energy_Resurrection_Boundary_Governor();
PRG_Physical_Deadlock_Resolution_Governor();
PRG_Execution_Progress_Causality_Governor();
PRG_Resource_Starvation_Boundary_Governor();
PRG_Distributed_Forward_Progress_Governor();
PRG_Safety_Observability_Truth_Governor();
PRG_Physical_Safety_Projection_Governor();
PRG_Unsafe_Transition_Forensics_Governor();
PRG_Distributed_Safety_Reality_Consensus_Governor();
PRG_Temporal_Causality_Closure_Governor();
PRG_Distributed_Epoch_Linearity_Governor();
PRG_Historical_Ordering_Integrity_Governor();
PRG_Causality_Reversal_Prevention_Governor();
PRG_Passive_Runtime_Verification_Governor();
PRG_Semantic_Drift_Observability_Governor();
PRG_Proof_Continuity_Audit_Governor();
PRG_Runtime_Assumption_Integrity_Governor();
PRG_Runtime_Transition_Validator();
PRG_Operational_Intelligence_Governor();
PRG_Causal_Narrative_Engine();
PRG_Physical_Reality_Validation_Governor();
PRG_Survivability_Intelligence_Governor();
PRG_Runtime_Compression_Governor();
PRG_Runtime_Budget_Governor();
PRG_Controlled_Capability_Shedding_Governor();
PRG_Semantic_Execution_Control_Governor();
PRG_Industrial_Maintainability_Governor();
PRG_Observability_Authority_Governor();
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