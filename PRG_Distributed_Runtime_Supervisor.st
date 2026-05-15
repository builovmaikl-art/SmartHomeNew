PROGRAM PRG_Distributed_Runtime_Supervisor
VAR
    fbClusterSafetyBarrier : FB_Cluster_Safety_Barrier_Runtime;

    fbRuntimeDiscovery : FB_Runtime_Node_Discovery;
    fbRuntimeSessions : FB_Runtime_Session_Governance;

    fbDistributedRuntimeContinuity : FB_Distributed_Runtime_Continuity;
    fbDistributedAuthority : FB_Distributed_Authority_Arbitration;

    fbRuntimeBusReplication : FB_Runtime_Bus_Replication;

    fbMQTTRuntimeAdapter : FB_MQTT_Runtime_Adapter;
    fbOPCUARuntimeAdapter : FB_OPCUA_Runtime_Adapter;
    fbADSRuntimeAdapter : FB_ADS_Runtime_Adapter;

    fbProjectionOwnership : FB_Distributed_Projection_Ownership_Runtime;
    fbDistributedOrchestration : FB_Distributed_Orchestration_Runtime;
    fbRecoveryLock : FB_Distributed_Recovery_Lock_Runtime;

    fbExecutionGates : FB_Distributed_Execution_Gates_Runtime;
    fbClusterRuntimeFSM : FB_Cluster_Runtime_FSM;
END_VAR

// Root distributed runtime execution chain.
//
// Execution order intentionally deterministic:
// safety -> discovery -> sessions -> authority -> replication
// -> transport -> ownership -> orchestration -> recovery locking
// -> unified execution gates -> cluster runtime FSM.

fbClusterSafetyBarrier(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbRuntimeDiscovery(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbRuntimeSessions(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbDistributedRuntimeContinuity(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbDistributedAuthority(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbRuntimeBusReplication(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbMQTTRuntimeAdapter(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbOPCUARuntimeAdapter(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbADSRuntimeAdapter(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbProjectionOwnership(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbDistributedOrchestration(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbRecoveryLock(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbExecutionGates(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbClusterRuntimeFSM(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

END_PROGRAM