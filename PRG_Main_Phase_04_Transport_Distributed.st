PROGRAM PRG_Main_Phase_04_Transport_Distributed
// MAIN PHASE 07/08 — fieldbus, transport, runtime barriers and distributed governance.
// Critical: mixed. Transport/barrier parts are runtime-critical; observability parts can be reviewed later for shedding.

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

// >>> BULK_SYNC_ANCHOR: PRG_Main_Phase_04_Transport_Distributed <<<
END_PROGRAM
