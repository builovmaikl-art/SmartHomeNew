PROGRAM PRG_IO_Write_Phase_01_Context
// IO write phase 01: derive output publication guards and domain forced-off flags.

GVL_IO_WRITE_RUNTIME_BUFFER.B_PreOutput_Block_IO :=
    GVL_COMMAND_VERIFY.PreOutput_Block_IO;

GVL_IO_WRITE_RUNTIME_BUFFER.B_Output_Freshness_Block :=
    GVL_OUTPUT_EPOCH.Output_Forced_Safe_Decay;

GVL_IO_WRITE_RUNTIME_BUFFER.B_Output_Publication_Block :=
    (NOT GVL_OUTPUT_EPOCH.Output_Publication_Valid)
    OR (NOT GVL_OUTPUT_EPOCH.Output_Runtime_Epoch_Valid)
    OR GVL_OUTPUT_EPOCH.Output_Lease_Expired;

GVL_IO_WRITE_RUNTIME_BUFFER.B_Distributed_Publication_Block :=
    (NOT GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Valid)
    OR GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Quarantine_Active
    OR GVL_DISTRIBUTED_COMMIT.Commit_Lease_Expired
    OR (NOT GVL_DISTRIBUTED_SNAPSHOT.Distributed_Publication_Reconciled)
    OR (NOT GVL_DISTRIBUTED_SNAPSHOT.Distributed_Publication_Freeze_Valid)
    OR (NOT GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Consistent);

GVL_IO_WRITE_RUNTIME_BUFFER.B_Snapshot_Block :=
    (NOT GVL_RUNTIME_SNAPSHOT.Snapshot_Frozen)
    OR (NOT GVL_RUNTIME_SNAPSHOT.Snapshot_Publication_Allowed)
    OR (NOT GVL_RUNTIME_SNAPSHOT.Snapshot_Copy_Valid)
    OR (NOT GVL_RUNTIME_SNAPSHOT.Snapshot_Isolation_Valid)
    OR GVL_RUNTIME_SNAPSHOT.Snapshot_Mutation_Detected;

GVL_IO_WRITE_RUNTIME_BUFFER.B_Distributed_Execution_Block :=
    NOT GVL_Distributed_Execution_Gates.G_Can_Execute
    OR NOT GVL_Distributed_Execution_Gates.G_Can_Own_Projection;

GVL_IO_WRITE_RUNTIME_BUFFER.B_Global_Hard_Stop :=
    GVL_COMMAND_SHADOW.G_Heating_Emergency_Stop
    OR GVL_IO_WRITE_RUNTIME_BUFFER.B_PreOutput_Block_IO
    OR GVL_IO_WRITE_RUNTIME_BUFFER.B_Output_Freshness_Block
    OR GVL_IO_WRITE_RUNTIME_BUFFER.B_Output_Publication_Block
    OR GVL_IO_WRITE_RUNTIME_BUFFER.B_Distributed_Publication_Block
    OR GVL_IO_WRITE_RUNTIME_BUFFER.B_Snapshot_Block
    OR GVL_IO_WRITE_RUNTIME_BUFFER.B_Distributed_Execution_Block;

GVL_IO_WRITE_RUNTIME_BUFFER.B_Gas_Safety_Stop :=
    GVL_COMMAND_SHADOW.G_Heating_Gas_Safety_Stop
    OR GVL_COMMAND_SHADOW.G_Boiler_Stop;

GVL_IO_WRITE_RUNTIME_BUFFER.B_Freeze_Active :=
    GVL_STATE.G_Safety_Freeze_Risk;

GVL_IO_WRITE_RUNTIME_BUFFER.B_Gas_Fire_Siren_Enable :=
    GVL_ALARM.G_Gas_Fire_Siren
    OR GVL_ALARM.G_Global_Siren
    OR GVL_ALARM.G_Global_Critical;

GVL_IO_WRITE_RUNTIME_BUFFER.B_Gas_Siren_Authority :=
    GVL_HEALTH_BRIDGE.G_Gas_Detected
    OR GVL_HEALTH_BRIDGE.G_CO_Alarm_Level
    OR GVL_STATE.G_Safety_Gas_Latched;

GVL_IO_WRITE_RUNTIME_BUFFER.B_Fire_Siren_Authority :=
    GVL_HEALTH_BRIDGE.G_Smoke_Detected
    OR GVL_STATE.G_Safety_Smoke_Latched;

GVL_IO_WRITE_RUNTIME_BUFFER.B_Heating_Forced_Off :=
    GVL_COMMAND_SHADOW.G_Heating_Block;

GVL_IO_WRITE_RUNTIME_BUFFER.B_Vent_Forced_Off :=
    GVL_COMMAND_SHADOW.G_Vent_Stop
    OR GVL_COMMAND_SHADOW.G_Vent_Block;

GVL_IO_WRITE_RUNTIME_BUFFER.B_Water_Forced_Off :=
    GVL_COMMAND_SHADOW.G_Water_Block
    OR GVL_COMMAND_SHADOW.G_Water_Emergency_Stop;

GVL_IO_WRITE_RUNTIME_BUFFER.B_Access_Safety_Override :=
    (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = FIRE)
    OR (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = GAS);

GVL_IO_WRITE_RUNTIME_BUFFER.B_Access_Forced_Off :=
    GVL_SAFETY_RECOVERY.G_Recovery_Active
    AND NOT GVL_IO_WRITE_RUNTIME_BUFFER.B_Access_Safety_Override;

// >>> BULK_SYNC_ANCHOR: PRG_IO_Write_Phase_01_Context <<<
END_PROGRAM
